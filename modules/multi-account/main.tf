terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = [aws.parent, aws.child] // Passed from the examples/multi-account-module module
    }
  }
}

// Now, to check this is actually working, add two aws_caller_identity data sources, and configure each one to use a different provider:
data "aws_caller_identity" "parent" {
  provider = aws.parent
}

data "aws_caller_identity" "child" {
  provider = aws.child
}
