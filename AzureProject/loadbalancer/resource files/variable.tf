variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "name" {
  type = string
}
/*
variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}
*/

variable "lb_port" {
  type    = number
  default = 80
}

variable "probe_port" {
  type    = number
  default = 80
}