variable "project" {
  description = "official name of project"
  type        = string
}
variable "company" {
  type = string
}
variable "department" {
  type = string
}
variable "env" {
  type = string
}

variable "image_confs" {
  type = list(map(any))
}

variable "vpc_id" {
  type = string
}
variable "subnets_public" {
  type = list(string)
}
variable "subnets_private" {
  type = list(string)
}
variable "igw_id" {
  type = string
}


variable "versioning" {
  type    = string
  default = "Enabled"
}


variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "AWS_ACCESS_KEY_ID" {}
variable "AWS_SECRET_ACCESS_KEY" {}