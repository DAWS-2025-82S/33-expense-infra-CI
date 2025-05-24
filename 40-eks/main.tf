resource "aws_key_pair" "eks" {
  key_name   = "expense-eks"
  #public_key = file("~/.ssh/eks.pub")
  #public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrOzE8MvLn569u+/+ea7Q0xLucFKjNvtayvmtkt0Io2 rajas@ManDev"
  public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCy2cLS3fsPE0oewaaEpgtr5DtyDe130JKG3Wk/vMIxH0OixIcUBj7eC4cBp3W/9CglEDuIvqHez18ajqOSDKmJB4J9LkUH+uYv3ndhmDfGuDtnsxRlVD+B6M2u6lJMoVAH0XB1/tr4K2W5PuWgoJx+PqvnhWyKWqrB4b6m5+KJX+gOloN34Zt7xOoH9tPIZSbdXBVdPoVZJcFOurkstV4Lt7lHuB7+Ammf/y3subNYKB1aPLfp0248nflxRklAA1uENWF7j6jQea5PHafvw406rfFyPMxOX7a53l0FclaXxd2aM2S9WgPMl32+5OFjQhOW4S402EWCFo9yXCFz6XtbKIBeejNgKX1VtsQtWhjCrz3ilHVcahMQm2E6nyasACcopqd4LE7bYbnowgG6qhC5BK89zfcpWPMFcjRfuo9RSrHDNp4FCiKWWaHdcubys+NZmuaNMCjK3kCBdhkbRqZwWF4x0qwAyu3tdD4BiHvmBCBvXcSt7fJ8mVN0yNpMETk= rajas@ManDev"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = "1.31" # later we upgrade 1.32
  
  # After cluster upgrade change the version to 1.32
  #cluster_version = "1.32"

  create_node_security_group = false
  create_cluster_security_group = false
  cluster_security_group_id = local.eks_control_plane_sg_id
  node_security_group_id = local.eks_node_sg_id

  #bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    metrics-server = {}
  }

  # Optional
  cluster_endpoint_public_access = false

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2_x86_64"
      instance_types = ["m5.xlarge"]
      key_name = aws_key_pair.eks.key_name

      min_size     = 2
      max_size     = 10
      desired_size = 2
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        #AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    }

# Green Node Group Added for cluster upgrade to 1.32
/*     green = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2_x86_64"
      instance_types = ["m5.xlarge"]
      key_name = aws_key_pair.eks.key_name

      min_size     = 2
      max_size     = 10
      desired_size = 2
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        #AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
        AmazonEKSLoadBalancingPolicy = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    } */

  }

  tags = merge(
    var.common_tags,
    {
        Name = local.name
    }
  )
}