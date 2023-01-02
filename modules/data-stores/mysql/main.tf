provider "aws" {
  region = var.aws_region
}

// Amazon RDS can take roughly 10 minutes to provision even a small database, so be patient
resource "aws_db_instance" "example" { // aws_db_instance for AWS RDS
  identifier_prefix   = var.rds_identifier_prefix
  engine              = "mysql"
  allocated_storage   = var.allocated_storage
  instance_class      = var.instance_class
  skip_final_snapshot = true // The final snapshot is disabled, as this code is just for learning and testing (if you don’t disable the snapshot, or don’t provide a name for the snapshot via the final_snapshot_identifier parameter, destroy will fail).
  db_name             = var.db_name

  // Pass the credential through environmental variables:
  username = var.db_username // export TF_VAR_db_username="<YOUR_DB_USERNAME>"
  password = var.db_password // export TF_VAR_db_password="<YOUR_DB_PASSWORD>" 
}
