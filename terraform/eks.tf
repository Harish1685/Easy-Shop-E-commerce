module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.33"

  # ─── ADDONS ────────────────────────────────────────────────────────────────
  addons = {
    coredns    = {}
    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }

    eks-pod-identity-agent = {
      before_compute = true
    }

    # Added EBS CSI driver addon
    # This is what actually provisions PVCs (EBS volumes) for your pods.
    # Without this, gp3/gp2 PVCs will stay Pending forever.
    aws-ebs-csi-driver = {}
  }

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  security_group_additional_rules = {
    jenkins_api_access = {
      description              = "Allow Jenkins EC2 to reach EKS API server"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.my_security_group.id
    }
  }

  # ─── NODE GROUPS ───────────────────────────────────────────────────────────
  eks_managed_node_groups = {
    easyshop-ng = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m7i-flex.large"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 3
      desired_size = 2

  
      # hop limit 2 = allows pods inside nodes to reach AWS metadata service
      metadata_options = {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 2       
        http_tokens                 = "required"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 35
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      # Giving the node IAM role permission to create/attach EBS volumes
      # Without this policy, the EBS CSI driver can't actually make volumes
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  tags = {
    Project     = "EasyShop"
    Environment = "dev"
    Terraform   = "true"
  }
}