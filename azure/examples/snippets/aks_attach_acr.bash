# Integrate an ACR with an existing AKS (this creates a system managed identity)
# It authorizes the ACR in your subscription and configures the appropriate ACRPull role for the managed identity.
# get ACR ID
ACR_ID=$(az acr show --name ${acr_n} --query 'id' --output tsv); echo $ACR_ID
# Attach ACR to AKS
az aks update \
-n $aks_cluster_n \
-g $app_rg \
--attach-acr $ACR_ID
