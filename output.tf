output "load_balancer_dns" {
  value = module.lb.lb_dns
}
output "ecr_url" {
  value = module.ecr.*.ecr_image_url
}
output "s3_bucket_name" {
  value = module.s3.bucket_name
}


# output "sg_lb" {
#   value = aws_security_group.lb.name
# }

# output "sg_ecs_service" {
#   value = aws_security_group.ecs_service.name
# }

# output "nat_gw" {
#   value = ["${aws_nat_gateway.main.*.id}"]
# }

# output "route_table_nat" {
#   value = ["${aws_route.private.*.id}"]
# }