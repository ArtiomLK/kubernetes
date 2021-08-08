# AKS Authentication to Azure KeyVault with (CSI) Container Storage Interface Secret Store Driver

## Requirements

- [Create an AKS Cluster][5]

## Code

```bash
# Set Up params IF required
# ---
# Main Vars
# ---
app="akscni";                                 echo $app
env="prod";                                   echo $env
app_rg="rg-$app-$env";                        echo $app_rg
l="eastus2";                                  echo $l
tags="env=$env app=$app";                     echo $tags

# KV
kv_n="kv-$app-$env";                          echo $kv_n
# AKS
aks_cluster_n="aks-$app-cni-$env";            echo $aks_cluster_n
# ID
aks_id_n="id-$app-aks-$env";                  echo $aks_id_n
```

```bash
# ---
# Enable AKS preview
# ---
az extension add --name aks-preview
# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview
# Review AKS preview installation (Installed true)
az extension list-available --output table --query "[?contains(name, 'aks-preview')]"

# ---
# Create a KV
# ---
az keyvault create --name $kv_n --resource-group $app_rg --location $l --tags $tags
# add a secret to the KV
az keyvault secret set --vault-name $kv_n --name "ExamplePassword" --value "123456789"
az keyvault secret set --vault-name $kv_n --name "MySecret" --value "123"
# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "ExamplePassword" --query "value"
az keyvault secret show --vault-name $kv_n --name "MySecret" --query "value"

# ---
# Enable Manged Identity on AKS
# ---
# EXPECTED RESULT {"clientId": "msi"}
az aks show -g $app_rg -n $aks_cluster_n --query "servicePrincipalProfile"
# ---
# Otherwise enable Managed Identity on AKS IF RESULT ISN'T {"clientId": "msi"}
az aks update -g $app_rg -n $aks_cluster_n --enable-managed-identity # RUN ONLY IF RESULT ISN'T {"clientId": "msi"}
# To complete the update to managed identity upgrade the nodepools. e.g.
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
--addons azure-keyvault-secrets-provider
# Verify aks-secrets-store-csi-driver and providers but first Connect to your AKS cluster
az aks get-credentials -g $app_rg -n $aks_cluster_n --overwrite-existing
# Verify
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

# Get your generated KeyVault Managed Identity resource ID
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
# Secret Provider
# ---
az feature unregister --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
# State unregistered
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"

# ---
# aks-preview
# ---
# If you're not planning to keep using aks preview features, then uninstall aks-preview
az extension remove -n aks-preview
# Check AKS preview installation (Installed false)
az extension list-available --output table --query "[?contains(name, 'aks-preview')]"

az group delete -n $app_rg -y
az keyvault purge --name $kv_n --location $l --no-wait
```

## Additional Resources

- AKS
- [MS | Docs | Use the Secrets Store CSI Driver for Kubernetes in an Azure Kubernetes Service (AKS) cluster (preview)][4]
- [MS | Docs | Best practices for pod security in Azure Kubernetes Service (AKS)][1]
- [MS | Docs | Use Azure Active Directory pod-managed identities in Azure Kubernetes Service][2]
- KV
- [MS | Docs | Set and retrieve a secret from Azure Key Vault using Azure CLI][3]

[1]: https://docs.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[2]: https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity
[3]: https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
[4]: https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
[5]: ./../aks_cni.md
