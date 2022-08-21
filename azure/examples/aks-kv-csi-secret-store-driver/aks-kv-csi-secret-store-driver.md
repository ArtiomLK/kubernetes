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
app="confidential";                                   echo $app
env="qa";                                             echo $env
app_rg="rg-$app-$env";                                echo $app_rg
l="eastus";                                           echo $l
tags="env=$env app=$app";                             echo $tags
sub_id="########-####-####-####-############";        echo $sub_id

# KV
kv_rg="rg-kv-$app-$env";                              echo $kv_rg
kv_n="kv-$app-$env";                                  echo $kv_n

# AKS
aks_cluster_n="aks-$app-$env";                        echo $aks_cluster_n
aks_node_count="3";                                   echo $aks_node_count
aks_v="1.23.8";                                       echo $aks_v
aks_node_size="Standard_B2s";                         echo $aks_node_size
aks_ns="kv-ns";                                       echo $aks_ns
# ID
aks_id_n="id-$app-aks-$env";                          echo $aks_id_n
```

### Create Resource Groups

```bash
# AKS RG
az group create \
--name $app_rg \
--subscription $sub_id \
--location $l \
--tags $tags

# KV RG
az group create \
--name $kv_rg \
--subscription $sub_id \
--location $l \
--tags $tags
```

### Create a new AKS cluster

```bash
# You can skip this section if you have an existing cluster you want to use
# Note: you must override the $aks params with your existing cluster values
# IF AKS version becomes unavailable
az aks get-versions -l $l -o table

# Create AKS cluster
az aks create \
--name $aks_cluster_n \
--subscription $sub_id \
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
# rm enable-rbac-authorization if using kv access policies
az keyvault create \
--name $kv_n \
--subscription $sub_id \
--resource-group $kv_rg \
--location $l \
--enable-rbac-authorization \
--tags $tags

# ---
# Allow user to create secrets IF using RBAC
# ---
# get user name
USER_N=$(az account show --query "user.name" -o tsv); echo $USER_N
# Get kv resource id
KV_ID=$(az keyvault show --name $kv_n --query "id" -o tsv); echo $KV_ID

# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-administrator
az role assignment create \
--assignee $USER_N \
--role "Key Vault Administrator" \
--scope $KV_ID

# Secrets
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
az role assignment create \
--assignee $USER_N \
--role "Key Vault Secrets Officer" \
--scope $KV_ID

# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user
az role assignment create \
--assignee $USER_N \
--role "Key Vault Secrets User" \
--scope $KV_ID

# Certificates
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-certificates-officer
az role assignment create \
--assignee $USER_N \
--role "Key Vault Certificates Officer" \
--scope $KV_ID

# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-reader
az role assignment create \
--assignee $USER_N \
--role "Key Vault Reader" \
--scope $KV_ID

# Keys
# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-crypto-officer
az role assignment create \
--assignee $USER_N \
--role "Key Vault Crypto Officer" \
--scope $KV_ID

# https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-crypto-user
az role assignment create \
--assignee $USER_N \
--role "Key Vault Crypto User" \
--scope $KV_ID

# ---
# add sample secret to the KV
# ---
az keyvault secret set --vault-name $kv_n --name "kv-secret-1" --value "kv-secret-1-value"
az keyvault secret set --vault-name $kv_n --name "kv-secret-2" --value "kv-secret-2-value"
az keyvault certificate create --vault-name $kv_n --name "MyCert" --policy "$(az keyvault certificate get-default-policy)"
az keyvault key create --vault-name $kv_n --name "MyKey" --protection software

# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "kv-secret-1" --query "value"
az keyvault secret show --vault-name $kv_n --name "kv-secret-2" --query "value"
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
--rotation-poll-interval 10s

# Verify aks-secrets-store-csi-driver and providers but first Connect to your AKS cluster
az aks get-credentials -g $app_rg -n $aks_cluster_n --overwrite-existing
# Verify
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)' -o wide

# Get your generated KeyVault User Managed Identity resource ID
ID_KVPROVIDER_CLIENT_ID=$(az aks show -g $app_rg -n $aks_cluster_n --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" --out tsv); echo $ID_KVPROVIDER_CLIENT_ID

# Get kv resource id
KV_ID=$(az keyvault show --name $kv_n --query "id" -o tsv); echo $KV_ID

az role assignment create \
--assignee $ID_KVPROVIDER_CLIENT_ID \
--role "Key Vault Secrets User" \
--scope $KV_ID

# az keyvault set-policy -n $kv_n --secret-permissions get --spn $ID_KVPROVIDER_CLIENT_ID
```

## Sync CSI Driver Secrets to Pod Volumes

```bash
# YOU MUST REPLACE from the secret-provider-to-pod-volumes.yaml file the following parameters
echo $ID_KVPROVIDER_CLIENT_ID # userAssignedIdentityID with
echo $kv_n # keyvaultName
az account show --query tenantId # tenantId
# OPTIONALLY replace metadata.namespace
echo $aks_ns

# OPTIONALLY If working from a different k8s namespace
# Creates a new k8s ns
echo kubectl create ns $aks_ns
kubectl get ns
# set k8s ns
echo kubectl config set-context --current --namespace=$aks_ns
kubectl config view | grep namespace

## Create CSI Secret Store Driver
kubectl apply -f secret-provider-to-pod-volumes.yaml
# Verify if secretProviderClass created
kubectl get SecretProviderClass
kubectl describe SecretProviderClass secret-provider-to-pod-volumes

# ---
# Deploy a Sample App
# OPTIONALLY replace metadata.namespace
# OPTIONALLY replace spec.volumes.csi.volumeAttributes.secretProviderClass.secretProviderClass
echo $aks_ns
# ---
kubectl apply -f pod-def-nginx-w-secrets-from-pod-volume.yaml
kubectl apply -f pod-def-busybox-w-secrets-from-pod-volume.yaml
kubectl get pods

# ---
# Test access with authorization to KeyVault Secrets
# ---
## show secrets held in secrets-store
kubectl exec nginx-w-secrets-from-pod-volume -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec nginx-w-secrets-from-pod-volume -- cat /mnt/secrets-store/kv-secret-1
kubectl exec nginx-w-secrets-from-pod-volume -- cat /mnt/secrets-store/kv-secret-2

## show secrets held in secrets-store
kubectl exec busybox-w-secrets-from-pod-volume -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-w-secrets-from-pod-volume -- cat /mnt/secrets-store/kv-secret-1
kubectl exec busybox-w-secrets-from-pod-volume -- cat /mnt/secrets-store/kv-secret-2
```

## Sync CSI Secrets to k8s Secret

```bash
# YOU MUST REPLACE from the secret-provider.yaml file the following parameters
echo $ID_KVPROVIDER_CLIENT_ID # userAssignedIdentityID with
echo $kv_n # keyvaultName
az account show --query tenantId # tenantId
# OPTIONALLY replace metadata.namespace
echo $aks_ns

# OPTIONALLY If working from a different k8s namespace
# Creates a new k8s ns
echo kubectl create ns $aks_ns
kubectl get ns
# set k8s ns
echo kubectl config set-context --current --namespace=$aks_ns
kubectl config view | grep namespace

## Create CSI Secret Store Driver
kubectl apply -f secret-provider-to-k8s-secrets.yaml
# Verify if secretProviderClass created
kubectl get SecretProviderClass
kubectl describe SecretProviderClass secret-provider-to-k8s-secrets

# ---
# Deploy a Sample App
# ---
kubectl apply -f pod-def-nginx-w-secrets-from-k8s-secret.yaml
kubectl apply -f pod-def-busybox-w-secrets-from-k8s-secret.yaml
kubectl get pods

kubectl get secret
kubectl get secret k8s-secret
kubectl describe secret k8s-secret
kubectl get secret k8s-secret -o jsonpath='{.data.k8s-secret-1}' | base64 --decode
kubectl get secret k8s-secret -o jsonpath='{.data.k8s-secret-2}' | base64 --decode

kubectl exec -it nginx-w-secrets-from-k8s-secret -- env
kubectl exec -it busybox-w-secrets-from-k8s-secret -- env
# ---
## show secrets held in secrets-store
kubectl exec nginx-w-secrets-from-k8s-secret -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec nginx-w-secrets-from-k8s-secret -- cat /mnt/secrets-store/kv-secret-1
kubectl exec nginx-w-secrets-from-k8s-secret -- cat /mnt/secrets-store/kv-secret-2

## show secrets held in secrets-store
kubectl exec busybox-w-secrets-from-k8s-secret -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-w-secrets-from-k8s-secret -- cat /mnt/secrets-store/kv-secret-1
kubectl exec busybox-w-secrets-from-k8s-secret -- cat /mnt/secrets-store/kv-secret-2
```

## Clean-up

```bash
# ---
# Uninstall CSI Driver
# ---
# delete created SecretProvider
kubectl delete -f secret-provider-to-k8s-secrets.yaml
kubectl delete -f secret-provider-to-pod-volumes.yaml
kubectl get SecretProviderClass

# delete pods using the SecretProdivers
kubectl delete -f pod-def-nginx-w-secrets-from-pod-volume.yaml
kubectl delete -f pod-def-busybox-w-secrets-from-pod-volume.yaml
kubectl delete -f pod-def-nginx-w-secrets-from-k8s-secret.yaml
kubectl delete -f pod-def-busybox-w-secrets-from-k8s-secret.yaml
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
az group delete -n $kv_rg -y
az keyvault purge --name $kv_n --location $l --no-wait
```

## Additional Resources

- AKS
- [MS | Docs | Use the Secrets Store CSI Driver for Kubernetes in an Azure Kubernetes Service (AKS) cluster (preview)][4]
- CSI
- [CSI | Docs | Sync as Kubernetes Secret][2]
- [CSI | Docs | Secret Auto Rotation][8]
- [CSI | Docs | Best Practices][9]
- KV
- [MS | Docs | Set and retrieve a secret from Azure Key Vault using Azure CLI][3]
- RBAC
- [MS | Docs | Azure built-in roles][7]
- [MS | Docs | Assign Azure roles using Azure CLI][6]

[2]: https://secrets-store-csi-driver.sigs.k8s.io/topics/sync-as-kubernetes-secret.html
[3]: https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
[4]: https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-driver
[5]: ./../aks_cni.md#create-an-azure-kubernetes-service-aks-with-azure-container-networking-interface-cni
[6]: https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli
[7]: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
[8]: https://secrets-store-csi-driver.sigs.k8s.io/topics/secret-auto-rotation.html
[9]: https://secrets-store-csi-driver.sigs.k8s.io/topics/best-practices.html
