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
variable "mongodb_connection_string" {
  description = "MongoDB connection string"
  type        = string
  default     = ""
}

variable "sql_connection_string_orders" {
  description = "SQL connection string for orders database"
  type        = string
  default     = ""
}

variable "azure_storage_connection_string" {
  description = "Azure Storage connection string"
  type        = string
  default     = ""
}

variable "sql_connection_string_carts_payments" {
  description = "SQL connection string for carts and payments database"
  type        = string
  default     = ""
}

# Rede virtual
resource "azurerm_virtual_network" "k8s_vnet" {
  name                = "postech-fiap-k8s-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    prevent_destroy = true
  }
}

# Subnet para o cluster
resource "azurerm_subnet" "k8s_subnet" {
  name                 = "postech-fiap-k8s-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  lifecycle {
    prevent_destroy = true
  }
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

  lifecycle {
    prevent_destroy = true
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

resource "kubernetes_config_map" "myfood_db_products_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-db-products-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    MongoDb__ConnectionString = var.mongodb_connection_string
  }
}

resource "kubernetes_config_map" "myfood_db_carts_payments_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-db-carts-payments-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    ConnectionStrings__SQLConnection = var.sql_connection_string_carts_payments
  }
}

resource "kubernetes_config_map" "myfood_db_orders_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-db-orders-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    ConnectionStrings__SQLConnection = var.sql_connection_string_orders
  }
}

resource "kubernetes_config_map" "myfood_storage_account_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-storage-account-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    AzureStorageSettings__ConnectionString = var.azure_storage_connection_string
  }
}

resource "kubernetes_config_map" "myfood_products_config" {
  depends_on = [azurerm_kubernetes_cluster.k8s_cluster]

  metadata {
    name      = "myfood-products-config"
    namespace = kubernetes_namespace.myfood_namespace.metadata[0].name
  }

  data = {
    MyFoodProductsHttpClientSettings__BaseUrl = "http://myfood-products-webapi:80/api"
  }
}

# Adicionando o provedor Helm
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s_cluster.kube_config.0.cluster_ca_certificate)
  }
}

# Instalando o Helm Chart do Ingress NGINX
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "helm_repository.ingress_nginx.url"
  namespace  = "ingress-nginx"

  create_namespace = true
}

# Output para obter credenciais do cluster
output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s_cluster.kube_config_raw
  sensitive = true
}