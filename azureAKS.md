# Creating an Azure Kubernetes Service (AKS) with the az CLI

1. ### Create a Log Analytics Monitor Workspace

   1. Create a resource group where the Log Analytics Monitor Workspace resources will be with any of the following commands:

      ```
      az group create \
      --name log_analytics_workspace_RG \
      --location eastus \
      --tags 'env=dev' 'project=k8s'
      ```

      or

      `az group create -n log_analytics_workspace_RG -l eastus --tags 'env=dev' 'project=k8s'`

   2. Create the Log Analytics Monitor Workspace with any of the following commands:

      `--workspace-name` Must be unique

      ```
      az monitor log-analytics workspace create \
      --resource-group log_analytics_workspace_RG \
      --workspace-name alkLogAnalyticsWorkspace \
      --location eastus \
      --tags 'env=dev' 'project=k8s'
      ```

      or

      `az monitor log-analytics workspace create -g log_analytics_workspace_RG -n alkLogAnalyticsWorkspace -l eastus --tags 'env=dev' 'project=k8s'`

2. ### Enable aks-preview

   1. Install aks-preview extension

      `az extension add --name aks-preview`

      <details><summary>OPTIONAL ADDITIONAL INFO</summary>
      <p>

      Check available extensions

      `az extension list-available --output table`

      [azure-cli-extensions-overview](https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview?view=azure-cli-latest)

      </p>
      </details>

3. ### Create the Azure kubernetes Service (AKS)

   1. Create a resource group where the k8s resources will be with any of the following commands:

      ```
      az group create \
      --name k8s_RG \
      --location eastus \
      --tags 'env=dev' 'project=k8s'
      ```

      or

      `az group create -n k8s_RG -l eastus --tags 'env=dev' 'project=k8s'`

   2. Create the AKS

      1. [OPTIONAL] check available k8s versions: `az aks get-versions --location eastus` to use in part c.

      2. Get the Workspace Resource id:
         `workSpaceResourceID=$(az monitor log-analytics workspace show --workspace-name alkLogAnalyticsWorkspace --resource-group log_analytics_workspace_RG --query id -o tsv)`

         `echo $workSpaceResourceID`

      3. Create the AKS with any of the following command

         ```
         az aks create \
         --kubernetes-version 1.19.0 \
         --resource-group k8s_RG \
         --node-resource-group k8s_node_RG \
         --name k8sCluster \
         --node-vm-size Standard_B2s \
         --vm-set-type VirtualMachineScaleSets \
         --node-count 3 \
         --enable-addons monitoring \
         --workspace-resource-id $workSpaceResourceID \
         --generate-ssh-keys \
         --enable-managed-identity \
         --tags 'env=dev' 'project=k8s'
         ```

         or

         `az aks create -k 1.19.0 -g k8s_RG --node-resource-group k8s_node_RG -n k8sCluster -s Standard_B2s --vm-set-type VirtualMachineScaleSets -c 3 -a monitoring --workspace-resource-id $workSpaceResourceID --generate-ssh-keys --enable-managed-identity --tags 'env=dev' 'project=k8s'`

         _If you don't have a network watcher enabled in the region that the virtual network you want to generate a topology for is in, network watchers are automatically created for you in all regions. The network watchers are created in a resource group named NetworkWatcherRG._
