output "iam_user_arn" {
  value       = aws_iam_user.example.arn
  description = "The ARN of the created IAM user"
}

output "iam_user_name" {
  value       = aws_iam_user.example.name
  description = "The IAM username"
}

output "user_attributes" {
  value       = aws_iam_user.example
  description = "The ARN of the created IAM user"
}
