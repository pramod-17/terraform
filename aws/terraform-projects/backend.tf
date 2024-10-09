terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-pramod" # The S3 bucket you created
    key            = "pramod/terraform.tfstate"         # Path for the state file
    region         = "us-east-1"                        # AWS region
    encrypt        = true                               # Enable encryption
    dynamodb_table = "terraform-lock"                   # DynamoDB table for state locking
  }
}
