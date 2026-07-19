# ─── Networking: VPC, public/private subnets across 2 AZs, NAT ─────
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ─── Compute: Launch Template + Auto Scaling Group + ALB ────────────
module "asg" {
  source = "./modules/asg"

  project_name      = var.project_name
  environment       = var.environment
  instance_type     = var.instance_type
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  asg_subnet_ids    = module.networking.private_subnet_ids
  key_name          = var.key_name
  app_port          = var.app_port

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
}
