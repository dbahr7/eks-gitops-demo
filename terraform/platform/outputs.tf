# Values for connecting kubectl and for the Phase 6 manifests.

output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.votes.name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
