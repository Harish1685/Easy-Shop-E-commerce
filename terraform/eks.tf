module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # Cluster Configuration
  name               = local.name
  kubernetes_version = "1.33"

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # Networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Cluster Add-ons
  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  # Managed Node Group
  eks_managed_node_groups = {

    easyshop-ng = {

      instance_types = ["m7i-flex.large"]

      ami_type = "AL2023_x86_64_STANDARD"

      capacity_type = "SPOT"

      min_size     = 2
      desired_size = 2
      max_size     = 3

      disk_size = 35

      tags = {
        Name        = "easyshop-nodegroup"
        Environment = "dev"
      }
    }
  }

  tags = {
    Project     = "EasyShop"
    Environment = "dev"
    Terraform   = "true"
  }
}