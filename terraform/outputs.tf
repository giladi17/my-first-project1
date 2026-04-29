# 1. שם קלאסטר ה-EKS
output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

# 2. הכתובת (endpoint) של הקלאסטר
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# 3. ה-URL של מאגר ה-ECR (אליו נדחוף את הדוקר בשלב הבא)
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

# 4. ה-ARN של תפקיד ה-IAM של הקלאסטר
output "iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

# 5. פלט רלוונטי נוסף: מזהה ה-VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}