# The EKS cluster and its nodes, via the community EKS module (terraform-aws-modules/eks/aws).

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.30"

  name               = var.project
  kubernetes_version = var.kubernetes_version

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  addons = {
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
    coredns                = {}
    kube-proxy             = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_count
    }
  }
}
