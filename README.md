# kubectl Cheat Sheet

- [`create`](#Create-Commands)
- [`get`](#Get-Commands)
- [`describe`](#Describe-Commands)
- [`delete`](#Delete-Commands)
- [`config`](#Config-Commands)

## Create Commands

| Command                      | Description                                                 |
| ---------------------------- | ----------------------------------------------------------- |
| `kubectl create -f {FILE/S}` | Creates resources from the given file, files, dir, url, etc |

## Get Commands

| Command                                     | Description                                                                |
| ------------------------------------------- | -------------------------------------------------------------------------- |
| `kubectl get po \| pods`                    | Lists all Pods. [`Viewing Finding Resourses`](#Viewing-Finding-Resourses)  |
| `kubectl get no \| nodes`                   | Lists all nodes, [`Viewing Finding Resourses`](#Viewing-Finding-Resourses) |
| `kubectl get svc \| services`               | Lists all services in the namespace                                        |
| `kubectl get deploy \| deployments`         | Lists deployments                                                          |
| `kubectl get ep \| endpoints`               | Lists all endpoints                                                        |
| `kubectl get ing \| ingress`                | Lists all ingress                                                          |
| `kubectl get cs \| componentstatuses`       | Displays the health status of the components                               |
| `kubectl get ns \| namespaces`              | Lists namespaces                                                           |
| `kubectl get rs \| replicasets`             | Lists Replica Resources                                                    |
| `kubectl get sa \| serviceaccounts`         | Lists Service Accounts                                                     |
| `kubectl get clusterroles`                  | Lists default Cluster Roles                                                |
| `kubectl get roles`                         | Lists Roles                                                                |
| `kubectl get pv \| persistentvolumes`       | List persistent volumes                                                    |
| `kubectl get pvc \| persistentvolumeclaims` | Lists persistent volume claims                                             |
| `kubectl get secret`                        | Lists secrets/Tokens                                                       |
| `kubectl get rolebinding`                   | Lists rolebinding                                                          |

## Describe Commands

| Command                                                | Description                                                                  |
| ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `kubectl describe po {POD_NAME}`                       | Describes a specific pod                                                     |
| `kubectl describe no {NODE_NAME}`                      | Describes the status of a specific Node, CPU and memory (system information) |
| `kubectl describe rs {REPLICA_SET_NAME}`               | Describes a specific ReplicaSet                                              |
| `kubectl describe sa {SERVICE_ACCOUNT_NAME}`           | Describes a specific Service Account                                         |
| `kubectl describe secret {SECRET_NAME}`                | Describes a secret/Token                                                     |
| `kubectl describe rolebinding {ROLE_BINDING_NAME}`     | Describes a specific role binding                                            |
| `kubectl describe pv {PERSISTENT_VOLUME_NAME}`         | Describes a specific persistent volume                                       |
| `kubectl describe pvc {PERSISTENT_VOLUME_CLAIMS_NAME}` | Describes a specific persistent volume claim                                 |

## Delete Commands

| Command                                          | Description                                |
| ------------------------------------------------ | ------------------------------------------ |
| `kubectl delete po {POD_NAME}`                   | Deletes the specified pod                  |
| `kubectl delete ns {NAMESPACE_NAME}`             | Deletes a specific namespace               |
| `kubectl delete deploy {DEPLOY_NAME}`            | Deletes a specific deployment              |
| `kubectl delete sa {SERVICE_ACCOUNT_NAME}`       | Deletes a specific service account         |
| `kubectl delete role {ROLE_NAME}`                | Deletes a specific role                    |
| `kubectl delete rolebinding {ROLE_BINDING_NAME}` | Deletes a specific role binding            |
| `kubectl delete pv {PV_NAME}`                    | Deletes a specific persistent volume       |
| `kubectl delete pvc {PVC_NAME}`                  | Deletes a specific persistent volume claim |

## Config Commands

| Command                               | Description                                |
| ------------------------------------- | ------------------------------------------ |
| `kubectl get-contexts`                | display list of contexts                   |
| `kubectl use-context my-cluster-name` | set the default context to my-cluster-name |

## Other Commands

| Command                                                      | Description                                           |
| ------------------------------------------------------------ | ----------------------------------------------------- |
| `kubectl expose deployment {DEPLOY_NAME} --type="ClusterIP"` | Exposes an external IP address                        |
| `kubectl top node`                                           | Displays resource (CPU/Memory/Storage) usage of nodes |  |
| `kubectl proxy`                                              | Starts a proxy to the Kubernetes API server           |  |

### Viewing Finding Resourses:

`kubectl get pods --all-namespaces` List all pods in all namespaces

`kubectl get pods -o wide` List all pods in the namespace, with more details
