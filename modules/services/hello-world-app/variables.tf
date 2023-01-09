variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "db_remote_state_bucket_aws_region" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "desired_capacity" {
  description = "The desired capacity number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

// To allow users to specify custom tags, we add a new map input variable called custom_tags:
variable "custom_tags" { 
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type        = bool
}

variable "ami" {
  description = "The AMI to run in the cluster"
  type        = string
  default     = "ami-08d4ac5b634553e16"
}

variable "server_text" {
  description = "The text the web server should return"
  type        = string
  default     = "Hello, World"
}

variable "environment" {
  description = "The name of the environment we're deploying to"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC in which to deploy the resources"
  type        = string
}
