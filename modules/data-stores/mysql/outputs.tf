output "rds_mysql_address" {
  value       = aws_db_instance.example.address
  description = "Connect to the database at this endpoint"
}

output "rds_mysql_port" {
  value       = aws_db_instance.example.port
  description = "The port the database is listening on"
}

output "rds_mysql_engine" {
  value       = aws_db_instance.example.engine
  description = "Engine name"
}

output "rds_mysql_engine_version" {
  value       = aws_db_instance.example.engine_version
  description = "Engine version"
}