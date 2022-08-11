# AKS Authentication to Azure KeyVault with (CSI) Container Storage Interface Secret Store Driver

## Requirements

- Create an AKS Cluster
  - [You could follow these steps to create an AKS CNI Cluster][5]

## Code

```bash
export MSYS_NO_PATHCONV=1
# ---
# Main Vars
# ---
app="confidential";                           echo $app
env="qa";                                     echo $env
app_rg="rg-$app-$env";                        echo $app_rg
l="eastus";                                   echo $l
tags="env=$env app=$app";                     echo $tags

# KV
kv_n="kv-$app-$env";                          echo $kv_n
# AKS
aks_cluster_n="aks-$app-$env";                echo $aks_cluster_n
aks_node_count="3";                           echo $aks_node_count
aks_v="1.22.4";                               echo $aks_v
aks_node_size="Standard_B2s";                 echo $aks_node_size
# ID
aks_id_n="id-$app-aks-$env";                  echo $aks_id_n
```

### Create a new AKS cluster

```bash
# You can skip this section if you have an existing cluster you want to use
# Note: you must override the $aks params with your existing cluster values
az aks create \
--name $aks_cluster_n \
--resource-group $app_rg \
--kubernetes-version $aks_v \
--node-vm-size $aks_node_size \
--node-count $aks_node_count \
--generate-ssh-keys \
--enable-managed-identity \
--enable-addons monitoring \
--tags $tags
```

---

### Create an Azure Key Vault

```bash
# ---
# Create a KV
# ---
az keyvault create --name $kv_n --resource-group $app_rg --location $l --tags $tags
# add a secret to the KV
az keyvault secret set --vault-name $kv_n --name "ExamplePassword" --value "light"
az keyvault secret set --vault-name $kv_n --name "MySecret" --value "123"
az keyvault certificate create --vault-name $kv_n --name "MyCert" --policy "$(az keyvault certificate get-default-policy)"
az keyvault key create --vault-name $kv_n --name "MyKey" --protection software
# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "ExamplePassword" --query "value"
az keyvault secret show --vault-name $kv_n --name "MySecret" --query "value"
az keyvault certificate show --vault-name $kv_n --name "MyCert" --query "cer"
az keyvault key show --vault-name $kv_n --name "MyKey" --query "key.n"
```

```bash
# ---
# Enable Manged Identity on AKS
# ---
# EXPECTED RESULT {"clientId": "msi"}
az aks show -g $app_rg -n $aks_cluster_n --query "servicePrincipalProfile"
# ---
# Otherwise enable Managed Identity on AKS IF RESULT ISN'T {"clientId": "msi"}
az aks update -g $app_rg -n $aks_cluster_n --enable-managed-identity # RUN ONLY IF RESULT ISN'T {"clientId": "msi"}
# To complete the update to managed identity upgrade the nodepools. e.g. nodepool1
az aks nodepool upgrade --node-image-only -g $app_rg --cluster-name $aks_cluster_n -n nodepool1
# ---

# ---
# Create the SecretProvider
# ---
# register the Secret Provider
az feature register --name AKS-AzureKeyVaultSecretsProvider --namespace Microsoft.ContainerService
# Check if registered
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
# When ready, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command:
az provider register --namespace Microsoft.ContainerService
# check installation status
az provider list -o table --query "[?contains(namespace, 'Microsoft.ContainerService')]"

# REGISTER AKS FOR SECRET STORE CSI DRIVER SUPPORT
az aks enable-addons \
--name $aks_cluster_n \
--resource-group $app_rg \
--addons azure-keyvault-secrets-provider \
--enable-secret-rotation \
--rotation-poll-interval 30s

# Verify aks-secrets-store-csi-driver and providers but first Connect to your AKS cluster
az aks get-credentials -g $app_rg -n $aks_cluster_n --overwrite-existing
# Verify
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)' -o wide

# Get your generated KeyVault User Managed Identity resource ID
ID_KVPROVIDER_CLIENT_ID=$(az aks show -g $app_rg -n $aks_cluster_n --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" --out tsv); echo $ID_KVPROVIDER_CLIENT_ID
az keyvault set-policy -n $kv_n --secret-permissions get --spn $ID_KVPROVIDER_CLIENT_ID

# YOU MUST REPLACE from the secret-provider.yaml file the following parameters
echo $ID_KVPROVIDER_CLIENT_ID # userAssignedIdentityID with
echo $kv_n # keyvaultName
az account show --query tenantId # tenantId
# OPTIONALLY replace namespace

kubectl apply -f secret-provider.yaml
# Verify if secretProviderClass created
kubectl get SecretProviderClass
kubectl describe SecretProviderClass my-secret-provider

# ---
# Deploy a Sample App
# ---
kubectl apply -f pod-def-w-secrets.yaml
kubectl apply -f pod-def-w-secrets-busybox.yaml
kubectl get pods

# ---
# Test access with authorization to KeyVault Secrets
# ---
## show secrets held in secrets-store
kubectl exec nginx-secrets-store-inline -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec nginx-secrets-store-inline -- cat /mnt/secrets-store/ExamplePassword
kubectl exec nginx-secrets-store-inline -- cat /mnt/secrets-store/MySecret

## show secrets held in secrets-store
kubectl exec busybox-secrets-store-inline -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-secrets-store-inline -- cat /mnt/secrets-store/ExamplePassword
kubectl exec busybox-secrets-store-inline -- cat /mnt/secrets-store/MySecret
```

## Clean-up

```bash
# ---
# Uninstall CSI Driver
# ---
# delete created SecretProvider
kubectl delete SecretProviderClass my-secret-provider
kubectl get SecretProviderClass

# delete pods using SecretProdiver
kubectl delete -f pod-def-w-secrets.yaml
kubectl delete -f pod-def-w-secrets-busybox.yaml
kubectl get po

# delete aks-secret-store-provider-azure-perNode
# delete aks-secret-store-csi-driver-perNode
az aks disable-addons \
--name $aks_cluster_n \
--resource-group $app_rg \
--addons azure-keyvault-secrets-provider
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)' -o wide
# ---
# Secret Provider
# ---
az feature unregister --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
# State unregistered
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"

az group delete -n $app_rg -y
az keyvault purge --name $kv_n --location $l --no-wait
```

## Additional Resources

- AKS
- [MS | Docs | Use the Secrets Store CSI Driver for Kubernetes in an Azure Kubernetes Service (AKS) cluster (preview)][4]
- KV
- [MS | Docs | Set and retrieve a secret from Azure Key Vault using Azure CLI][3]

[3]: https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
[4]: https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
[5]: ./../aks_cni.md#create-an-azure-kubernetes-service-aks-with-azure-container-networking-interface-cni
