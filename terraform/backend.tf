terraform {
  # התוספת החדשה שכופה גרסה עדכנית:
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  # זה הבלוק שכבר יש לך (אל תשנה אותו, רק ודא שהוא שם):
  backend "s3" {
    bucket = "gilad-project1"         
    key    = "state/terraform.tfstate" 
    region = "us-east-1"              
  }
}