# Use Azure Active Directory pod-managed identities in Azure Kubernetes Services

## Requirements

- You must have Owner RBAC on your subscription to create the identity and assign role binding to the cluster identity.

## Useful Commands

| Command                                                              | Description                                                      |
| -------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `az login`                                                           | login to azure with your account                                 |
| `az account list --output table`                                     | display available subscription                                   |
| `az account set --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | use subscriptionID                                               |
| `az account show --output table`                                     | check the subscriptions currently in use                         |
| `az group list -o table`                                             | -                                                                |
| `az account list-locations -o table`                                 | -                                                                |
| `az aks get-versions --location eastus2 -o table`                    | -                                                                |
| `export MSYS_NO_PATHCONV=1`                                          | avoids the C:/Program Files/Git/ path being appended to commands |

## Step by step guide

### Prerequisites

```bash
# Connect to azure
az login

# Find your subscription ID
az account list --output table

# Connect to the connect to the subscription
az account set --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Confirm you are pointing to the correct subscription
az account show

# If you happen to be using gitbash avoid wrong path appended to commands by running
export MSYS_NO_PATHCONV=1
```

### Initialize params

```bash
# Set Up params if required
# ---
# Main Vars
# ---
app="confidential";                                                     echo $app
env="prod";                                                             echo $env
l="eastus2";                                                            echo $l
tags="env=$env app=$app";                                               echo $tags
app_rg="rg-$app-$env";                                                  echo $app_rg

# ---
# KV
# ---
kv_rg="rg-kv-$app-$env";                                                echo $kv_rg
kv_n="kv-$app-$env";                                                    echo $kv_n

# ---
# AKS
# ---
aks_cluster_n="aks-$app-$env";                                          echo $aks_cluster_n
aks_node_count="3";                                                     echo $aks_node_count
aks_v="1.23.8";                                                         echo $aks_v
aks_node_size="Standard_B2s";                                           echo $aks_node_size
# KV
aks_kv_ns="kv-demo";                                                    echo $aks_kv_ns
aks_kv_pod_identity="pod-identity-to-kv";                               echo $aks_kv_pod_identity
# VMSS
aks_vmss_ns="vmss-demo";                                                echo $aks_vmss_ns
aks_vmss_pod_identity="pod-identity-to-aks-vmss";                       echo $aks_vmss_pod_identity

# ---
# Management Identities
# ---
id_to_kv_n="id-to-kv-$app-$env";                                        echo $id_to_kv_n
id_to_aks_vmss_n="id-to-aks-vmss-$app-$env";                            echo $id_to_aks_vmss_n

# ---
# Policy Mitigation for Kubenet
# ---
policy_n="AAD_POD_IDENTITY_MITIGATION_POLICY";                          echo $policy_n
policy_display_n="Kubernetes cluster containers should only use allowed capabilities"; echo $policy_display_n
```

---

### Create Main Resource Group

```bash
# Create a resource group where our app resources will be created, e.g. AKS, ACR, vNets...
az group create \
--name $app_rg \
--location $l \
--tags $tags
```

---

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
# Create a resource group where our app resources will be created, e.g. AKS, ACR, vNets...
az group create --name $kv_rg --location $l --tags $tags

az keyvault create --name $kv_n --resource-group $kv_rg --location $l --tags $tags
# add a secrets to the KV
az keyvault secret set --vault-name $kv_n --name "secret1" --value "secret1val"
az keyvault secret set --vault-name $kv_n --name "secret2" --value "secret2val"
az keyvault secret set --vault-name $kv_n --name "ExamplePassword" --value "Password123!"
az keyvault secret set --vault-name $kv_n --name "MySecret" --value "someSecret"

# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "ExamplePassword" --query "value"
az keyvault secret show --vault-name $kv_n --name "MySecret" --query "value"
az keyvault secret show --vault-name $kv_n --name "secret1" --query "value"
az keyvault secret show --vault-name $kv_n --name "secret2" --query "value"
```

---

### Register and install required providers

```bash
# POD Identity
# Register the EnablePodIdentityPreview
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
# check installation status
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnablePodIdentityPreview')].{Name:name,State:properties.state}"

# Enable AKS preview
az extension add --name aks-preview
# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview
# Review AKS preview installation (Installed true)
az extension list-available --output table --query "[?contains(name, 'aks-preview')]"
```

---

### Enable AAD Pod Management Identity - Kubenet AKS Configuration

```bash
# ---
# Set up Kubenet AKS
# ---

# Running aad-pod-identity in a cluster with Kubenet is not a recommended configuration because of the security implication.
# Please follow the mitigation steps and configure policies before enabling aad-pod-identity in a cluster with Kubenet to limit the CAP_NET_RAW attack.

# Mitigation
# Enable AKS Built in Policy
az provider register --namespace Microsoft.PolicyInsights
az provider list -o table --query "[?contains(namespace, 'Microsoft.PolicyInsights')]"

az aks enable-addons --addons azure-policy -g $app_rg -n $aks_cluster_n
az aks show --query addonProfiles.azurepolicy -g $app_rg -n $aks_cluster_n

# Apply aks built in policy:
# Kubernetes cluster containers should only use allowed capabilities
RG_ID="$(az group show --name $app_rg --query "id" -otsv)"; echo $RG_ID

az policy assignment create \
--name $policy_n \
--display-name "${policy_display_n}" \
--scope $RG_ID \
--policy "c26596ff-4d70-4e6a-9a30-c2506bd2f80c" \
--params "{ \"effect\": { \"value\":  \"deny\"  }, \"requiredDropCapabilities\": { \"value\": [ \"NET_RAW\" ] } }"

# show policies at the rg scope
az policy assignment list -g $app_rg

# Note Policy assignments can take up to 20 minutes to sync into each cluster.
# We could validate aks policies from inside the cluster but you must be authenticated against the the cluster
az aks get-credentials -g $app_rg -n $aks_cluster_n
kubectl get constrainttemplates

# Test AKS Policy by deploying a pod with NET_RAW Policy
# capability allow NET_RAW
kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_allow_net_raw.yaml.yaml
kubectl delete -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_allow_net_raw.yaml.yaml
# capability drop NET_RAW
kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_drop_net_raw.yaml
kubectl delete -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_drop_net_raw.yaml
# no Capabilities specified
kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_no_capabilities_specified.yaml
kubectl delete -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_no_capabilities_specified.yaml

# Enable pod-identity on our cluster
# Update an existing AKS cluster with Kubenet network plugin
az aks update -g $app_rg -n $aks_cluster_n --enable-pod-identity --enable-pod-identity-with-kubenet
az aks show -g $app_rg -n $aks_cluster_n --query "podIdentityProfile"

# Test
az aks get-credentials -g $app_rg -n $aks_cluster_n
kubectl api-versions
# We should find: aadpodidentity.k8s.io/v1
```

---

### Enable AAD Pod Management Identity - CNI AKS Configuration

```bash
# ---
# Set up CNI AKS
# ---
az aks update -g $app_rg -n $aks_cluster_n --enable-pod-identity

# Test
az aks get-credentials -g $app_rg -n $aks_cluster_n
kubectl api-versions
# We should find: aadpodidentity.k8s.io/v1
```

---

### Configure Pod Managed Identities to access Key Vault

```bash
# ---
# AAD Pod Managed Identity to access Key Vault (Pod Managed Identity 2)
# ---

# Create an Azure User Managed Identity
az identity create -g $app_rg -n $id_to_kv_n --tags $tags

# Assign permissions to the Managed Identity to access KV secrets
# Application ID
IDENTITY_CLIENT_ID_TO_KV="$(az identity show -g $app_rg -n $id_to_kv_n --query clientId -otsv)"; echo $IDENTITY_CLIENT_ID_TO_KV
az keyvault set-policy -n $kv_n --secret-permissions get --spn $IDENTITY_CLIENT_ID_TO_KV

# Create a pod identity
# You must have Owner RBAC on your subscription to create the identity and assign role binding to the cluster identity.
IDENTITY_RESOURCE_ID_TO_KV="$(az identity show -g $app_rg -n $id_to_kv_n --query id -otsv)"; echo $IDENTITY_RESOURCE_ID_TO_KV

az aks pod-identity add \
--resource-group $app_rg \
--cluster-name $aks_cluster_n \
--namespace $aks_kv_ns  \
--name $aks_kv_pod_identity \
--identity-resource-id ${IDENTITY_RESOURCE_ID_TO_KV}

# Check AAD Pod Managed Identity provisioningState and any linked pod-identity
az aks pod-identity list --cluster-name $aks_cluster_n --resource-group $app_rg --query "podIdentityProfile"
```

---

### Configure Pod Managed Identities to access Key Vault with (CSI) Container Storage Interface Secret Store Driver

```bash
# ---
# Enable Managed Identity on AKS
# ---
# EXPECTED RESULT {"clientId": "msi"}
az aks show -g $app_rg -n $aks_cluster_n --query "servicePrincipalProfile"
# ---
# Otherwise enable Managed Identity on AKS IF RESULT ISN'T {"clientId": "msi"}
az aks update -g $app_rg -n $aks_cluster_n --enable-managed-identity # RUN ONLY IF RESULT ISN'T {"clientId": "msi"}
# To complete the update to managed identity upgrade the nodepools. e.g.
az aks nodepool upgrade --node-image-only -g $app_rg --cluster-name $aks_cluster_n -n nodepool1

# rerun ACR to AKS attachment
# https://github.com/ArtiomLK/kubernetes/blob/main/azure/examples/snippets/aks_attach_acr.md

# ---
# Setup the SecretProvider
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

# ---
# Configure the SecretProvider Files
# ---
# NOTE: The SecretProviderClass has to be in the same namespace as the pod referencing it.
# YOU MUST REPLACE from the pod-managed-secret-provider.yaml file the following parameters
echo $aks_kv_ns # metadata.namespace
echo $kv_n # spec.parameters.keyvaultName
az account show --query tenantId # spec.parameters.tenantId

# ---
# Deploy the SecretProvider Files
# ---
kubectl apply -f pod-managed-secret-provider.yaml
# Verify if secretProviderClass created
kubectl get SecretProviderClass -n $aks_kv_ns
# kubectl describe SecretProviderClass azure-kvname

# ---
# Configure a sample App to access our Key Vault
# ---
# Modify the pod-managed-identity-to-kv.yaml file. Replace the following:
# metadata.namespace: $aks_vmss_ns
echo $aks_kv_ns
# metadata.labels.aadpodidbinding: $aks_vmss_ns
echo $aks_kv_pod_identity

kubectl apply -f pod-managed-identity-to-kv.yaml
kubectl get pods -n $aks_kv_ns

# ---
# Test access with authorization to KeyVault Secrets
# ---

## show secrets held in secrets-store
kubectl exec busybox-secrets-store-inline -n  $aks_kv_ns -- ls /mnt/secrets-store/
## print a test secret 'ExampleSecret' held in secrets-store
kubectl exec busybox-secrets-store-inline -n $aks_kv_ns -it -- sh

kubectl exec busybox-secrets-store-inline -n $aks_kv_ns -- cat /mnt/secrets-store/ExamplePassword
kubectl exec busybox-secrets-store-inline -n $aks_kv_ns -- cat /mnt/secrets-store/MySecret
kubectl exec busybox-secrets-store-inline -n $aks_kv_ns -- cat /mnt/secrets-store/secret1
kubectl exec busybox-secrets-store-inline -n $aks_kv_ns -- cat /mnt/secrets-store/secret2

# Modifying kv secret vals
kubectl delete -f pod-managed-identity-to-kv.yaml
az keyvault secret set --vault-name $kv_n --name "secret1" --value "NEW secret1val"
az keyvault secret set --vault-name $kv_n --name "secret2" --value "NEW secret2val"
az keyvault secret set --vault-name $kv_n --name "ExamplePassword" --value "NEW Password123!"
az keyvault secret set --vault-name $kv_n --name "MySecret" --value "NEW someSecret"
# Deploy pod again
kubectl apply -f pod-managed-identity-to-kv.yaml
kubectl get pods -n $aks_kv_ns

# Test wrong Namespace
kubectl apply -f pod-managed-identity-to-kv-wrong-ns.yaml
kubectl get pods

kubectl delete -f pod-managed-identity-to-kv.yaml
kubectl delete -f pod-managed-identity-to-kv-wrong-ns.yaml
```

### Configure Pod Managed Identities to access AKS NodePool VMSS

```bash
# ---
# AAD Pod Managed Identity to access AKS NodePool VMSS (Pod Managed Identity 1)
# ---

# Create an Azure User Managed Identity
az identity create -g $app_rg -n $id_to_aks_vmss_n --tags $tags

# Assign permissions to the Managed Identity to access AKS NodePool VMSS
IDENTITY_CLIENT_ID_TO_AKS_VMSS="$(az identity show -g $app_rg -n $id_to_aks_vmss_n --query clientId -otsv)"; echo $IDENTITY_CLIENT_ID_TO_AKS_VMSS
NODE_GROUP=$(az aks show -g $app_rg -n $aks_cluster_n --query nodeResourceGroup -otsv); echo $NODE_GROUP
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP --query "id" -otsv); echo $NODES_RESOURCE_ID

az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID_TO_AKS_VMSS" --scope $NODES_RESOURCE_ID

# Assign permissions to the Managed Identity to access Main RG VMs
RG_ID=$(az group show -n $app_rg --query "id" -otsv); echo $RG_ID
az role assignment create --role "Virtual Machine User Login" --assignee "$IDENTITY_CLIENT_ID_TO_AKS_VMSS" --scope $RG_ID

# Create a pod identity
# You must have Owner RBAC on your subscription to create the identity and assign role binding to the cluster identity.
IDENTITY_RESOURCE_ID_TO_AKS_VMSS="$(az identity show -g $app_rg -n $id_to_aks_vmss_n --query id -otsv)"; echo $IDENTITY_RESOURCE_ID_TO_AKS_VMSS

az aks pod-identity add \
--resource-group $app_rg \
--cluster-name $aks_cluster_n \
--namespace $aks_vmss_ns \
--name $aks_vmss_pod_identity \
--identity-resource-id ${IDENTITY_RESOURCE_ID_TO_AKS_VMSS}

# Check AAD Pod Managed Identity provisioningState and any linked pod-identity
az aks pod-identity list --cluster-name $aks_cluster_n --resource-group $app_rg --query "podIdentityProfile"

# ---
# Run a sample App to access AKS NodePool VMSS
# ---

# Modify the pod-managed-identity-to-aks-vmss.yaml file. Replace the following:
# metadata.namespace: $aks_vmss_ns
echo $aks_vmss_ns
# metadata.labels.aadpodidbinding: $aks_vmss_ns
echo $aks_vmss_pod_identity
#  spec.containers[0].args subscriptionid
az account show --query "id"
#  spec.containers[0].args clientid
echo $IDENTITY_CLIENT_ID_TO_AKS_VMSS
# spec.containers[0].args resourcegroup
echo $app_rg # this is the RESOURCE_GROUP where the Managed Identity was created

# Create the pod
kubectl apply -f pod-managed-identity-to-aks-vmss.yaml

# verify the app successfully prints the AKS nodePool vmss logs
kubectl logs pod-managed-id-to-aks-vmss --follow --namespace  $aks_vmss_ns

# Create the pod in the wrong Namespace
kubectl apply -f pod-managed-identity-to-aks-vmss-wrong-ns.yaml

# verify the app successfully prints the AKS nodePool vmss logs
kubectl get po
kubectl logs pod-managed-id-to-aks-vmss-wrong-ns --follow
```

---

## Clean-up

```bash
# ---
# pod identity preview
# ---
# If not using pod-identity-preview
az feature unregister --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
# Check that pod identity was uninstalled (State NotRegistered)
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnablePodIdentityPreview')].{Name:name,State:properties.state}"

# ---
# Secret Provider
# ---
az feature unregister --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"

# ---
# aks-preview
# ---
# If you're not planning to keep using aks preview features, then uninstall aks-preview
az extension remove -n aks-preview
# Check AKS preview installation (Installed false)
az extension list-available --output table --query "[?contains(name, 'aks-preview')]"

# ---
# Policy Mitigation if using AKS kubenet network plugin
# ---
az policy assignment list -g $app_rg #find and copy the Policy name if required
az policy assignment delete -n $policy_n -g $app_rg # paste your policy name
# Remove the azure policy add-on from AKS * If not using the feature at all
az aks disable-addons --addons azure-policy -g $app_rg -n $aks_cluster_n

# ---
# Delete Pod Identities from the cluster
# ---
# AKS VMSS POD-IDENTITY
az aks pod-identity delete \
--resource-group $app_rg \
--cluster-name $aks_cluster_n \
--namespace $aks_vmss_ns \
--name $aks_vmss_pod_identity
# AKS KV POD-IDENTITY
az aks pod-identity delete \
--resource-group $app_rg \
--cluster-name $aks_cluster_n \
--namespace $aks_vmss_ns \
--name $aks_vmss_pod_identity

# Check AAD Pod Managed Identity provisioningState and any linked pod-identity
az aks pod-identity list --cluster-name $aks_cluster_n --resource-group $app_rg --query "podIdentityProfile"

# ---
# Delete the created User Identities
# ---
# Identity to access aks nodepool vmss
az identity delete -g $app_rg -n $id_to_aks_vmss_n
# Identity to access Azure key Vault
az identity delete -g $app_rg -n $id_to_kv_n

# ---
# Delete the resource group if required
# ---
az group delete -n $app_rg
```

## Notes

> Managed identities are essentially a wrapper around service principals, and make their management simpler. Credential rotation for MI happens automatically every 46 days according to Azure Active Directory default. AKS uses both system-assigned and user-assigned managed identity types. These identities are currently immutable. To learn more, read about managed identities for Azure resources. [link][9]

</br>

> Deleting a user-assigned managed identity won't remove the reference from any resource it was assigned to. Remove those from a VM or virtual machine scale set by using the az vm/vmss identity remove command. [link][10]

---

## Additional Resources

- Pod ID
- [MS | Docs | Best practices for pod security in Azure Kubernetes Service (AKS)][1]
- [MS | Docs | Use Azure Active Directory pod-managed identities in Azure Kubernetes Service][2]
- KV
- [MS | Docs | Set and retrieve a secret from Azure Key Vault using Azure CLI][3]
- AKS
- [MS | Docs | Azure Policy built-in definitions for Azure Kubernetes Service][4]
- [MS | Docs | Install Azure Policy Add-on for AKS][5]
- [MS | Docs | Secure your cluster with Azure Policy][8]
- [MS | Docs | Use managed identities in Azure Kubernetes Service][9]

[1]: https://docs.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[2]: https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity
[3]: https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
[4]: https://docs.microsoft.com/en-us/azure/aks/policy-reference
[5]: https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes#install-azure-policy-add-on-for-aks
[6]: ./../aks_cni.md#create-an-azure-kubernetes-service-aks-with-azure-container-networking-interface-cni
[7]: ./../aks_private_kubenet.md#create-a-private-azure-kubernetes-service-aks-with-kubenet
[7]: https://docs.microsoft.com/en-us/azure/aks/use-azure-policy
[8]: .././snippets/aks_attach_acr.md
[9]: https://docs.microsoft.com/en-us/azure/aks/use-managed-identity
[10]: https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azcli#delete-a-user-assigned-managed-identity-1
