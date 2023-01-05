// Let’s now write an example Terraform module in examples/multi-account-root that can authenticate to multiple AWS accounts. Just as with the multiregion AWS example, you will need to add two provider blocks in main.tf, each with a different alias. First, the provider block for the parent AWS account:
provider "aws" {
  region = "us-east-2"
  alias  = "parent"
}

// Next, the provider block for the child AWS account but to be able to authenticate to the child AWS account, you’ll assume an IAM role. In the web console, you did this by clicking the Switch Role button; in your Terraform code, you do this by adding an assume_role block to the child provider block:
provider "aws" {
  region = "us-east-2"
  alias  = "child"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_iam_role}"
  }
}

// Now, to check this is actually working, add two aws_caller_identity data sources, and configure each one to use a different provider:
data "aws_caller_identity" "parent" {
  provider = aws.parent
}

data "aws_caller_identity" "child" {
  provider = aws.child
}

// Manual local test can be done by running:
// time terraform apply -var 'aws_account_id=<AWs Account ID>' -var 'aws_iam_role=<IAM Role>'