terraform {
    # backend "s3"{
    #     bucket = "sorceress-state"
    #     key = "terraform.tfstate"
    #     region = "eu-west-2"
    # }
}    

provider "aws"{
        region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
