resource "aws_s3_bucket" "sg1" {
  bucket = "terraform-jenkins-pipeline-bucket-eashu"

  tags = {
    Name = "terraform-state-bucket"
  }
}


resource "aws_s3_bucket_versioning" "sg1_versioning" {
  bucket = aws_s3_bucket.sg1.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks-baby"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-lock-table"
  }
}