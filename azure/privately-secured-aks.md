# AKS - Azure Kubernetes Service Zero Trust Environment

## Introduction

Connect privately to Azure Kubernetes Services and Azure Container Registry using Azure Private Links

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
   app="confidential";                 echo $app
   env="uat";                          echo $env
   l="eastus2";                        echo $l
   tags="env=$env app=$app";           echo $tags
   vm_user="artiomlk";                 echo $vm_user

   log_rg="rg-log-$app-$env";          echo $log_rg
   log_n="log-$app-$env";              echo $log_n

   app_rg="rg-$app-$env";              echo $app_rg
   arm_sc_n="sc-sub-alk";              echo $arm_sc_n
   acr_sc_n="acr-sc-$env";             echo $acr_sc_n


   # ---
   # NETWORK TOPOLOGY
   # ---
   #NSG
   nsg_n_default="nsg-$app-$env-default"; echo $nsg_n_default
   nsg_n_bastion="nsg-$app-$env-bastion"; echo $nsg_n_bastion
   #VNET
   vnet_pre="10.5";                       echo $vnet_pre
   vnet_n="vnet-$app-$env";               echo $vnet_n
   vnet_addr="$vnet_pre.0.0/16";          echo $vnet_addr
   #Bastion
   snet_n_bas="AzureBastionSubnet";       echo $snet_n_bas
   snet_addr_bas="$vnet_pre.1.0/27";      echo $snet_addr_bas
   #Az DevOps Agents
   snet_n_devops="snet-$app-$env-devops"; echo $snet_n_devops
   snet_addr_devops="$vnet_pre.2.0/24";   echo $snet_addr_devops
   #Private Endpoints
   snet_n_pe="snet-$app-$env-pe";         echo $snet_n_pe
   snet_addr_pe="$vnet_pre.3.0/24";       echo $snet_addr_pe
   #AKS
   snet_n_aks="snet-$app-$env-aks";       echo $snet_n_aks
   snet_addr_aks="$vnet_pre.8.0/21";      echo $snet_addr_aks

   # ---
   # ACR
   # ---
   acr_n="cr$app$env";                    echo $acr_n
   acr_sku="Premium";                     echo $acr_sku
   dns_link="dnslink-$acr_n";             echo $dns_link
   pe_n="pe-$acr_n";                      echo $pe_n

   # ---
   # AKS
   # ---
   aks_cluster_n="aks-$app-$env";         echo $aks_cluster_n
   aks_cluster_count="3";                 echo $aks_cluster_count
   aks_v="1.20.7";                        echo $aks_v
   aks_node_size="Standard_B2s";          echo $aks_node_size
   aks_id_n="id-$app-$env";               echo $aks_id_n

   # ---
   # Bastion
   # ---
   bastion_n="bastion-$app-$env";            echo $bastion_n
   bastion_pip="pip-bastion-$app-$env";      echo $bastion_pip
   ```

2. ### Create Topology

   ```bash
   # ---
   # Create a resource group where our app resources will be created, e.g. AKS, ACR, vNets...
   # ---
   az group create \
   --name $app_rg \
   --location $l \
   --tags $tags

   # Default NSG
   az network nsg create \
   --resource-group $app_rg \
   --name $nsg_n_default \
   --location $l \
   --tags $tags

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

   # Main vNet
   az network vnet create \
   --name $vnet_n \
   --resource-group $app_rg \
   --address-prefixes $vnet_addr \
   --location $l \
   --tags $tags

   # Bastion Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $snet_n_bas \
   --address-prefixes $snet_addr_bas \
   --network-security-group $nsg_n_bastion

   # DevOps Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $snet_n_devops \
   --address-prefixes $snet_addr_devops \
   --network-security-group $nsg_n_default

   # Private Endpoint Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $snet_n_pe \
   --address-prefixes $snet_addr_pe \
   --network-security-group $nsg_n_default

   # AKS Subnet
   az network vnet subnet create \
   --resource-group $app_rg \
   --vnet-name $vnet_n \
   --name $snet_n_aks \
   --address-prefixes $snet_addr_aks
   ```

3. ### Create the Azure Container Registry (ACR)

   ```bash
   # Create a private ACR
   az acr create \
   --name $acr_n \
   --resource-group $app_rg \
   --location $l \
   --sku $acr_sku \
   --public-network-enabled false \
   --tags $tags

   # [OPTIONALLY] Integrate the ACR with an existing AKS (this creates a system managed identity)
   # it authorizes the ACR in your subscription and configures the appropriate ACRPull role for the managed identity.
   # get ACR ID
   ACR_ID=$(az acr show --name $acr_n --query 'id' --output tsv);   echo $ACR_ID
   az aks update \
   -n myAKSCluster \
   -g $app_rg \
   --attach-acr $ACR_ID

   # [OPTIONALLY] Create a public ACR to see the difference
   az acr create \
   --name "${acr_n}publict" \
   --resource-group $app_rg \
   --location $l \
   --sku $acr_sku \
   --public-network-enabled true \
   --tags $tags
   ```

4. ### Create a private Link to ACR

   ```bash
   # Disable network policies in the private endpoint subnet
   az network vnet subnet update \
   --vnet-name $vnet_n \
   --name $snet_n_pe \
   --resource-group $app_rg \
   --disable-private-endpoint-network-policies

   # Create a Custom Private DNS
   # The FQDN of the services resolves automatically to a public IP address. To resolve to the private IP address of the private endpoint, change your DNS configuration.
   az network private-dns zone create \
   --resource-group $app_rg \
   --name "privatelink.azurecr.io" \
   --tags $tags

   # Create an association link to associate your private zone with the virtual network
   az network private-dns link vnet create \
   --resource-group $app_rg \
   --zone-name "privatelink.azurecr.io" \
   --name $dns_link \
   --virtual-network $vnet_n \
   --registration-enabled false \
   --tags $tags

   # Create a private ACR endpoint
   ACR_ID=$(az acr show --name $acr_n --query 'id' --output tsv);   echo $ACR_ID

   # TODO replace groups-ids
   # --group-ids' has been deprecated and will be removed in a future release. Use '--group-id' instead
   az network private-endpoint create \
    --name $pe_n \
    --resource-group $app_rg \
    --vnet-name $vnet_n \
    --subnet $snet_n_pe \
    --private-connection-resource-id $ACR_ID \
    --group-ids registry \
    --connection-name "$pe_n-connection" \
    --tags $tags --verbose

   # ---
   # GET ENDPOINT IP CONFIGURATIONS
   # two private IP addresses for the container registry:
   # one for the registry itself, and one for the registry's data endpoint.
   # ---
   # Get the private endpoint network interface ID
   NETWORK_INTERFACE_ID=$(az network private-endpoint show \
    --name $pe_n \
    --resource-group $app_rg \
    --query 'networkInterfaces[0].id' \
    --output tsv); echo $NETWORK_INTERFACE_ID

   REGISTRY_PRIVATE_IP=$(az network nic show \
   --ids $NETWORK_INTERFACE_ID \
   --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry'].privateIpAddress" \
   --output tsv); echo $REGISTRY_PRIVATE_IP

   DATA_ENDPOINT_PRIVATE_IP=$(az network nic show \
   --ids $NETWORK_INTERFACE_ID \
   --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry_data_$l'].privateIpAddress" \
   --output tsv); echo $DATA_ENDPOINT_PRIVATE_IP

   # An FQDN is associated with each IP address in the IP configurations
   REGISTRY_FQDN=$(az network nic show \
   --ids $NETWORK_INTERFACE_ID \
   --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry'].privateLinkConnectionProperties.fqdns" \
   --output tsv);   echo $REGISTRY_FQDN

   DATA_ENDPOINT_FQDN=$(az network nic show \
   --ids $NETWORK_INTERFACE_ID \
   --query "ipConfigurations[?privateLinkConnectionProperties.requiredMemberName=='registry_data_$l'].privateLinkConnectionProperties.fqdns" \
   --output tsv); echo $DATA_ENDPOINT_FQDN

   # Create the A records for the registry endpoint and data endpoint

   # Registry endpoint
   az network private-dns record-set a add-record \
   --record-set-name $acr_n \
   --zone-name privatelink.azurecr.io \
   --resource-group $app_rg \
   --ipv4-address $REGISTRY_PRIVATE_IP

   # Specify registry region in data endpoint name
   az network private-dns record-set a add-record \
   --record-set-name "$acr_n.$l.data" \
   --zone-name privatelink.azurecr.io \
   --resource-group $app_rg \
   --ipv4-address $DATA_ENDPOINT_PRIVATE_IP
   ```

5. ### Create the Azure Kubernetes Service (AKS)

   ```bash
   # Create an User Managed Identity
   az identity create \
   -g $app_rg \
   -n $aks_id_n

   # Assign permissions to the User Managed Identity Network Contributor Role to modify vnet as required
   MANAGEDID_SP_ID=$(az identity show --resource-group $app_rg --name $aks_id_n --query principalId --out tsv); echo $MANAGEDID_SP_ID
   VNET_ID=$(az network vnet show --resource-group $app_rg --name $vnet_n --query id -o tsv) ; echo $VNET_ID
   az role assignment create --assignee $MANAGEDID_SP_ID --scope $VNET_ID --role "Network Contributor"

   # Create a Custom Private DNS for AKS private link
   # The FQDN of the services resolves automatically to a public IP address. To resolve to the private IP address of the private endpoint, change your DNS configuration.
   az network private-dns zone create \
   --resource-group $app_rg \
   --name "privatelink.$l.azmk8s.io" \
   --tags $tags

   # Create an association link to associate your private zone with the virtual network
   az network private-dns link vnet create \
   --resource-group $app_rg \
   --zone-name "privatelink.$l.azmk8s.io" \
   --name "dnslink-$aks_cluster_n" \
   --virtual-network $vnet_n \
   --registration-enabled false \
   --tags $tags

   # Assign permissions to the User Managed Identity private dns zone contributor to modify the private dns zone as required
   MANAGEDID_SP_ID=$(az identity show --resource-group $app_rg --name $aks_id_n --query principalId --out tsv); echo $MANAGEDID_SP_ID
   AKS_PDNSZ_ID=$(az network private-dns zone show --resource-group $app_rg --name "privatelink.$l.azmk8s.io" --query id -o tsv) ; echo $AKS_PDNSZ_ID
   az role assignment create --assignee $MANAGEDID_SP_ID --scope $AKS_PDNSZ_ID --role "Private DNS Zone Contributor"


   # GET AKS CREATE OTHER AZ RESOURCES IDS
   ACR_ID=$(az acr show --name $acr_n --query 'id' --output tsv);   echo $ACR_ID
   SNET_AKS_ID=$(az network vnet subnet show --resource-group $app_rg --vnet-name $vnet_n --name $snet_n_aks --query id -o tsv); echo $SNET_AKS_ID
   MANAGEDID_ID=$(az identity show --resource-group $app_rg --name $aks_id_n --query id --out tsv); echo $MANAGEDID_ID

   # Create the AKS with any of the following command
   az aks create \
   --name $aks_cluster_n \
   --resource-group $app_rg \
   --kubernetes-version $aks_v \
   --node-vm-size $aks_node_size \
   --network-plugin kubenet \
   --service-cidr 10.0.0.0/16 \
   --dns-service-ip 10.0.0.10 \
   --pod-cidr 10.244.0.0/16 \
   --docker-bridge-address 172.17.0.1/16 \
   --vnet-subnet-id $SNET_AKS_ID \
   --vm-set-type VirtualMachineScaleSets \
   --node-count $aks_cluster_count \
   --generate-ssh-keys \
   --enable-managed-identity \
   --assign-identity $MANAGEDID_ID \
   --private-dns-zone $AKS_PDNSZ_ID \
   --attach-acr $ACR_ID \
   --enable-private-cluster \
   --tags $tags

   # --service-principal <appId> \ #TODO NOT REQUIRED BECAUSE USING MANAGED IDENITITY (--assign-identity)
   # --client-secret <password> \ #TODO NOT REQUIRED BECAUSE USING MANAGED IDENITITY (--assign-identity)
   ```

   _If you don't have a network watcher enabled in the region that the virtual network you want to generate a topology for is in, network watchers are automatically created for you in all regions. The network watchers are created in a resource group named NetworkWatcherRG._

6. ### Create an AzureDevOps agent

   ```bash
   # test vm that could also be used as DevOps Agent (scale sets recommend though)
   az vm create \
   --resource-group $app_rg \
   --name $devops_vm_n \
   --vnet-name $vnet_n \
   --subnet $snet_n_devops \
   --image $devops_vm_img \
   --admin-username $vm_user \
   --generate-ssh-keys \
   --public-ip-address "" \
   --nsg "" \
   --nsg-rule NONE \
   --tags $tags

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
   --admin-username $vm_user \
   --tags $tags

   # EXPECTED RESULT {"clientId": "msi"}
   az aks show -g $app_rg -n $aks_cluster_n --query "servicePrincipalProfile"

   # ----
   # IF not msi result enable AKS managed identity
   az aks update -g $app_rg -n $aks_cluster_n --enable-managed-identity
   #  to complete the update to managed identity upgrade the nodepools. e.g.
   az aks nodepool upgrade --node-image-only -g $app_rg --cluster-name $aks_cluster_n -n nodepool1
   # ----

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

7. ### Create a Bastion agent

   ```bash
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

8. ### Test Private Endpoint DNS Resolution

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

   # Test that an az VMSS instance can connect to the Private ACR
   sudo az login --identity
   echo $acr_n
   sudo az acr login -n $acr_n
   sudo az acr repository list --name $acr_n --output table

   # PUSH AN IMAGE TO ACR
   echo $acr_n
   sudo docker pull mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine
   sudo docker tag mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine $acr_n.azurecr.io/myrepo/nginx:1.0.0
   sudo docker push $acr_n.azurecr.io/myrepo/nginx:1.0.0

   # Test if image was successfully pushed to private ACR
   echo $acr_n
   sudo az acr repository list --name $acr_n --output table

   ## ANY QUESTION ABOUT ACR?
   ## IF NOT LETS MOVE TO AKS TESTS

   # VALIDATE that the VMSS instances connect to the AKS connection and authenticate
   az login --identity
   echo $aks_cluster_n
   echo $app_rg
   az aks get-credentials -n $aks_cluster_n -g $app_rg
   kubectl get no
   ```

9. ### Cleanup resources

   ```bash
   az group delete -n $app_rg -y --no-wait
   ```

## Additional Resources

- ACR Private Link
- [MS | Docs | Connect privately to an Azure container registry using Azure Private Link][6]
- [MS | Docs | Azure Container Registry: Mitigating data exfiltration with dedicated data endpoints][7]
- [MS | Docs | What is Azure Private Link service?][10]
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
- [MS | Docs | Azure virtual machine scale set agents][17]
- [MS | Docs | Get started with Azure DevOps CLI][18]
- Azure VM Scale Sets
- [MS | Docs | Configure managed identities for Azure resources on a virtual machine scale set using Azure CLI][19]
- [MS | Docs | Use an Azure managed identity to authenticate to an Azure container registry][20]
- Azure Bastion
- [MS | Docs | Working with NSG access and Azure Bastion][16]
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
