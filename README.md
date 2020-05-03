# Kubernetes Lab Commands Sheet

### Juju

| Command                           | Description                                                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------- |
| `juju status`                     | Reports the current status of the model, machines, applications and units                     |
| `watch -c juju status --color`    | Tracks the deployment process live                                                            |
| `juju deploy`                     | Deploys a new application or bundle                                                           |
| `juju add-unit`                   | Adds one or more units to a deployed application                                              |
| `juju add-credential`             | Adds or replaces credentials for a cloud, stored locally on this client                       |
| `juju list-credentials`           | Lists locally stored credentials for a cloud                                                  |
| `juju add-model`                  | Adds a hosted model                                                                           |
| `juju list-models`                | Lists models a user can access on a controller                                                |
| `juju run-action`                 | Queue an action for execution. E.g. `juju run-action kubernetes-worker/0 microbot replicas=5` |
| `juju upgrade-charm {CHARM_NAME}` | Upgrade an application's charm                                                                |
| `juju config {APPLICATION_NAME}`  | Gets, sets, or resets configuration for a deployed application                                |

### Kubernetes

| Command                                                      | Description                                                                  |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `kubectl create -f [FILE/S]`                                 | Creates resources from the given file, files, dir, url, [etc][2]             |
| `kubectl get pods \| pod \| po`                              | Lists all Pods. [`Viewing Finding Resourses`](#Viewing-Finding-Resourses)    |
| `kubectl get nodes`                                          | Lists all nodes, [`Viewing Finding Resourses`](#Viewing-Finding-Resourses)   |
| `kubectl get svc \| services`                                | Lists all services in the namespace                                          |
| `kubectl get deploy`                                         | Lists deployments                                                            |
| `kubectl get endpoints`                                      | Lists all endpoints                                                          |
| `kubectl get ingress`                                        | Lists all ingress                                                            |
| `kubectl get componentstatuses`                              | Displays the health status of the components                                 |
| `kubectl get namespaces`                                     | Lists namespaces                                                             |
| `kubectl get rs`                                             | Lists Replica Resources                                                      |
| `kubectl get sa`                                             | Lists Service Accounts                                                       |
| `kubectl get clusterroles`                                   | Lists default Cluster Roles                                                  |
| `kubectl get rol`                                            | Lists Roles                                                                  |
| `kubectl get pv`                                             | List persistent volumes                                                      |
| `kubectl get pvc`                                            | Lists persistent volume claims                                               |
| `kubectl describe pod {POD_NAME}`                            | Describes a specific pod                                                     |
| `kubectl describe node {NODE_NAME}`                          | Describes the status of a specific Node, CPU and memory (system information) |
| `kubectl describe rs {REPLICA_SET_NAME}`                     | Describes a specific ReplicaSet                                              |
| `kubectl describe sa {SERVICE_ACCOUNT_NAME}`                 | Describes a specific Service Account                                         |
| `kubectl describe secret {SECRET_NAME}`                      | Describes a secret/Token                                                     |
| `kubectl describe rolebinding {ROLE_BINDING_NAME}`           | Describes a specific role binding                                            |
| `kubectl describe pv {PERSISTENT_VOLUME_NAME}`               | Describes a specific persistent volume                                       |
| `kubectl describe pv {PERSISTENT_VOLUME_CLAIMS_NAME}`        | Describes a specific persistent volume claim                                 |
| `kubectl delete pod {POD_NAME}`                              | Deletes the specified pod                                                    |
| `kubectl delete namespaces {NAMESPACE_NAME}`                 | Deletes a specific namespace                                                 |
| `kubectl delete deploy {DEPLOY_NAME}`                        | Deletes a specific deployment                                                |
| `kubectl delete sa {SERVICE_ACCOUNT_NAME}`                   | Deletes a specific service account                                           |
| `kubectl delete rol {ROLE_NAME}`                             | Deletes a specific role                                                      |
| `kubectl delete rolebinding {ROLE_BINDING_NAME}`             | Deletes a specific role binding                                              |
| `kubectl delete pv {PV_NAME}`                                | Deletes a specific persistent volume                                         |
| `kubectl delete pvc {PVC_NAME}`                              | Deletes a specific persistent volume claim                                   |
| `kubectl expose deployment {DEPLOY_NAME} --type="ClusterIP"` | Exposes an external IP address                                               |
| `kubectl top node`                                           | Displays resource (CPU/Memory/Storage) usage of nodes                        |  |
| `kubectl proxy`                                              | Starts a proxy to the Kubernetes API server                                  |  |

### Helm

| Command                          | Description                                                                                              |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `helm init`                      | Install Tiller to your running Kubernetes cluster. It will also set up any necessary local configuration |
| `helm repo update`               | Updates index chart repositories                                                                         |
| `helm search {CHART_NAME}`       | Searches for a specific chart                                                                            |
| `helm install {CHART_REFERENCE}` | Installs a specific chart. E.g. `helm install stable/mariadb`                                            |
| `helm create {CHART_NAME}`       | Create a new chart with the given name                                                                   |
| `helm package {CHART_PATH}`      | Packages a chart directory into a chart archive                                                          |
| `helm delete {RELREASE_NAME}`    | Given a release name, delete the release from Kubernetes                                                 |

### Viewing Finding Resourses:

`kubectl get pods --all-namespaces` List all pods in all namespaces

`kubectl get pods -o wide` List all pods in the namespace, with more details
