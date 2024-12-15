# Documentação do Repositório Terraform para Infraestrutura Azure

## Descrição
Este repositório utiliza **Terraform** para provisionar recursos na plataforma Microsoft Azure, incluindo a criação de uma rede virtual (VNet), sub-redes, cluster Kubernetes (AKS), além do gerenciamento de namespaces e configurações.

O repositório também inclui um pipeline automatizado de **GitHub Actions (CI/CD)** para validar e aplicar alterações na infraestrutura conforme definido no **Terraform**.

---

## Componentes

### Arquivos Principais

- **`main.yml`**: Configuração do pipeline CI/CD com GitHub Actions para validação e aplicação das mudanças de infraestrutura.
- **`main.tf`**: Configuração principal do Terraform que define a infraestrutura na Azure.

---

## Estrutura do Repositório

### Pipeline CI/CD (`main.yml`)
O arquivo `main.yml` contém um pipeline de CI/CD automatizado que realiza validações e aplicabilidade das alterações feitas.

#### **Fluxo do Pipeline**
1. **Eventos Disparadores**:
    - É disparado nos seguintes eventos:
        - Pull Requests fechados.
        - Alterações na branch `main`.
    - Também pode ser executado manualmente com `workflow_dispatch`.

2. **Permissões Necessárias**:
    - `id-token`: Usado para login no Azure.
    - `contents`: Para verificar o repositório.

3. **Etapas do Job `terraform`**:
    - **Checkout do Código**: Obtém o código da branch.
    - **Setup Terraform**: Prepara o ambiente com a versão adequada do Terraform.
    - **Login no Azure**: Utiliza credenciais configuradas como Secrets no repositório.
    - **Terraform Init**: Inicializa o diretório e os providers.
    - **Terraform Validate**: Valida sintaticamente o código.
    - **Terraform Plan**: Gera um plano de execução.
    - **Terraform Apply**: Aplica as mudanças (somente quando aplicável à branch `main`).

#### **Secrets Necessários**:
Para autenticar e realizar deploy no Azure, os seguintes **secrets** são necessários no repositório:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_POSTGRESQL_CONNECTION_STRING`

---

### Infraestrutura Terraform (`main.tf`)
O arquivo `main.tf` utiliza o Terraform para provisionar e configurar os seguintes recursos na Azure:

#### **Provedores**
1. **AzureRM**:
    - Utilizado para gerenciar recursos na Azure com o Subscription ID.
2. **Kubernetes**:
    - Configurado para administração e provisionamento de recursos no cluster AKS.

#### **Variáveis Configuráveis**
- **`subscription_id`**: ID da assinatura Azure (obrigatório).
- **`sql_connection_string`**: String de conexão com banco de dados PostgreSQL (configurada como sensível).
- **Defaults**:
    - **`resource_group_name`**: Nome do Resource Group. Default: `"rg-postech-fiap-k8s"`.
    - **`location`**: Localização dos recursos. Default: `"eastus"`.
    - **`vnet_name`**: Nome da Virtual Network. Default: `"postech-fiap-k8s-vnet"`.
    - **`subnet_name`**: Nome da Sub-rede. Default: `"postech-fiap-k8s-subnet"`.
    - **`cluster_name`**: Nome do cluster AKS. Default: `"postech-fiap-k8s-cluster"`.

#### **Recursos Criados**
1. **Rede Virtual**
    - Nome: `postech-fiap-k8s-vnet`.
    - Localização: `"eastus"`.
    - Endereço: `10.0.0.0/16`.

2. **Sub-rede**
    - Nome: `postech-fiap-k8s-subnet`.
    - Endereço: `10.0.1.0/24`.

3. **Cluster Kubernetes (AKS)**
    - Nome: `postech-fiap-k8s-cluster`.
    - DNS: `devk8scluster`.
    - Node Pool:
        - Tamanho: `Standard_B2s` (econômico para desenvolvimento).
        - Contagem de Nós: `1`.

4. **Recursos Kubernetes**
    - Namespace:
        - Nome: `myfood-namespace`.
    - ConfigMap:
        - Nome: `myfood-config`.
        - Dados:
            - **`ConnectionStrings__SQLConnection`**: Configurado com `sql_connection_string`.

#### **Saídas (Outputs)**
- **`kube_config`**: Credenciais geradas para acesso ao cluster Kubernetes.

---

## Como Usar

### Pré-Requisitos
Certifique-se de que possui os seguintes requisitos configurados:
1. **Ferramentas**:
    - **Terraform**: Version `>= 1.3.0`.
    - **Azure CLI**: Autenticado previamente.
2. **Configuração do GitHub Actions**:
    - Secrets configurados:
        - `AZURE_CLIENT_ID`
        - `AZURE_TENANT_ID`
        - `AZURE_SUBSCRIPTION_ID`
        - `AZURE_POSTGRESQL_CONNECTION_STRING`

---

## Estrutura do Cluster Kubernetes

#### Configuração
1. **Rede Virtual**:
    - Configurado com a sub-rede definida no Terraform.
2. **Namespaces e Configurações**:
    - Namespace `myfood-namespace`.
    - ConfigMap associado com informações de conexão.

---

## Pipeline Automatizado

### Funcionalidade
- **Validação Automática**:
    - Gatilhos em eventos pull request e pushes.
    - Geração de plano para verificação.
- **Aplicação Automatizada**:
    - Aplicação ocorre apenas na branch `main` após validação.

---