
variable "lambda_extraction" {
  type = string
  default = "lambda-extraction"
}

variable "lambda_transformation" {
  type = string
  default = "lambda-transformation"
}

variable "lambda_loading" {
  type = string
  default = "lambda-loading"
}

variable "region"{
    type = string
    default = "eu-west-2"
}

variable "extraction_bucket" {
  type        = string
  default     = "extraction-bucket-sorceress"
}

variable "transformation_bucket" {
  type        = string
  default     = "transformation-bucket-sorceress"
}

variable "loading_bucket" {
  type        = string
  default     = "warehouse-bucket-sorceress"
}
