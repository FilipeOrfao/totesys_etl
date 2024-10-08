import datetime
import json
import os
import boto3
import logging
from botocore.exceptions import NoCredentialsError, ClientError
from .connection_extract import connect_to_extract_db_cloud as db_conn
from pg8000 import DatabaseError


ssm_client = boto3.client("ssm", region_name="eu-west-2")
s3_client = boto3.client("s3", region_name="eu-west-2")


def get_table_names(conn):
    data = conn.run(
        """SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_type = 'BASE TABLE';"""
    )
    unwanted_tables = ["_prisma_migrations"]
    return [i[0] for i in data if i[0] not in unwanted_tables]


def get_latest_date(conn, tables):
    newest = datetime.datetime(1990, 11, 3, 14, 20, 49, 962000)
    # print(tables)
    for table in tables:
        # print(table)
        newest_table_time = conn.run(
            f"select last_updated from {table} order by last_updated desc limit 1;"
        )[0][0]
        # print(newest_table_time)
        if newest_table_time > newest:
            newest = conn.run(
                f"select last_updated from {table} order by last_updated desc limit 1;"
            )[0][0]
    # print(newest_table_time)
    # print(newest)
    return newest


def get_latest_date_parameter(ssm_client=ssm_client):
    try:
        parameter_latest_date = ssm_client.get_parameter(Name="latest_date")
        late_date_parameter = parameter_latest_date["Parameter"]["Value"]

        datetime_str = datetime.datetime.strptime(
            late_date_parameter, "%Y-%m-%d %H:%M:%S.%f"
        )
    except ClientError as e:
        logging.error(f"{e}")
        if e.response["Error"]["Code"] == "ParameterNotFound":
            raise
    return datetime_str


# def table_to_json(conn, table, where_date):
#     res = conn.run(
#         f"select json_agg(row_to_json({table})) as payment_json from {table} where last_updated > ':{where_date}';",
#         where_date=where_date,
#     )[0][0]
#     return res


def table_to_json(conn, table, where_date):
    try:
        res = conn.run(
            f"select json_agg(row_to_json({table})) as payment_json from {table} where last_updated > ':{where_date}';",
            where_date=where_date,
        )[0][0]
        return res
    except DatabaseError as e:
        raise


def update_date_parameter(newest):
    # if parameter store empty
    ssm_client = boto3.client("ssm")
    res = ssm_client.put_parameter(
        Name="latest_date", Value=f"{newest}", Type="String", Overwrite=True
    )


def save_json_to_folder(table, latest_update, data, s3_client=s3_client):
    if not os.path.exists("/tmp/"):
        os.mkdir("/tmp/")
    if not os.path.exists("/tmp/data/"):
        os.mkdir("/tmp/data/")
    if not os.path.exists(f"/tmp/data/{table}"):
        os.mkdir(f"/tmp/data/{table}")
    if not os.path.exists(
        f"/tmp/data/{table}/{latest_update.year}-{latest_update.strftime('%B')}/"
    ):
        os.mkdir(
            f"/tmp/data/{table}/{latest_update.year}-{latest_update.strftime('%B')}/"
        )

    file_name = f"/tmp/data/{table}/{latest_update.year}-{latest_update.strftime('%B')}/{table}-{latest_update}.json"
    with open(file_name, "w") as f:
        f.write(json.dumps(data))

    try:
        s3_client.upload_file(
            file_name,
            "extraction-bucket-sorceress",
            f"{table}/{latest_update.year}-{latest_update.strftime('%B')}/{table}-{latest_update}.json",
        )
    except FileNotFoundError as e:
        logging.error(f"File {file_name} not found")
        raise e
    except NoCredentialsError as e:
        logging.error("Credentials not correct")
        raise e
    except ClientError as e:
        logging.error("Bucket does not exist or does not have access")
        raise e


def lambda_handler(event, context):
    table_names = get_table_names(db_conn())
    print(f"==>> table_names: {table_names}")

    latest_date_from_db = get_latest_date(db_conn(), table_names)
    # print(f"==>> latest_date_from_db: {latest_date_from_db}")

    parameter_date = get_latest_date_parameter()
    # print(f"==>> parameter_date: {parameter_date}")
    if latest_date_from_db > parameter_date:
        for table in table_names:
            json_table = table_to_json(db_conn(), table, parameter_date)

            if json_table:
                save_json_to_folder(table, latest_date_from_db, json_table)
                logging.info(f"Table {table} saved")
            else:
                logging.info(f"There is no new data in {table}")
    else:
        logging.info(f"No new data from {latest_date_from_db}")

    update_date_parameter(latest_date_from_db)

    # Whenever initially running this function, you need to uncomment these two lines, run it twice, obtain the data, and then commit those lines again.
    # newest = datetime.datetime(1990, 11, 3, 14, 20, 49, 962000)
    # update_date_parameter(newest)


# lambda_handler(1, 2)
