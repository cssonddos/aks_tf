variable "location" {
  default = "East US"
}
variable "subscription_id" {
  default = "xxxx"
}
variable "subscription_id_network" {
  default = "xxxx"
}
variable "client_id" {
  default = "xxxx"
}
variable "client_secret" {
  default = "xxxx"
}
variable "tenant_id" {
  default = "xxxx"
}
variable "vnet" {
  default = "vNetDefault"
}
variable "vnet_rg" {
  default = "rg-network"
}
variable "ip_address" {
  default = "172.26.0.0/28"
}
variable "prefix" {
  default = "rg-aks-xxxx"
}
variable "name" {
  default = "aks-xxxx"
}
variable "environment" {
  default = "prd"
}
variable "system_size" {
  default = 1
}
variable "application_size_min" {
  default = 1
}
variable "application_size_max" {
  default = 2
}
variable "tags" {
  type = map
  default = {
    "Environment" = "prd"
    "Project" = "xxxx"
  }
}