module "vpc" {
  source             = "./modules/vpc"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  az                 = var.az
}

module "security" {
  source           = "./modules/security"
  name             = var.name
  vpc_id           = module.vpc.vpc_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

module "ec2" {
  source            = "./modules/ec2"
  name              = var.name
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.security.security_group_id
  key_name          = var.key_name
  user_data_path    = "${path.module}/wordpress-nginx.sh"
}
