provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket to store Terraform state (with encryption)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket-pramod" # Replace with your bucket name


  tags = {
    Name = "Terraform State Bucket"
  }
}

# Optional: Create a DynamoDB table for state locking (to prevent concurrent operations)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}

