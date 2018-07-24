provider "aws" {
  region = "${var.region}"
}

/*
Store infrastructure state in a remote store (instead of local machine):
https://www.terraform.io/docs/state/purpose.html
*/
terraform {
  backend "s3" {
    bucket  = "terraform-state-002"
    key     = "tvs/terraform.tfstate" # When using workspaces this changes to ':env/{terraform.workspace}/tvs/terraform.tfstate'
    region  = "eu-west-2"
    encrypt = "true"
  }
}

module "core" {
  source = "./terraform/modules/core"

  environment          = "${terraform.workspace}"
  project_name         = "${var.project_name}"
  vpc_cidr             = "${var.vpc_cidr}"
  availability_zones   = "${var.availability_zones}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  availability_zones   = "${var.availability_zones}"
  ssh_ips              = "${var.ssh_ips}"

  region                   = "${var.region}"
  load_balancer_check_path = "${var.load_balancer_check_path}"
  alb_certificate_arn      = "${var.alb_certificate_arn}"
  image_id                 = "${var.image_id}"
  instance_type            = "${var.ecs_instance_type}"
  ecs_key_pair_name        = "${var.ecs_key_pair_name}"

  asg_name         = "${var.asg_name}"
  asg_max_size     = "${var.asg_max_size}"
  asg_min_size     = "${var.asg_min_size}"
  asg_desired_size = "${var.asg_desired_size}"

  ecs_cluster_name                  = "${module.ecs.cluster_name}"
  ecs_service_name                  = "${module.ecs.service_name}"
  aws_iam_ecs_instance_profile_name = "${module.ecs.aws_iam_ecs_instance_profile_name}"
}

module "ecs" {
  source = "./terraform/modules/ecs"

  environment                                     = "${terraform.workspace}"
  project_name                                    = "${var.project_name}"
  region                                          = "${var.region}"
  ecs_cluster_name                                = "${var.ecs_cluster_name}"
  ecs_service_name                                = "${var.project_name}_${terraform.workspace}_${var.ecs_service_name}"
  ecs_service_task_name                           = "${var.project_name}_${terraform.workspace}_${var.ecs_service_task_name}"
  ecs_service_task_count                          = "${var.ecs_service_task_count}"
  ecs_service_task_port                           = "${var.ecs_service_task_port}"
  ecs_service_web_container_definition_file_path  = "${var.ecs_service_web_container_definition_file_path}"
  ecs_service_rake_container_definition_file_path = "${var.ecs_service_rake_container_definition_file_path}"

  ecs_service_logspout_container_definition_file_path = "${var.ecs_service_logspout_container_definition_file_path}"
  logspout_command                                    = "${var.logspout_command}"
  ecs_logspout_task_count                             = "${var.asg_min_size}"

  import_schools_task_command = "${var.import_schools_task_command}"

  vacancies_scrape_task_command  = "${var.vacancies_scrape_task_command}"
  vacancies_scrape_task_schedule = "${var.vacancies_scrape_task_schedule}"

  sessions_trim_task_command  = "${var.sessions_trim_task_command}"
  sessions_trim_task_schedule = "${var.sessions_trim_task_schedule}"

  update_pay_scale_task_command                  = "${var.update_pay_scale_task_command}"

  update_vacancies_task_command                  = "${var.update_vacancies_task_command}"

  reindex_vacancies_task_command                 = "${var.reindex_vacancies_task_command}"

  aws_alb_target_group_arn      = "${module.core.alb_target_group_arn}"
  aws_cloudwatch_log_group_name = "${module.logs.aws_cloudwatch_log_group_name}"

  # Application variables
  rails_env                = "${var.rails_env}"
  override_school_urn      = "${var.override_school_urn}"
  http_pass                = "${var.http_pass}"
  http_user                = "${var.http_user}"
  aad_client_id            = "${var.aad_client_id}"
  aad_tenant               = "${var.aad_tenant}"
  dfe_sign_in_issuer       = "${var.dfe_sign_in_issuer}"
  dfe_sign_in_redirect_url = "${var.dfe_sign_in_redirect_url}"
  dfe_sign_in_identifier   = "${var.dfe_sign_in_identifier}"
  dfe_sign_in_secret       = "${var.dfe_sign_in_secret}"
  google_maps_api_key      = "${var.google_maps_api_key}"
  google_analytics         = "${var.google_analytics}"
  rollbar_access_token     = "${var.rollbar_access_token}"
  secret_key_base          = "${var.secret_key_base}"
  rds_username             = "${var.rds_username}"
  rds_password             = "${var.rds_password}"
  rds_address              = "${module.rds.rds_address}"
  es_address               = "${module.es.es_address}"
  aws_elasticsearch_region = "${var.region}"
  aws_elasticsearch_key    = "${module.es.es_user_access_key_id}"
  aws_elasticsearch_secret = "${module.es.es_user_access_key_secret}"
  redis_url                = "redis://${module.elasticache_redis.endpoint}"
  authorisation_service_token = "${var.authorisation_service_token}"
  authorisation_service_url   = "${var.authorisation_service_url}"
  google_drive_json_key = "${var.google_drive_json_key}"
  auth_spreadsheet_id = "${var.auth_spreadsheet_id}"
  domain                   = "${var.domain}"
}

module "logs" {
  source = "./terraform/modules/logs"

  environment  = "${terraform.workspace}"
  project_name = "${var.project_name}"
}

module "cloudwatch" {
  source = "./terraform/modules/cloudwatch"

  environment            = "${terraform.workspace}"
  project_name           = "${var.project_name}"
  slack_hook_url         = "${var.cloudwatch_slack_hook_url}"
  slack_channel          = "${var.cloudwatch_slack_channel}"
  ops_genie_api_key      = "${var.cloudwatch_ops_genie_api_key}"
  autoscaling_group_name = "${module.core.ecs_autoscaling_group_name}"
  pipeline_name          = "${module.pipeline.pipeline_name}"
}

module "pipeline" {
  source = "./terraform/modules/pipeline"

  environment         = "${terraform.workspace}"
  project_name        = "${var.project_name}"
  aws_account_id      = "${var.aws_account_id}"
  github_token        = "${var.github_token}"
  buildspec_location  = "${var.buildspec_location}"
  git_branch_to_track = "${var.git_branch_to_track}"

  registry_name    = "${module.ecs.registry_name}"
  ecs_cluster_name = "${module.ecs.cluster_name}"
  ecs_service_name = "${module.ecs.service_name}"
}

module "rds" {
  source = "./terraform/modules/rds"

  environment        = "${terraform.workspace}"
  project_name       = "${var.project_name}"
  rds_storage_gb     = "${var.rds_storage_gb}"
  rds_instance_type  = "${var.rds_instance_type}"
  rds_engine         = "${var.rds_engine}"
  rds_engine_version = "${var.rds_engine_version[var.rds_engine]}"
  rds_username       = "${var.rds_username}"
  rds_password       = "${var.rds_password}"

  vpc_id                    = "${module.core.vpc_id}"
  default_security_group_id = "${module.core.default_security_group_id}"
}

module "es" {
  source = "./terraform/modules/es"

  environment    = "${terraform.workspace}"
  project_name   = "${var.project_name}"
  instance_count = "${var.es_instance_count}"
  instance_type  = "${var.es_instance_type}"
  es_version     = "${var.es_version}"
  es_domain_name = "${var.project_name}-${terraform.workspace}-default"

  vpc_id                    = "${module.core.vpc_id}"
  default_security_group_id = "${module.core.default_security_group_id}"
}

module "cloudfront" {
  source = "./terraform/modules/cloudfront"

  environment                   = "${terraform.workspace}"
  project_name                  = "${var.project_name}"
  cloudfront_origin_domain_name = "${module.core.alb_dns_name}"
  cloudfront_aliases            = "${var.cloudfront_aliases}"
  cloudfront_certificate_arn    = "${var.cloudfront_certificate_arn}"
  offline_bucket_domain_name    = "${var.offline_bucket_domain_name}"
  offline_bucket_origin_path    = "${var.offline_bucket_origin_path}"
}

module "elasticache_redis" {
  source = "./terraform/modules/elasticache-redis"

  cluster_id           = "${var.project_name}-${terraform.workspace}"
  engine_version       = "${var.elasticache_redis_engine_version}"
  instance_type        = "${var.elasticache_redis_instance_type}"
  parameter_group_name = "${var.elasticache_redis_parameter_group_name}"
  maintenance_window   = "${var.elasticache_redis_maintenance_window}"
  vpc_id               = "${module.core.vpc_id}"
  private_subnet_ids   = "${join(",", module.core.private_subnet_ids)}"

  tag_name          = "${var.project_name}-${terraform.workspace}"
  tag_environment   = "${terraform.workspace}"
  tag_team          = "dfe"
  tag_contact-email = ""
  tag_customer      = ""
  tag_application   = "tvs"

  default_security_group_id = "${module.core.default_security_group_id}"
}
