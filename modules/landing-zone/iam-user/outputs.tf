output "user_arn" {
  value       = aws_iam_user.example.arn
  description = "The ARN of the created IAM user"
}


output "user_all" {
  value       = aws_iam_user.example
  description = "The ARN of the created IAM user"
}
