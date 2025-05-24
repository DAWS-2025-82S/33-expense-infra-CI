module "mysql_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "mysql"
    sg_description = "Created for MySQL instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}


module "bastion_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "bastion"
    sg_description = "Created for bastion instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "alb_ingress_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "app-alb"
    sg_description = "Created for application load(backend) balancer in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "eks_control_plane_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "eks_control_plane"
    sg_description = "Created for application load(backend) balancer in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "eks_node_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "eks-node"
    sg_description = "Created for application load(backend) balancer in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

# Allo traffic from worker node to master(control) node
resource "aws_security_group_rule" "eks_control_plane_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id       = module.eks_node_sg.sg_id
  security_group_id = module.eks_control_plane_sg.sg_id
}

# Allo traffic from  master(control) node to worker node
resource "aws_security_group_rule" "eks_node_eks_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id       = module.eks_control_plane_sg.sg_id
  security_group_id = module.eks_node_sg.sg_id
}

# Nodes accepting traffic ingress alb
# resource "aws_security_group_rule" "node_alb_ingress" {
#   type              = "ingress"
#   from_port         = 30000
#   to_port           = 32767
#   protocol          = "tcp"
#   source_security_group_id       = module.alb_ingress_sg.sg_id
#   security_group_id = module.eks_node_sg.sg_id
# }

# From Pod(node) to pod(node) access,DB to pod access
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" #this is huge mistake, if value is tcp, DNS will work in EKS. UDP traffic is required. So make it All traffic
  cidr_blocks = ["10.0.0.0/16"] # our private IP address range
  security_group_id = module.eks_node_sg.sg_id
}

# Node accepting traffic from Bastion
resource "aws_security_group_rule" "node_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id = module.eks_node_sg.sg_id
}

# Access to Load Balancer from Bastion(Bastion security group instances)
# APP ALB(Backend Load Balancer) accepting traffic from bastion security group instead of IP
# here we are not  configuring Bastion IP bcoz it may change
resource "aws_security_group_rule" "alb_ingress_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp" 
  # configuring bastion security group instead of Bastion IP(cidr)
  source_security_group_id  = module.bastion_sg.sg_id
  security_group_id = module.alb_ingress_sg.sg_id
}

resource "aws_security_group_rule" "alb_ingress_bastion_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp" 
  # configuring bastion security group instead of Bastion IP(cidr)
  source_security_group_id  = module.bastion_sg.sg_id
  security_group_id = module.alb_ingress_sg.sg_id
}

# Access to alb from public
resource "aws_security_group_rule" "alb_ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.alb_ingress_sg.sg_id
}


# To access Bastion instance using public IP from local Laptop using SSH
resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp" 
  #cidr_blocks = ["49.37.219.75/32"] # Provide your local system IP # This IP is not fixed and it will change
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.bastion_sg.sg_id
}

# Security Group for VPN Server
# ports 22, 443, 1194, 943 --> VPN ports
# 22 -- for ssh access
# 443 -- for access from browser
# 1194 & 943 -- VPN internal ports
module "vpn_sg" {
    source = "git::https://github.com/DAWS-2025-82S/12-terraform-aws-securitygroup.git?ref=main"
    project_name = var.project_name
    environment = var.environment
    sg_name = "vpn"
    sg_description = "Created for VPN instances in expense dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}


# Access to Database from Bastion(Bastion security group instances)
resource "aws_security_group_rule" "mysql_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id = module.mysql_sg.sg_id
}

# mysql accepting traffic from eks nodes
resource "aws_security_group_rule" "mysql_eks_node" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.eks_node_sg.sg_id
  security_group_id = module.mysql_sg.sg_id
}

# Traffic from bastion to control plane
resource "aws_security_group_rule" "eks_control_plane_bastion" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id = module.eks_control_plane_sg.sg_id
}

# Traffic from alb to nodes
resource "aws_security_group_rule" "eks_node_alb_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.alb_ingress_sg.sg_id
  security_group_id = module.eks_node_sg.sg_id
}




