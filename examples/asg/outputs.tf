output "ami_arn" {
    value       = data.aws_ami.ubuntu.arn
}

output "ami_description" {
    value       = data.aws_ami.ubuntu.description
}
