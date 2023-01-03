output "user_arn" {
  value       = aws_iam_user.example.arn
  description = "The ARN of the created IAM user"
}

output "user_attributes" {
  value       = aws_iam_user.example
  description = "The ARN of the created IAM user"
}

output "neo_cloudwatch_policy_arn" {
  value = (
    var.give_neo_cloudwatch_full_access
    ? aws_iam_user_policy_attachment.neo_cloudwatch_full_access[0].policy_arn
    : aws_iam_user_policy_attachment.neo_cloudwatch_read_only[0].policy_arn
  )
}