# Use Azure Active Directory pod-managed identities in Azure Kubernetes Services

## Requirements

- AKS Cluster
  - You could follow these steps to create an AKS Cluster:
    - [AKS (CNI) Cluster][6]
    - [AKS (Kubenet) Cluster][7]
- You must have Owner RBAC on your subscription to create the identity and assign role binding to the cluster identity.

## Code

---

### Initialize params

```bash
# Set Up params if required
# ---
# Main Vars
# ---
app="confidential";                          echo $app
env="prod";                                  echo $env
l="eastus2";                                 echo $l
tags="env=$env app=$app";                    echo $tags
app_rg="rg-$app-$env";                       echo $app_rg

# ---
# KV
# ---
kv_n="kv-$app-$env";                         echo $kv_n

# ---
# AKS
# ---
aks_cluster_n="aks-$app-$env";                                          echo $aks_cluster_n
# KV
aks_kv_ns="kv-test";                                                    echo $aks_kv_ns
aks_kv_pod_identity="pod-identity-to-kv";                               echo $aks_kv_pod_identity
# VMSS
aks_vmss_ns="vmss-test";                                                echo $aks_vmss_ns
aks_vmss_pod_identity="pod-identity-to-aks-vmss";                       echo $aks_vmss_pod_identity

# ---
# Management Identities
# ---
id_to_kv_n="id-to-kv-$app-$env";                                        echo $id_to_kv_n
id_to_aks_vmss_n="id-to-aks-vmss-$app-$env";                            echo $id_to_aks_vmss_n

# ---
# Policy Mitigation for Kubenet
# ---
policy_n="AAD_POD_IDENTITY_MITIGATION_POLICY"; echo $policy_n
policy_display_n="Kubernetes cluster containers should only use allowed capabilities"; echo $policy_display_n
```

---

### Create an Azure Key Vault

```bash
# ---
# Create a KV
# ---
az keyvault create --name $kv_n --resource-group $app_rg --location $l --tags $tags
# add a secret to the KV
az keyvault secret set --vault-name $kv_n --name "ExamplePassword" --value "Password123!"
az keyvault secret set --vault-name $kv_n --name "MySecret" --value "someSecret"
# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "ExamplePassword" --query "value"
az keyvault secret show --vault-name $kv_n --name "MySecret" --query "value"
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
sudo kubectl get constrainttemplates

# Test AKS Policy by deploying a pod with NET_RAW Policy
# capability add NET_RAW
sudo kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_cap_net_raw-disallowed.yaml
# capability drop NET_RAW
sudo kubectl apply -f https://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_cap_net_raw-allowed.yaml
# no Capabilities specified
sudo kubectl apply -f hhttps://raw.githubusercontent.com/ArtiomLK/opa-aad-pod-identity-kubenet/main/pod_cap_net_raw-none.yaml

# Enable pod-identity on our cluster
# Update an existing AKS cluster with Kubenet network plugin
az aks update -g $app_rg -n $aks_cluster_n --enable-pod-identity --enable-pod-identity-with-kubenet
az aks show -g $app_rg -n $aks_cluster_n --query "podIdentityProfile"

# Test
az aks get-credentials -g $app_rg -n $aks_cluster_n
sudo kubectl api-versions
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
sudo kubectl api-versions
# We should find: aadpodidentity.k8s.io/v1
```

---

### Configure Pod Managed Identities

```bash
# ---
# AAD Pod Managed Identity to access AKS NodePool VMSS (Pod Managed Identity 1)
# ---

# Create an Azure User Managed Identity
az identity create -g $app_rg -n $id_to_aks_vmss_n --tags $tags

# Assign permissions to the Managed Identity to access AKS NodePool VMSS
IDENTITY_CLIENT_ID_TO_AKS_VMSS="$(az identity show -g $app_rg -n $id_to_kv_n --query clientId -otsv)"; echo $IDENTITY_CLIENT_ID_TO_AKS_VMSS
NODE_GROUP=$(az aks show -g $app_rg -n $aks_cluster_n --query nodeResourceGroup -otsv); echo $NODE_GROUP
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP --query "id" -otsv); echo $NODES_RESOURCE_ID

az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID_TO_AKS_VMSS" --scope $NODES_RESOURCE_ID

# Create a pod identity
# You must have Owner RBAC on your subscription to create the identity and assign role binding to the cluster identity.
IDENTITY_RESOURCE_ID_TO_AKS_VMSS="$(az identity show -g $app_rg -n $id_to_kv_n --query id -otsv)"; echo $IDENTITY_RESOURCE_ID_TO_AKS_VMSS

az aks pod-identity add \
--resource-group $app_rg \
--cluster-name $aks_cluster_n \
--namespace $aks_vmss_ns \
--name $aks_vmss_pod_identity \
--identity-resource-id ${IDENTITY_RESOURCE_ID_TO_AKS_VMSS}

# Check AAD Pod Managed Identity provisioningState and any linked pod-identity
az aks pod-identity list --cluster-name $aks_cluster_n --resource-group $app_rg --query "podIdentityProfile"


# ---
# AAD Pod Managed Identity to access Key Vault (Pod Managed Identity 2)
# ---

# Create an Azure User Managed Identity
az identity create -g $app_rg -n $id_to_kv_n --tags $tags

# Assign permissions to the Managed Identity to access KV secrets
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

```bash
# ---
# Install dependencies
# ---
# Register the EnablePodIdentityPreview
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
# check installation status
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnablePodIdentityPreview')].{Name:name,State:properties.state}"

# register the Secret Provider
az feature register --name AKS-AzureKeyVaultSecretsProvider --namespace Microsoft.ContainerService
# Check if registered
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"

# When ready, refresh the registration of the Microsoft.ContainerService ()AKS) resource provider by using the az provider register command:
az provider register -n Microsoft.ContainerService
# check installation status
az provider list -o table --query "[?contains(namespace, 'Microsoft.ContainerService')]"

# Enable AKS preview
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
# retrieve secrets from KV
az keyvault secret show --vault-name $kv_n --name "ExamplePassword" --query "value"

# ---
# Set up AKS
# ---
# Enable pod-identity on our cluster
# az aks update -g $app_rg -n $aks_cluster_n --enable-pod-identity



```

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
```

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

[1]: https://docs.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[2]: https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity
[3]: https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
[4]: https://docs.microsoft.com/en-us/azure/aks/policy-reference
[5]: https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes#install-azure-policy-add-on-for-aks
[6]: ./../aks_cni.md#create-an-azure-kubernetes-service-aks-with-azure-container-networking-interface-cni
[7]: ./../aks_private_kubenet.md#create-a-private-azure-kubernetes-service-aks-with-kubenet
[7]: https://docs.microsoft.com/en-us/azure/aks/use-azure-policy
