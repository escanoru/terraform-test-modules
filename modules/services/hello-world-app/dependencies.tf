data "terraform_remote_state" "db" { // Read the state file from 05_file_isolation/stage/data-stores/mysql 
  backend = "s3"

  config = {
    bucket         = var.db_remote_state_bucket
    key            = var.db_remote_state_key
    region         = var.db_remote_state_bucket_aws_region
  }
}