terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.73.0"
    }
  }
}

provider "azurerm" {
  client_id           = var.client_id
  client_secret       = var.client_secret
  tenant_id           = var.tenant_id
  subscription_id     = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "network"
  subscription_id = var.subscription_id_network
  features {}
}

resource "azurerm_subnet" "k8s" {
  name                 = "${var.name}-${var.environment}"
  resource_group_name  = "${var.vnet_rg}"
  virtual_network_name ="${var.vnet}"
  address_prefixes     = [var.ip_address]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_resource_group" "k8s" {
  name     = "${var.prefix}-${var.environment}"
  location = var.location
  tags = var.tags
}

##Private DNS zone previously created
data "azurerm_private_dns_zone" "dns" {
  provider = azurerm.network
  name                = "privatelink.eastus.azmk8s.io"
  resource_group_name = var.vnet_rg
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.name}-${var.environment}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  dns_prefix_private_cluster = "${var.name}-${var.environment}"
  private_dns_zone_id        = data.azurerm_private_dns_zone.dns.id
  ## cluster private config
  private_cluster_enabled = true
  private_cluster_public_fqdn_enabled = true

  tags = var.tags

## node pool system + support
  default_node_pool {
    name       = "${var.environment}system"
    node_count = "${var.system_size}"
    vm_size    = "Standard_D4aS_v5"
    type       = "VirtualMachineScaleSets"
    availability_zones =  ["1", "2", "3"]
    vnet_subnet_id = azurerm_subnet.k8s.id
    max_pods = 250
    only_critical_addons_enabled = true
    tags = var.tags
    node_labels = {
      "type" = "support"
    }
  }

  service_principal {
      client_id     = var.client_id
      client_secret = var.client_secret
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
    load_balancer_sku = "standard"
    load_balancer_profile {
      outbound_ports_allocated  = 0
      managed_outbound_ip_count = 1
      idle_timeout_in_minutes   = 30
    }
  }

  addon_profile {
    aci_connector_linux { enabled = false }
    azure_policy { enabled = false }
    http_application_routing { enabled = false }
    kube_dashboard { enabled = false }
    oms_agent { enabled = false }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "${var.environment}app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  vm_size               = "Standard_F4s_v2"
  min_count             = var.application_size_min
  max_count             = var.application_size_max
  availability_zones    = ["1", "2", "3"]
  max_pods              = 250
  os_type               = "Linux"
  mode                  = "User"
  enable_auto_scaling   = true
  vnet_subnet_id        = azurerm_subnet.k8s.id
  node_labels           = {
    "type" = "app"
  }
  tags = var.tags
}
