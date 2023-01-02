variable "aws_region" {
  description = "Working AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_class" {
  description = "instance class, not all classe are availble on all regions"
  type        = string
}

variable "rds_identifier_prefix" {
  description = "identifier prefix for rds instance"
  type        = string
}

variable "db_name" {
  description = "The name for the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  description = "Allocated space"
  type        = string
}
