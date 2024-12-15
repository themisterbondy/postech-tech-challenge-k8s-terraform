# Documentação do Projeto

## Descrição Geral
Este projeto utiliza **Terraform** para provisionar recursos na plataforma Microsoft Azure, incluindo a criação de uma rede virtual, sub-redes, um cluster Kubernetes (AKS) e o gerenciamento de namespaces e configurações. Paralelamente, um pipeline do GitHub Actions automatiza a implantação e o gerenciamento dos recursos definidos no Terraform.

---

## Estrutura do Projeto

### Arquivos Principais

1. **`main.yml`**: Arquivo de automação do GitHub Actions, utilizado para configurar um pipeline CI/CD para o Terraform.
2. **`main.tf`**: Arquivo principal do Terraform contendo a configuração dos recursos Azure e Kubernetes.

---

## Configuração do CI/CD com GitHub Actions (`main.yml`)

O pipeline de **GitHub Actions** realiza as seguintes etapas:

### Gatilhos
- **Pull Request**: É executado quando pull requests são fechados para main

`terraform apply`**: Aplica o plano gerado automaticamente. Este passo é executado **somente na branch `main`**.

---

## Configuração de Infraestrutura com Terraform (`main.tf`)

### Provedores
1. **AzureRM**:
    - Configurado para acessar o recurso por `subscription_id`.
2. **Kubernetes**:
    - Configurado para interagir com o cluster Kubernetes provisionado.

### Recursos Criados

#### Variáveis
**Definidas**:
- **`subscription_id`**: ID da Assinatura Azure.
- **`sql_connection_string`**: String de conexão com banco de dados PostgreSQL (sensível).

**Default**:
- **`resource_group_name`**: Nome do grupo de recursos (default: `rg-postech-fiap-k8s`).
- **`location`**: Local dos recursos no Azure (default: `eastus`).

#### Rede Virtual
1. **Rede Virtual (VNet)**:
    - Nome: `postech-fiap-k8s-vnet`.
    - Espaço de endereço: `10.0.0.0/16`.
    - Local: `eastus`.

2. **Sub-rede**:
    - Nome: `postech-fiap-k8s-subnet`.
    - Prefixo: `10.0.1.0/24`.

#### Cluster Kubernetes (AKS)
- Nome: `postech-fiap-k8s-cluster`.
- DNS: `devk8scluster`.
- Node Pool:
    - Tamanho dos nós: `Standard_B2s` (focado em economia para Dev).
    - Contagem de nós: `1`.

#### Recursos Kubernetes
1. **Namespace**:
    - Nome: `myfood-namespace`.

2. **ConfigMap**:
    - Nome: `myfood-config`.
    - Namespace: `myfood-namespace`.
    - Dados:
        - **`ConnectionStrings__SQLConnection`** com o valor de `sql_connection_string`.

---

## Saídas do Terraform

**`kube_config`**:
- Gera e retorna as credenciais necessárias para acessar o cluster Kubernetes.

---

## Requisitos

### Ferramentas Necessárias
- Terraform (v1.3.0 ou superior).
- Azure CLI configurado.
- GitHub Secrets configurados:
    - **`AZURE_CLIENT_ID`**
    - **`AZURE_TENANT_ID`**
    - **`AZURE_SUBSCRIPTION_ID`**
    - **`AZURE_POSTGRESQL_CONNECTION_STRING`**

---

