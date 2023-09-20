# Kubernetes on Microsoft Azure

## Introduction

These are architecture design examples around Azure Kubernetes Services (AKS)

## Architectures

[The choice of which network plugin to use for your AKS cluster is usually a balance between flexibility and advanced configuration needs. The following considerations help outline when each network model may be the most appropriate.][6]

- Use kubenet when:
  - You have limited IP address space.
  - Most of the pod communication is within the cluster.
  - You don't need advanced AKS features such as virtual nodes or Azure Network Policy.
- Use Azure CNI when:
  - You have available IP address space.
  - Most of the pod communication is to resources outside of the cluster.
  - You don't want to manage user defined routes for pod connectivity.
  - You need AKS advanced features such as virtual nodes or Azure Network Policy.

- [Public AKS with Azure CNI][1]
- [Private AKS with kubenet][2]

## Quick Guides

- [Authorize AKS to Access ACR][3]
- [AKS Authentication to KV with (CSI) Container Storage Interface Secret Store Driver][4]
- [Azure Active Directory (AAD) Pod Managed Identities][5]

[1]: ./examples/aks_cni.md
[2]: ./examples/aks_private_kubenet.md
[3]: ./examples/snippets/aks_attach_acr.md
[4]: ./examples/aks-kv-csi-secret-store-driver/aks-kv-csi-secret-store-driver.md
[5]: ./examples/pod-managed-identity/pod-managed-identity.md
[6]: https://learn.microsoft.com/en-us/training/modules/design-implement-private-access-to-azure-services/7-integrate-your-app-service-azure-virtual-networks
