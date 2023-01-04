# provider "aws" {
#   region = var.aws_region
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

// Amazon RDS can take roughly 10 minutes to provision even a small database, so be patient
resource "aws_db_instance" "example" { // aws_db_instance for AWS RDS
  identifier_prefix   = var.rds_identifier_prefix
  allocated_storage   = var.allocated_storage
  instance_class      = var.instance_class
  skip_final_snapshot = true // // If you don’t skip (disable) the snapshot, or don’t provide a name for the snapshot via the final_snapshot_identifier parameter, destroy will fail).
  tags                = var.db_tags

  # Enable backups
  backup_retention_period = var.backup_retention_period

  # If specified, this DB will be a replica
  replicate_source_db = var.replicate_source_db

  # Only set these params if replicate_source_db is not set
  engine   = var.replicate_source_db == null ? "mysql" : null
  db_name  = var.replicate_source_db == null ? var.db_name : null
  username = var.replicate_source_db == null ? var.db_username : null // export TF_VAR_db_username="<YOUR_DB_USERNAME>"
  password = var.replicate_source_db == null ? var.db_password : null // export TF_VAR_db_password="<YOUR_DB_PASSWORD>"

}
