# AKS - Azure Kubernetes Service with Azure CNI

## Introduction

Azure Kubernetes Service with Azure (CNI) Container Networking Interface.

### Resources used

- AKS (Azure Kubernetes Service)
- ACR (Azure Container Registry)
- Azure vNets & sNets
- Azure NSG (Network Security Groups)
- Azure Bastion
- Azure VM Scale Set
- Azure User & System Managed Identities
- Azure SQL Managed Instance
- Azure App Gateway
- Azure Front Door

## How To

All these CLI commands require us to login into azure `az login` and point to the right subscription `az account set --subscription SUB_ID`. We could use the CLI commands in order or individually as required. For instance:

- [Follow CLI instructions in order][103]
- [ONLY Create an Azure Container Registry (ACR)][105]
- [ONLY Create an Azure Kubernetes Service (AKS) with Azure Container Networking Interface (CNI)][111]
- [ONLY Enable AGIC on an AKS with Azure (CNI)][112]
- [ONLY SetUp Front Door to AGIC on an AKS with Azure (CNI)][114]
- [ONLY Configure Azure Front Door Custom Domains][101]
- [ONLY AKS to ACR Integration][107]
- [ONLY Create AzureDevOps agents][108]
- [ONLY Create a Bastion agent][109]
- [ONLY Create and Setup an Azure SQL Managed Identity][110]

## Useful Commands

| Command                                                              | Description                                     |
| -------------------------------------------------------------------- | ----------------------------------------------- |
| `az login`                                                           | login to azure with your account                |
| `az account list --output table`                                     | display available subscription                  |
| `az account set --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | use subscriptionID                              |
| `az account show --output table`                                     | check the subscriptions currently in use        |
| `az group list -o table`                                             | -                                               |
| `az account list-locations -o table`                                 | -                                               |
| `az aks get-versions --location eastus2 -o table`                    | -                                               |
| `export MSYS_NO_PATHCONV=1`                                          | avoids the C:/Program Files/Git/ being appended |

0. ### Connect to our azure subscription

   ```bash
   # Login to azure
   az login
   # Display available subscriptions
   az account list --output table
   # Switch to the subscription where we want to work on
   az account set --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   # Check whether we are on the right subscription
   az account show --output table
   # If using Git Bash avoid C:/Program Files/Git/ being appended to some resources IDs
   export MSYS_NO_PATHCONV=1
   ```

1. ### Setup reusable variables

   ```bash
   # ---
   # Main Vars
   # ---
   app="akscni";                                echo $app
   env="prod";                                  echo $env
   app_rg="rg-$app-$env";                       echo $app_rg
   l="eastus2";                                 echo $l
   tags="env=$env app=$app";                    echo $tags
   user_n_test="artiomlk";                      echo $user_n_test
   user_pass_test="Password123!";               echo $user_pass_test


   # ---
   # NETWORK TOPOLOGY
   # ---
   vnet_pre="172.16";                           echo $vnet_pre
   vnet_n="vnet-$app-$env";                     echo $vnet_n
   vnet_addr="$vnet_pre.0.0/16";                echo $vnet_addr

   # ---
   # ACR
   # ---
   acr_n="cr$app$env";                          echo $acr_n
   acr_sku="Premium";                           echo $acr_sku

   # ---
   # AKS with CNI
   # ---
   snet_n_aks_cni="snet-$app-aks-cni-$env";     echo $snet_n_aks_cni
   snet_addr_aks_cni="$vnet_pre.16.0/21";       echo $snet_addr_aks_cni
   aks_cluster_n_cni="aks-$app-cni-$env";       echo $aks_cluster_n_cni
   aks_cluster_count_cni="3";                   echo $aks_cluster_count_cni
   aks_node_max_pod_cni="110";                  echo $aks_node_max_pod_cni
   aks_cluster_count="3";                       echo $aks_cluster_count
   aks_v_cni="1.20.7";                          echo $aks_v_cni
   aks_node_size_cni="Standard_B2s";            echo $aks_node_size_cni
   aks_id_n_cni="id-$app-aks-cni-$env";         echo $aks_id_n_cni

   # ---
   # AGIC
   # ---
   agic_n="agic-$app-$env";                     echo $agic_n
   agic_sku="WAF_v2";                           echo $agic_sku
   agic_pip_n="pip-agic-$app-$env";             echo $agic_pip_n
   agic_pip_sku="Standard";                     echo $agic_pip_sku
   agic_snet_n="snet-agic-$app-$env";           echo $agic_snet_n
   agic_nsg_n="nsg-agic-$app-$env";             echo $agic_nsg_n
   agic_snet_addr="$vnet_pre.24.0/21";          echo $agic_snet_addr

   # ---
   # FD
   # ---
   fd_n="$app";                                 echo $fd_n
   fd_host_n="www.kmgpty.com";                  echo $fd_host_n

   # ---
   # Bastion
   # ---
   snet_n_bas="AzureBastionSubnet";             echo $snet_n_bas
   snet_addr_bas="$vnet_pre.1.0/27";            echo $snet_addr_bas
   nsg_n_bastion="nsg-$app-$env-bastion";       echo $nsg_n_bastion
   bastion_n="bastion-$app-$env";               echo $bastion_n
   bastion_pip="pip-bastion-$app-$env";         echo $bastion_pip

   # ---
   # DevOps Agents (scale set recommended though)
   # ---
   devops_vm_n="vm-$app-$env-devops";           echo $devops_vm_n
   devops_vm_img="UbuntuLTS";                   echo $devops_vm_img
   snet_n_devops="snet-$app-$env-devops";       echo $snet_n_devops
   snet_addr_devops="$vnet_pre.2.0/24";         echo $snet_addr_devops
   nsg_n_devops="nsg-$app-$env-devops";         echo $nsg_n_devops

   # ---
   # SQLMI
   # ---
   snet_n_sqlmi="snet-$app-$env-sqlmi";         echo $snet_n_sqlmi
   snet_addr_sqlmi="$vnet_pre.4.0/24";          echo $snet_addr_sqlmi
   nsg_n_sqlmi="nsg-$app-$env-sqlmi";           echo $nsg_n_sqlmi
   sqlmi_n="sqlmi-$app-$env";                   echo $sqlmi_n
   sqlmi_rt_n="rt-sqlmi-$app-$env";             echo $sqlmi_rt_n
   sqlmi_login="artiomlk";                      echo $sqlmi_login
   sqlmi_pass="Password1234567890!";            echo $sqlmi_pass
   sqlmi_bu_redundancy="Geo";                   echo $sqlmi_bu_redundancy
   ```

2. ### Create Main Resource Group

   ```bash
   # Create a resource group where our app resources will be created, e.g. AKS, ACR, vNets...
   az group create \
   --name $app_rg \
   --location $l \
   --tags $tags
   ```

3. ### Create Main vNet

   ```bash
   # Main vNet
   az network vnet create \
   --name $vnet_n \
   --resource-group $app_rg \
   --address-prefixes $vnet_addr \
   --location $l \
   --tags $tags
   ```

4. ### Create an Azure Container Registry (ACR)

   1. [Create a Resource Group][102]

   ```bash
   # Create an ACR
   az acr create \
   --name "${acr_n}" \
   --resource-group $app_rg \
   --location $l \
   --sku $acr_sku \
   --public-network-enabled true \
   --tags $tags
   ```

5. ### Create an Azure Kubernetes Service (AKS) with Azure Container Networking Interface (CNI)

   1. [Review the Azure CNI Requirements][38]
   1. [Review Maximum pods per node][39]
   1. [Create a Resource Group][102]
   1. [Create a vNet][100]
   1. Calculate Subnet size
      - (number of nodes + 1) + ((number of nodes + 1) \* maximum pods per node that you configure)
        - 50 Nodes Scaling to 60 Nodes (30 max pods per Node)
          - (51) + (51 \* 30) = 1,581 < (2,043 + 5 az) = /21 or larger
          - (61) + (61 \* 30) = 1,891 < (2,043 + 5 az) = /21 or larger
        - 10 Nodes scaling to 17 Nodes (110 max pods per Node)
          - (11) + (11 \* 110) = 1,221 < (2,043 + 5 az) = /21 or larger
          - (18) + (18 \* 110) = 1,998 < (2,043 + 5 az) = /21 or larger

   ```bash
   # AKS Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $snet_n_aks_cni \
   --address-prefixes $snet_addr_aks_cni

   # Create an User Managed Identity
   az identity create \
   -g $app_rg \
   -n $aks_id_n_cni \
   --tags $tags

   # Assign permissions to the User Managed Identity Network Contributor Role to modify vnet as required
   AKS_CNI_MANAGEDID_SP_ID=$(az identity show --resource-group $app_rg --name $aks_id_n_cni --query principalId --out tsv); echo $AKS_CNI_MANAGEDID_SP_ID
   VNET_ID=$(az network vnet show --resource-group $app_rg --name $vnet_n --query id -o tsv) ; echo $VNET_ID
   az role assignment create --assignee $AKS_CNI_MANAGEDID_SP_ID --scope $VNET_ID --role "Network Contributor"

   # Provide sNet to allocate AKS nodes
   SNET_AKS_CNI_ID=$(az network vnet subnet show --resource-group $app_rg --vnet-name $vnet_n --name $snet_n_aks_cni --query id -o tsv); echo $SNET_AKS_CNI_ID
   # Attach User Managed Identity by ID to our AKS
   AKS_CNI_MANAGEDID_ID=$(az identity show --resource-group $app_rg --name $aks_id_n_cni --query id --out tsv); echo $AKS_CNI_MANAGEDID_ID

   # OPTIONALLY - Attach ACR by ID to our AKS
   # ACR_ID=$(az acr show --name $acr_n --query 'id' --output tsv);   echo $ACR_ID
   # --attach-acr $ACR_ID \

   # Create the AKS with any of the following command
   az aks create \
   --name $aks_cluster_n_cni \
   --resource-group $app_rg \
   --kubernetes-version $aks_v_cni \
   --node-vm-size $aks_node_size_cni \
   --network-plugin azure \
   --service-cidr 10.2.0.0/24 \
   --dns-service-ip 10.2.0.10 \
   --docker-bridge-address 172.17.0.1/16 \
   --vnet-subnet-id $SNET_AKS_CNI_ID \
   --vm-set-type VirtualMachineScaleSets \
   --node-count $aks_cluster_count_cni \
   --max-pod $aks_node_max_pod_cni \
   --generate-ssh-keys \
   --enable-managed-identity \
   --assign-identity $AKS_CNI_MANAGEDID_ID \
   --tags $tags
   ```

   _If you don't have a network watcher enabled in the region that the virtual network you want to generate a topology for is in, network watchers are automatically created for you in all regions. The network watchers are created in a resource group named NetworkWatcherRG._

6. ### AKS to ACR Integration

   ```bash
   # Integrate the ACR with an existing AKS (this creates a system managed identity)
   # it authorizes the ACR in your subscription and configures the appropriate ACRPull role for the managed identity.
   # get ACR ID
   ACR_ID=$(az acr show --name ${acr_n} --query 'id' --output tsv); echo $ACR_ID
   # Attach ACR to AKS
   az aks update \
   -n $aks_cluster_n_cni \
   -g $app_rg \
   --attach-acr $ACR_ID
   ```

7. ### Create a new Application Gateway

   1. [Create a Resource Group][102]
   1. [Create a vNet][100]

   ```bash
   #AGIC PIP
   az network public-ip create \
   -n $agic_pip_n \
   -g $app_rg \
   --allocation-method Static \
   --zone 1 2 3 \
   --sku $agic_pip_sku \
   --tags $tags

   # AGIC Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $agic_snet_n \
   --address-prefixes $agic_snet_addr

   # AGW NSG with Default rules
   az network nsg create \
   --resource-group $app_rg \
   --name $agic_nsg_n \
   --location $l \
   --tags $tags

   # AllowGatewayManagerInbound
   az network nsg rule create \
   --name AllowGatewayManagerInbound \
   --direction Inbound \
   --resource-group $app_rg \
   --nsg-name $agic_nsg_n \
   --priority 300 \
   --destination-port-ranges 65200-65535 \
   --protocol TCP \
   --source-address-prefixes GatewayManager \
   --destination-address-prefixes "*" \
   --access Allow

   # AllowAzureFrontDoor.BackendInbound
   az network nsg rule create \
   --name AllowAzureFrontDoor.Backend \
   --direction Inbound \
   --resource-group $app_rg \
   --nsg-name $agic_nsg_n \
   --priority 200 \
   --destination-port-ranges 443 80 \
   --protocol TCP \
   --source-address-prefixes AzureFrontDoor.Backend \
   --destination-address-prefixes VirtualNetwork \
   --access Allow

   # Add NSG to AGIC Subnet
   az network vnet subnet update \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $agic_snet_n \
   --network-security-group $agic_nsg_n

   # APP Gateway
   az network application-gateway create \
   -n $agic_n \
   -l $l \
   -g $app_rg \
   --sku $agic_sku \
   --zone 1 2 3 \
   --public-ip-address $agic_pip_n \
   --vnet-name $vnet_n \
   --subnet $agic_snet_n \
   --tags $tags
   ```

8. ### Enable the AGIC add-on in an existing AKS cluster

   1. [If you're using kubenet with Azure Kubernetes Service (AKS) and Application Gateway Ingress Controller (AGIC), you'll need a route table to allow traffic sent to the pods from Application Gateway to be routed to the correct node. This won't be necessary if you use Azure CNI.][41]
   1. [Create a Public Azure Kubernetes Service (AKS) with Azure Container Networking Interface (CNI)][111]
   1. [Create a new Application Gateway][113]

   ```bash
   # GET APP Gateway RESOURCE ID
   AGIC_APPGW_ID=$(az network application-gateway show -n $agic_n  -g $app_rg -o tsv --query "id"); echo $AGIC_APPGW_ID
   # Enable AGIC on existing cluster
   az aks enable-addons -n $aks_cluster_n_cni -g $app_rg -a ingress-appgw --appgw-id $AGIC_APPGW_ID
   ```

   ```bash
   # Test AGIC
   echo $aks_cluster_n_cni
   echo $app_rg
   az aks get-credentials -n $aks_cluster_n_cni -g $app_rg --overwrite-existing
   kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml
   ```

9. ### Create an Azure FrontDoor

   1. [Create a Resource Group][102]
   1. Check FD name availability
      - `az network front-door check-name-availability --name $fd_n --resource-type Microsoft.Network/frontDoors`

   ```bash
   # Get the AGW Frontend Public IP
   AGW_PIP_ID=$(az network application-gateway frontend-ip show --gateway-name $agic_n  --resource-group $app_rg -n appGatewayFrontendIP --query publicIpAddress.id --out  tsv); echo $AGW_PIP_ID
   AGW_PUBLIC_IP=$(az network public-ip show --ids $AGW_PIP_ID --query ipAddress --out  tsv); echo $AGW_PUBLIC_IP
   # OR Find AGW Public IP Manually
   #az network application-gateway frontend-ip list --gateway-name $agic_n -g $app_rg
   #az network application-gateway frontend-ip show --gateway-name $agic_n -g $app_rg -n appGatewayFrontendIP
   az network front-door create \
   --backend-address $AGW_PUBLIC_IP \
   --name $fd_n \
   --resource-group $app_rg \
   --accepted-protocols Https \
   --forwarding-protocol HttpOnly \
   --protocol Http \
   --tags $tags
   ```

10. ### Configure Azure Front Door Custom Domains

    ```bash
    # Get FD ID
    FD_ID=$(az network front-door show --name $fd_n --resource-group $app_rg --query id --out  tsv); echo $FD_ID

    # Check Custom Domain mapping
    # Add CNAME:
    # Name e.g. www.kmgpty.com
    # Value: FDNAME.azurefd.net
    # TTL 7200 or lowest
    az network front-door check-custom-domain \
    --host-name $fd_host_n \
    --name $fd_n \
    --resource-group $app_rg

    # Add Custom Domain
    az network front-door frontend-endpoint create \
    --front-door-name $fd_n \
    --host-name $fd_host_n \
    --name "${app}${env}FrontendEndpoint" \
    --resource-group $app_rg

    # Enable HTTPs managed by FD, it takes up to ~1hr to complete
    az network front-door frontend-endpoint enable-https \
    --front-door-name $fd_n \
    --name "${app}${env}FrontendEndpoint" \
    --resource-group $app_rg \
    --certificate-source FrontDoor \
    --minimum-tls-version 1.2

    # ---
    # CONTINUE FROM PORTAL TO ADD BACKEND POOL AND ROUTING RULES
    # ---
    ```

11. ### Create AzureDevOps agents

    1. [Create a Resource Group][102]
    1. [Create a vNet][100]

    ```bash
    # DevOps NSG with Default rules
    az network nsg create \
    --resource-group $app_rg \
    --name $nsg_n_devops \
    --location $l \
    --tags $tags

    # DevOps Subnet
    az network vnet subnet create \
    --resource-group $app_rg \
    --vnet-name $vnet_n \
    --name $snet_n_devops \
    --address-prefixes $snet_addr_devops \
    --network-security-group $nsg_n_devops

    # vm scale set agents
    az vmss create \
    --name $devops_vm_n \
    --resource-group $app_rg \
    --image $devops_vm_img \
    --vm-sku Standard_D2_v3 \
    --storage-sku StandardSSD_LRS \
    --authentication-type SSH \
    --vnet-name $vnet_n \
    --subnet $snet_n_devops \
    --instance-count 2 \
    --disable-overprovision \
    --upgrade-policy-mode manual \
    --single-placement-group false \
    --platform-fault-domain-count 1 \
    --load-balancer "" \
    --assign-identity \
    --admin-username $user_n_test \
    --tags $tags

    # EXPECTED RESULT {"clientId": "msi"}
    az aks show -g $app_rg -n $aks_cluster_n --query "servicePrincipalProfile"
    # ----
    # IF not msi result enable AKS managed identity
    # ---
    # az aks update -g $app_rg -n $aks_cluster_n --enable-managed-identity
    # ----
    # To complete the update to managed identity upgrade the nodepools. e.g.
    # ----
    # az aks nodepool upgrade --node-image-only -g $app_rg --cluster-name $aks_cluster_n -n nodepool1


    # Configure the VMSS with a system-managed identity to grant access to the container registry
    SP_VMSS_ID=$(az vmss show --resource-group $app_rg --name $devops_vm_n --query identity.principalId --out tsv); echo $SP_VMSS_ID

    # Grant the AzDevOps VMSS system managed identity access to the ACR
    ACR_ID=$(az acr show --name $acr_n --query 'id' --output tsv);   echo $ACR_ID
    az role assignment create --assignee $SP_VMSS_ID --scope $ACR_ID --role acrpush


    # Grant the AzDevOps VMSS system managed identity access to the AKS
    AKS_ID=$(az aks show --name $aks_cluster_n -g $app_rg --query 'id' --output tsv);   echo $AKS_ID
    az role assignment create --assignee $SP_VMSS_ID --scope $AKS_ID --role Contributor

    # Validate both ACR and AKS roles
    az role assignment list --assignee $SP_VMSS_ID --scope $ACR_ID
    az role assignment list --assignee $SP_VMSS_ID --scope $AKS_ID

    # You can't RDP from outside the vnet to the vm because it ONLY has a private IP and the NSG associated does not allow RDP by default, we overcome this with a Bastion :)
    ```

12. ### Create a Bastion agent

    1. [Create a Resource Group][102]
    1. [Create a vNet][100]

    ```bash
    # Bastion
    # Bastion NSG
    az network nsg create \
    --resource-group $app_rg \
    --name $nsg_n_bastion \
    --location $l \
    --tags $tags
    # Bastion NSG Rules
    # Inbound/Ingress
    # AllowHttpsInBound
    az network nsg rule create \
    --name AllowHttpsInBound \
    --resource-group $app_rg \
    --nsg-name $nsg_n_bastion \
    --priority 120 \
    --destination-port-ranges 443 \
    --protocol TCP \
    --source-address-prefixes Internet \
    --destination-address-prefixes "*" \
    --access Allow
    # AllowGatewayManagerInbound
    az network nsg rule create \
    --name AllowGatewayManagerInbound \
    --direction Inbound \
    --resource-group $app_rg \
    --nsg-name $nsg_n_bastion \
    --priority 130 \
    --destination-port-ranges 443 \
    --protocol TCP \
    --source-address-prefixes GatewayManager \
    --destination-address-prefixes "*" \
    --access Allow
    # AllowAzureLoadBalancerInbound
    az network nsg rule create \
    --name AllowAzureLoadBalancerInbound \
    --direction Inbound \
    --resource-group $app_rg \
    --nsg-name $nsg_n_bastion \
    --priority 140 \
    --destination-port-ranges 443 \
    --protocol TCP \
    --source-address-prefixes AzureLoadBalancer \
    --destination-address-prefixes "*" \
    --access Allow
    # AllowBastionHostCommunication
    az network nsg rule create \
    --name AllowBastionHostCommunication \
    --direction Inbound \
    --resource-group $app_rg \
    --nsg-name $nsg_n_bastion \
    --priority 150 \
    --destination-port-ranges 8080 5701 \
    --protocol "*" \
    --source-address-prefixes VirtualNetwork \
    --destination-address-prefixes VirtualNetwork \
    --access Allow
    # OutBound/Egress
    # AllowSshRdpOutbound
    az network nsg rule create \
    --priority 100 \
    --name AllowSshRdpOutbound \
    --destination-port-ranges 22 3389 \
    --protocol "*" \
    --source-address-prefixes "*" \
    --destination-address-prefixes VirtualNetwork \
    --access Allow \
    --nsg-name $nsg_n_bastion \
    --resource-group $app_rg \
    --direction Outbound
    # AllowAzureCloudOutbound
    az network nsg rule create \
    --priority 110 \
    --name AllowAzureCloudOutbound \
    --destination-port-ranges 443 \
    --protocol TCP \
    --source-address-prefixes "*" \
    --destination-address-prefixes AzureCloud \
    --access Allow \
    --nsg-name $nsg_n_bastion \
    --resource-group $app_rg \
    --direction Outbound
    # AllowBastion:Communication
    az network nsg rule create \
    --priority 120 \
    --name AllowBastion:Communication \
    --destination-port-ranges 8080 5701 \
    --protocol "*" \
    --source-address-prefixes VirtualNetwork \
    --destination-address-prefixes VirtualNetwork \
    --access Allow \
    --nsg-name $nsg_n_bastion \
    --resource-group $app_rg \
    --direction Outbound
    # AllowGetSessionInformation
    az network nsg rule create \
    --priority 130 \
    --name AllowGetSessionInformation \
    --destination-port-ranges 80 \
    --protocol "*" \
    --source-address-prefixes "*" \
    --destination-address-prefixes Internet \
    --access Allow \
    --nsg-name $nsg_n_bastion \
    --resource-group $app_rg \
    --direction Outbound
    # Bastion Subnet
    az network vnet subnet create \
    --resource-group $app_rg \
    --vnet-name $vnet_n \
    --name $snet_n_bas \
    --address-prefixes $snet_addr_bas \
    --network-security-group $nsg_n_bastion

    # Bastion Public IP
    az network public-ip create \
    --resource-group $app_rg \
    --name $bastion_pip \
    --sku Standard \
    --zone 1 2 3 \
    --location $l

    # Bastion (it takes a while go get some coffee)
    az network bastion create \
    --name $bastion_n \
    --public-ip-address $bastion_pip \
    --resource-group $app_rg \
    --vnet-name $vnet_n \
    --location $l
    ```

13. ### Testing from vmss

    ```bash
    # ssh azureuser@publicIpAddress
    # https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link#validate-private-link-connection
    # validate ACR DNS resolution to private link
    nslookup $REGISTRY_NAME.azurecr.io
    dig $REGISTRY_NAME.azurecr.io

    # validate AKS DNS resolution to private link
    nslookup aks-confid-rg-confidential--5f96bd-84e3fa29.privatelink.eastus2.azmk8s.io
    dig aks-confid-rg-confidential--5f96bd-84e3fa29.privatelink.eastus2.azmk8s.io

    # Install Docker
    sudo apt-get update
    sudo apt install docker.io -y
    # Test Docker Installation
    sudo docker run -it hello-world

    # Install the Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # VALIDATE that the VMSS instances connect to the AKS connection and authenticate
    sudo az login --identity
    echo $aks_cluster_n
    echo $app_rg
    az aks get-credentials -n $aks_cluster_n -g $app_rg
    kubectl get no

    # Upload nginx sample app
    kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/kubernetes/main/definitionFiles/deploy/deploy-nginx-w-replicas.yaml
    # Create a Service Load Balancer to expose nginx through a public ip
    kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/kubernetes/main/definitionFiles/service/loadBalancer/svc-nginx-to-deploy.yaml
    ```

14. ### Create and Setup an Azure SQL Managed Instance

    1. [Review Network Requirements][29]
    1. [Create a Resource Group][102]
    1. [Create a vNet][100]

    ```bash
    # default SQLMI NSG
    az network nsg create \
    --name $nsg_n_sqlmi \
    --resource-group $app_rg \
    --location $l \
    --tags $tags

    # Create SQLMI Subnet
    az network vnet subnet create \
    --resource-group $app_rg \
    --vnet-name $vnet_n \
    --name $snet_n_sqlmi \
    --address-prefixes $snet_addr_sqlmi \
    --network-security-group $nsg_n_sqlmi \
    --delegations Microsoft.Sql/managedInstances

    # Create an SQLMI custom Route Table
    az network route-table create \
    --name $sqlmi_rt_n \
    --resource-group $app_rg \
    --location $l \
    --tags $tags

    # SQLMI RT Routes ToLocalClusterNode
    az network route-table route create \
    --name "subnet-to-vnetlocal" \
    --address-prefix $snet_addr_sqlmi \
    --next-hop-type VnetLocal \
    --resource-group $app_rg \
    --route-table-name $sqlmi_rt_n

    # Configure SNET with Custom Route Table
    az network vnet subnet update\
    --vnet-name $vnet_n \
    --name $snet_n_sqlmi \
    --route-table $sqlmi_rt_n \
    --resource-group $app_rg

    # Create SQLMI
    az sql mi create \
    --name $sqlmi_n \
    --public-data-endpoint-enabled false \
    --capacity 4 \
    --minimal-tls-version 1.2 \
    --proxy-override Redirect \
    --backup-storage-redundancy $sqlmi_bu_redundancy \
    --admin-user $user_n_test \
    --admin-password $sqlmi_pass \
    --resource-group $app_rg \
    --subnet $snet_n_sqlmi \
    --vnet-name $vnet_n \
    --location $l \
    --tags $tags
    ```

15. ### Cleanup resources

    ```bash
    az group delete -n $app_rg -y --no-wait
    ```

## Additional Resources

- ACR
- [MS | Docs | Authenticate with Azure Container Registry from Azure Kubernetes Service][3]
- [MS | Docs | Azure Container Registry authentication with service principals][13]
- [MS | Docs | Authenticate with an Azure container registry][14]
- [MS | Docs | Push your first image to your Azure container registry using the Docker CLI][15]
- AKS
- [MS | Docs | Container insights overview][4]
- [MS | Docs | Create a private Azure Kubernetes Service cluster][11]
- [MS | Docs | Use managed identities in Azure Kubernetes Service][21]
- [MS | Docs | Network concepts for applications in Azure Kubernetes Service (AKS)][23]
- [MS | Docs | Use kubenet networking with your own IP address ranges in Azure Kubernetes Service (AKS)][24]
- [MS | Docs | Best practices for cluster isolation in Azure Kubernetes Service (AKS)][34]
- [MS | Docs | Configure Azure CNI networking in Azure Kubernetes Service (AKS)][35]
- [MS | Docs | Configure Azure CNI networking in Azure Kubernetes Service (AKS) - Prerequisites][38]
- [MS | Docs | Maximum pods per node][39]
- [Understanding kubernetes networking: pods][36]
- [Medium | AKS: Kubenet vs Azure CNI][37]
- AGIC
- [MS | Docs | What is Application Gateway Ingress Controller?][40]
- [MS | Docs | Application Gateway infrastructure configuration][41]
- [MS | Docs | Quickstart: Direct web traffic with Azure Application Gateway - Azure CLI][42]
- [MS | Docs | Enable the Ingress Controller add-on for a new AKS cluster with a new Application Gateway instance][43]
- [MS | Docs | Enable Application Gateway Ingress Controller add-on for an existing AKS cluster with an existing Application Gateway][44]
- FD
- [MS | Docs | Frequently asked questions for Azure Front Door][45]
- DNS
- [MS | Docs | What is Azure Private DNS?][25]
- [MS | Docs | What is the auto registration feature in Azure DNS private zones?][8]
- [MS | Docs | Azure Private Endpoint DNS configuration][9]
- [MS | Docs | Azure DNS private zones scenarios][12]
- [MS | Docs | Create a private Azure Kubernetes Service cluster - Configure Private DNS Zone][22]
- Security Center
- [MS | Docs | The Microsoft security difference][5]
- Managed Identity
- [MS | Docs | Create a user-assigned managed identity][26]
- Azure DevOps
- [MS | Docs | Azure virtual machine scale set agents][2]
- [MS | Docs | Service connections][17]
- [MS | Docs | Get started with Azure DevOps CLI][18]
- Azure VM Scale Sets
- [MS | Docs | Configure managed identities for Azure resources on a virtual machine scale set using Azure CLI][19]
- [MS | Docs | Use an Azure managed identity to authenticate to an Azure container registry][20]
- Azure Bastion
- [MS | Docs | Working with NSG access and Azure Bastion][16]
- Azure SQL managed Instance
- [MS | Docs | Determine required subnet size & range for Azure SQL Managed Instance][27]
- [MS | Docs | Configure an existing virtual network for Azure SQL Managed Instance][28]
- [MS | Docs | SQL Managed Instance virtual network requirements][29]
- [MS | Docs | Use CLI to create an Azure SQL Managed Instance][30]
- [MS | Docs | Enabling service-aided subnet configuration for Azure SQL Managed Instance][31]
- [MS | Docs | Azure SQL Managed Instance connection types][32]
- [MS | Docs | Quickstart: Configure an Azure VM to connect to Azure SQL Managed Instance][33]
- [MS | Docs | Configuring backup storage redundancy in Azure SQL][46]
- [MS | Docs | Automated backups - Azure SQL Database & Azure SQL Managed Instance][47]
- [MS | Docs | Creating and using active geo-replication - Azure SQL Database][48]
- ACR Private Link
- [MS | Docs | What is Azure Private Link service?][10]
- [MS | Docs | Connect privately to an Azure container registry using Azure Private Link][6]
- [MS | Docs | Azure Container Registry: Mitigating data exfiltration with dedicated data endpoints][7]
- Others
- [Git Bash | GitHub | azure cli commands automatically appends git-bash path in the parameter that contains forward slash][1]

[0]: ./azFirewallPremium.md
[1]: https://github.com/Azure/azure-cli/issues/14299
[2]: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops#create-the-scale-set-agent-pool
[3]: https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration
[4]: https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview
[5]: https://www.microsoft.com/en-us/security/business/operations
[6]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link
[7]: https://azure.microsoft.com/en-us/blog/azure-container-registry-mitigating-data-exfiltration-with-dedicated-data-endpoints/
[8]: https://docs.microsoft.com/en-us/azure/dns/private-dns-autoregistration
[9]: https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns
[10]: https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview
[11]: https://docs.microsoft.com/en-us/azure/aks/private-clusters
[12]: https://docs.microsoft.com/en-us/azure/dns/private-dns-scenarios
[13]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal
[14]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication?tabs=azure-cli
[15]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-docker-cli?tabs=azure-cli
[16]: https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg
[17]: https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints
[18]: https://docs.microsoft.com/en-us/azure/devops/cli
[19]: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vmss
[20]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication-managed-identity#example-2-access-with-a-system-assigned-identity
[21]: https://docs.microsoft.com/en-us/azure/aks/use-managed-identity#create-an-aks-cluster-with-managed-identities
[22]: https://docs.microsoft.com/en-us/azure/aks/private-clusters#configure-private-dns-zone
[23]: https://docs.microsoft.com/en-us/azure/aks/concepts-network
[24]: https://docs.microsoft.com/en-us/azure/aks/configure-kubenet
[25]: https://docs.microsoft.com/en-us/azure/dns/private-dns-overview
[26]: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azcli
[27]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/vnet-subnet-determine-size
[28]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/vnet-existing-add-subnet
[29]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connectivity-architecture-overview#network-requirements
[30]: https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-create-configure-managed-instance-cli
[31]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/subnet-service-aided-configuration-enable
[32]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connection-types-overview
[33]: https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/connect-vm-instance-configure
[34]: https://docs.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-isolation
[35]: https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni
[36]: https://waterplacid.files.wordpress.com/2018/04/understanding-kubernetes-networking.pdf
[37]: https://mehighlow.medium.com/aks-kubenet-vs-azure-cni-363298dd53bf
[38]: https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#prerequisites
[39]: https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni#maximum-pods-per-node
[40]: https://docs.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview
[41]: https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure
[42]: https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-cli
[43]: https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-new
[44]: https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing
[45]: https://docs.microsoft.com/en-us/azure/frontdoor/front-door-faq
[46]: https://techcommunity.microsoft.com/t5/azure-sql/configuring-backup-storage-redundancy-in-azure-sql/ba-p/1554322
[47]: https://docs.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview
[48]: https://docs.microsoft.com/en-us/azure/azure-sql/database/active-geo-replication-overview
[100]: #create-main-vnet
[101]: #configure-azure-front-door-custom-domains
[102]: #create-main-resource-group
[103]: #connect-to-our-azure-subscription
[104]: #empty
[105]: #create-an-azure-container-registry-acr
[106]: #empty
[107]: #aks-to-acr-integration
[108]: #create-azuredevops-agents
[109]: #create-a-bastion-agent
[110]: #create-and-setup-an-azure-sql-managed-instance
[111]: #create-an-azure-kubernetes-service-aks-with-azure-container-networking-interface-cni
[112]: #enable-the-agic-add-on-in-an-existing-aks-cluster
[113]: #create-a-new-application-gateway
[114]: #create-an-azure-frontdoor
