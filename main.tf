terraform {
  #   backend "s3" {
  #     bucket = "s3-terraform-state-store"
  #     key = "project_archive/terraform.tfstate"
  #     dynamodb_table = "terraform_lock_store"
  #   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region     = var.region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

module "s3" {
  source     = "./modules/s3"
  company    = var.company
  department = var.department
  project    = var.project
  versioning = var.versioning
  tags       = local.tags
}

module "ecr" {
  source     = "./modules/ecr"
  company    = var.company
  department = var.department
  project    = var.project
  models     = var.image_confs.*.endpoint
  tags       = local.tags
}

module "ecs" {
  source          = "./modules/ecs"
  project         = var.project
  env             = var.env
  region          = var.region
  s3_model_bucket = module.s3.bucket_name
  image_names     = var.image_confs.*.endpoint
  image_urls      = var.image_confs.*.url
  container_ports = var.image_confs.*.port
  cpu             = var.image_confs.*.cpu
  memory          = var.image_confs.*.memory
  subnets_public  = var.subnets_public
  public_ip       = true
  tags            = local.tags
  # aws cron guide
  # https://docs.aws.amazon.com/autoscaling/application/APIReference/API_ScheduledAction.html
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
  shutdown = "cron(30 12 ? * MON-FRI *)" #8.30am sgt
  turnon   = "cron(00 10 ? * MON-FRI *)" #6pm sgt

  lb_tg_arns          = module.lb.lb_target_group_arns
  security_groups_ecs = [module.sg.security_group_ecs_service]
}

module "lb" {
  # alb w path-based routing
  source         = "./modules/lb"
  project        = var.project
  company        = var.company
  env            = var.env
  vpc_id         = var.vpc_id
  subnets_public = var.subnets_public
  # subnets_private = var.subnets_private
  path_route         = var.image_confs.*.endpoint
  tags               = local.tags
  security_groups_lb = [module.sg.security_group_lb]
}

module "sg" {
  source          = "./modules/sg"
  project         = var.project
  env             = var.env
  vpc_id          = var.vpc_id
  container_ports = var.image_confs.*.port
  tags            = local.tags
}

module "eventbridge" {
  source      = "./modules/eventbridge"
  project     = var.project
  env         = var.env
  image_urls  = var.image_confs.*.url
  image_names = var.image_confs.*.endpoint
  cluster_nm  = module.ecs.cluster_nm
  service_nm  = module.ecs.service_nm
  tags        = local.tags
}

# module "network" {
#   source          = "./modules/network"
#   vpc_id          = var.vpc_id
#   subnets_public  = var.subnets_public
#   subnets_private = var.subnets_private
#   igw_id          = var.igw_id
#   tags            = local.tags
# }
