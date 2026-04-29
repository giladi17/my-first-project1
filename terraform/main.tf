provider "aws" {
  region = var.aws_region # אפשר ומומלץ להעביר את זה לקובץ variables.tf
}

# יצירת ה-S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "gilad-project1"

  tags = {
    Name        = "Terraform State Bucket"
    Project     = "DevOps-Assignment"
  }
}

# Best Practice 1: שמירת גרסאות כדי שאם קובץ ה-State נהרס, נוכל לשחזר אותו
#resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
#  bucket = aws_s3_bucket.terraform_state.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}

# Best Practice 2: הצפנת הנתונים בבאקט (קובץ ה-state עשוי להכיל מידע רגיש)
#resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
#  bucket = aws_s3_bucket.terraform_state.id
#  rule {
#    apply_server_side_encryption_by_default {
#      sse_algorithm = "AES256"
#    }
#  }
#}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # שימוש במודול רשמי ומתוחזק

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  # הגדרת שני אזורי זמינות שונים, כפי שקלאסטר EKS מחייב
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  
  # הגדרת הרשתות כפי שנדרש במשימה
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # הגדרות ה-NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true # גישת חיסכון בעלויות
  map_public_ip_on_launch = true

  # חובה לאפשר DNS כדי שרכיבי הקלאסטר יוכלו לתקשר זה עם זה
  enable_dns_hostnames = true
  enable_dns_support   = true

  # תגיות חובה ל-EKS כדי שיידע איפה מותר לו לייצר רכיבים שחשופים לאינטרנט
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
# 1. יצירת מאגר התמונות (ECR)
# ---------------------------------------------------------
resource "aws_ecr_repository" "app_repo" {
  name                 = "gilad-flask-app" # שם המאגר שאליו נדחוף את אפליקציית ה-Flask
  image_tag_mutability = "MUTABLE"

  # Best Practice: סריקת אבטחה אוטומטית לכל תמונת דוקר שנדחפת למאגר
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ---------------------------------------------------------
# 2. יצירת קלאסטר ה-EKS (כולל IAM וקבוצות צמתים)
# ---------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # המודול הזה דואג אוטומטית לכל תפקידי ה-IAM וההרשאות הנדרשות עבור ה-EKS
  enable_cluster_creator_admin_permissions = true

  # חיבור ה-EKS לרשת ה-VPC שיצרנו בשלב הקודם
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets 
  cluster_endpoint_public_access = true # מאפשר לך לגשת לקלאסטר מהמחשב שלך

  # יצירת שתי קבוצות הצמתים (Node Groups) לפי דרישת המשימה
  eks_managed_node_groups = {
    
    # קבוצה ראשונה: ברשת הפרטית
    private_nodes = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = [var.node_instance_type] # Best Practice: שרת זול כדי לחסוך בעלויות
      subnet_ids     = module.vpc.private_subnets
    }

    # קבוצה שנייה: ברשת הציבורית
    public_nodes = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = [var.node_instance_type] # Best Practice: שרת זול כדי לחסוך בעלויות
      subnet_ids     = module.vpc.public_subnets
    }
  }
}