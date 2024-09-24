import pytest
import os
from src.lambda_extraction_folder.extract_lambda import (
    get_table_names,
    get_latest_date_parameter,
    table_to_json,
    update_date_parameter,
    save_json_to_folder,
    get_latest_date,
    lambda_handler,
)
from pg8000 import DatabaseError
from unittest.mock import Mock
from moto import mock_aws
from botocore.exceptions import NoCredentialsError, ClientError
import boto3
import datetime
import json
from unittest.mock import Mock, patch
import logging


@pytest.fixture(scope="function")
def aws_credentials():
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "eu-west-2"


@pytest.fixture(scope="function")
def ssm_client(aws_credentials):
    with mock_aws():
        yield boto3.client("ssm", region_name="eu-west-2")


@pytest.fixture(scope="function")
def s3_client(aws_credentials):
    with mock_aws():
        yield boto3.client("s3", region_name="eu-west-2")


class TestGetTableNames:
    def test_return_list_of_strings(self, ssm_client, s3_client):
        mock_conn = Mock()
        mock_conn.run.return_value = [["1", "2", "3", "_prisma_migrations"]]
        res = get_table_names(mock_conn)
        assert all(type(i) == str for i in res)

    def test_return_list_without_prisma_migrations(self, ssm_client, s3_client):
        mock_conn = Mock()
        mock_conn.run.return_value = [
            ["address"],
            ["staff"],
            ["currency"],
            ["payment"],
            ["department"],
            ["transaction"],
            ["design"],
            ["sales_order"],
            ["_prisma_migrations"],
            ["counterparty"],
            ["purchase_order"],
            ["payment_type"],
        ]
        res = get_table_names(mock_conn)
        print(res)
        assert res == [
            "address",
            "staff",
            "currency",
            "payment",
            "department",
            "transaction",
            "design",
            "sales_order",
            "counterparty",
            "purchase_order",
            "payment_type",
        ]


# class TestGetLatestDate:
#     def test_(self, ssm_client, s3_client):


class TestGetLatestDateParameter:
    def test_returns_parameter(self, ssm_client, s3_client):
        ssm_client.put_parameter(
            Name="latest_date",
            Value="2024-05-23 15:16:09.981000",
            Type="String",
            Overwrite=True,
        )
        res = get_latest_date_parameter(ssm_client=ssm_client)
        assert res == datetime.datetime(2024, 5, 23, 15, 16, 9, 981000)

    def test_wrong_parameter(self, ssm_client, s3_client):
        ssm_client.put_parameter(
            Name="latest_dat",
            Value="2024-05-23 15:16:09.981000",
            Type="String",
            Overwrite=True,
        )
        with pytest.raises(ClientError):
            res = get_latest_date_parameter(ssm_client=ssm_client)


class TestUpdateDateParameter:
    def test_update_date_parameter_from_store(self, ssm_client, s3_client):
        old_datetime = datetime.datetime(2020, 5, 23, 15, 00, 00, 199000)
        old_date_inserted = ssm_client.put_parameter(
            Name="latest_date",
            Value=str(old_datetime),
            Type="String",
            Overwrite=True,
        )

        get_old_parameters = ssm_client.get_parameter(Name="latest_date")

        new_datetime = datetime.datetime(2024, 5, 23, 19, 54, 58, 199000)
        update_date_parameter(new_datetime)

        get_new_parameters = ssm_client.get_parameter(Name="latest_date")

        updated_parameter_value = get_new_parameters["Parameter"]["Value"]
        assert old_datetime < datetime.datetime.fromisoformat(updated_parameter_value)


class TestTableToJson:
    def test_return_list_of_dicts(self):
        mock_conn = Mock()
        mock_conn.run.return_value = json.loads(
            """[[[
  {
    "transaction_id": 1,
    "transaction_type": "PURCHASE",
    "sales_order_id": null,
    "purchase_order_id": 2,
    "created_at": "2022-11-03T14:20:52.186",
    "last_updated": "2022-11-03T14:20:52.186"
  },
  {
    "transaction_id": 2,
    "transaction_type": "PURCHASE",
    "sales_order_id": null,
    "purchase_order_id": 3,
    "created_at": "2022-11-03T14:20:52.187",
    "last_updated": "2022-11-03T14:20:52.187"
  }]]]"""
        )

        expected = [
            {
                "transaction_id": 1,
                "transaction_type": "PURCHASE",
                "sales_order_id": None,
                "purchase_order_id": 2,
                "created_at": "2022-11-03T14:20:52.186",
                "last_updated": "2022-11-03T14:20:52.186",
            },
            {
                "transaction_id": 2,
                "transaction_type": "PURCHASE",
                "sales_order_id": None,
                "purchase_order_id": 3,
                "created_at": "2022-11-03T14:20:52.187",
                "last_updated": "2022-11-03T14:20:52.187",
            },
        ]

        res = table_to_json(mock_conn, "transaction", "2022-11-03T14:20:52.187")
        assert expected == res

    def test_table_to_json_throws_database_error(self):
        mock_conn = Mock()
        mock_conn.run.side_effect = DatabaseError()
        parameter_date = str(datetime.datetime(2020, 5, 23, 15, 00, 00, 199000))

        with pytest.raises(DatabaseError) as dbe:
            table_to_json(mock_conn, "transaction", parameter_date)


class TestSaveJsonToFolder:
    def test_file_not_found(self, s3_client):
        mock_s3_client = Mock()
        mock_s3_client.upload_file.side_effect = FileNotFoundError
        latest_update = datetime.datetime(2022, 11, 1)
        with pytest.raises(FileNotFoundError):

            save_json_to_folder("test", latest_update, "json", s3_client=mock_s3_client)

    def test_no_cretentials(self, s3_client):
        mock_s3_client = Mock()
        mock_s3_client.upload_file.side_effect = NoCredentialsError
        latest_update = datetime.datetime(2022, 11, 1)
        with pytest.raises(NoCredentialsError):

            save_json_to_folder("test", latest_update, "json", s3_client=mock_s3_client)

    def test_client_error(self, s3_client):
        mock_s3_client = Mock()
        mock_s3_client.upload_file.side_effect = ClientError(
            error_response={
                "Error": {
                    "Code": "ResourceNotFoundException",
                    "Message": "Bucket not found",
                }
            },
            operation_name="PutObjectBucket",
        )

        latest_update = datetime.datetime(2022, 11, 1)
        with pytest.raises(ClientError):

            save_json_to_folder("test", latest_update, "json", s3_client=mock_s3_client)


class TestGetLatestDate:
    def test_returns_datetime(self):
        mock_conn = Mock()
        mock_conn.run.return_value = [
            [datetime.datetime(1990, 11, 3, 14, 20, 49, 962000)]
        ]

        res = get_latest_date(mock_conn, "tables")
        assert isinstance(res, datetime.datetime)
