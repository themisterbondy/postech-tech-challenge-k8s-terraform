# Configuração do provedor
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.3.0"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Configure o provedor do Azure
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Definir variáveis
variable "resource_group_name" {
  default = "rg-postech-fiap-k8s"
}

variable "location" {
  default = "eastus"
}

# Variáveis
variable "sql_connection_string" {
  description = "Connection string for PostgreSQL"
  type        = string
  sensitive   = true
}

# Rede virtual
resource "azurerm_virtual_network" "k8s_vnet" {
  name                = "postech-fiap-k8s-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Subnet para o cluster
resource "azurerm_subnet" "k8s_subnet" {
  name                 = "postech-fiap-k8s-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Cluster Kubernetes AKS
resource "azurerm_kubernetes_cluster" "k8s_cluster" {
  name                = "postech-fiap-k8s-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "devk8scluster"

  # Configuração mínima de node pool
  default_node_pool {
    name       = "default"
    node_count = 1              # Número mínimo de nós para desenvolvimento
    vm_size    = "Standard_B2s" # Tamanho de VM econômico para dev
  }

  # Identidade gerenciada
  identity {
    type = "SystemAssigned"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.cluster_ca_certificate)
}

# Namespace
resource "kubernetes_namespace" "myfood_namespace" {
  metadata {
    name = "myfood-namespace"
  }
}

# ConfigMap
resource "kubernetes_config_map" "myfood_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    ConnectionStrings__SQLConnection = var.sql_connection_string
  }
}

# Output para obter credenciais do cluster
output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s_cluster.kube_config_raw
  sensitive = true
}


