# Kubernetes Lab Commands Sheet 

###  Juju

| Command                        | Description                                                                                   |
| ------------------------------ | --------------------------------------------------------------------------------------------- |
| `juju status`                  | Reports the current status of the model, machines, applications and units                     |
| `watch -c juju status --color` | Track the deployment process live                                                             |
| `juju deploy`                  | Deploy a new application or bundle                                                            |
| `juju add-unit `               | Adds one or more units to a deployed application.                                             |
| `juju add-credential`          | Adds or replaces credentials for a cloud, stored locally on this client                       |
| `juju list-credentials`        | Lists locally stored credentials for a cloud                                                  |
| `juju add-model`               | Adds a hosted model                                                                           |
| `juju list-models`             | Lists models a user can access on a controller                                                |
| `juju run-action`              | Queue an action for execution. E.g. `juju run-action kubernetes-worker/0 microbot replicas=5` |


### Kubernetes 

| Command                                                      | Description                                                                  |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `kubectl create -f [FILE/S]`                                 | creates resources from the given file, files, dir, url, [etc][2]             |
| `kubectl get pods`                                           | Lists all Pods. [`Viewing Finding Resourses`](#Viewing-Finding-Resourses)    |
| `kubectl get nodes`                                          | List all nodes, [`Viewing Finding Resourses`](#Viewing-Finding-Resourses)    |
| `kubectl get svc`                                            | List all services in the namespace                                           |
| `kubectl get deploy`                                         | List deployments                                                             |
| `kubectl get endpoints`                                      | List all endpoints                                                           |
| `kubectl get ingress`                                        | List all ingress                                                             |
| `kubectl get componentstatuses`                              | Displays the health status of the components                                 |
| `kubectl get namespaces`                                     | List namespaces                                                              |
| `kubectl get rs`                                             | List Replica Resources                                                       |
| `kubectl get sa`                                             | List Service Accounts                                                        |
| `kubectl get clusterroles`                                   | List default Cluster Roles                                                   |
| `kubectl get rol`                                            | List Roles                                                                   |
| `kubectl get pv`                                             | List persistent volumes                                                      |
| `kubectl get pvc`                                            | List persistent volume claims                                                |
| `kubectl describe pod {POD_NAME}`                            | Describes a specific pod                                                     |
| `kubectl describe node {NODE_NAME}`                          | Describes the status of a specific Node, CPU and memory (system information) |
| `kubectl describe rs {REPLICA_SET_NAME}`                     | Describe a specific ReplicaSet                                               |
| `kubectl describe sa {SERVICE_ACCOUNT_NAME}`                 | Describe a specific Service Account                                          |
| `kubectl describe secret {SECRET_NAME}`                      | Describe a secret/Token                                                      |
| `kubectl  describe rolebinding {ROLE_BINDING_NAME}`          | Describe a specific role binding                                             |
| `kubectl  describe pv {PERSISTENT_VOLUME_NAME}`              | Describe a specific persistent volume                                      |
| `kubectl  describe pv {PERSISTENT_VOLUME_CLAIMS_NAME}`       | Describe a specific persistent volume claim                                  |
| `kubectl delete pod {POD_NAME}`                              | deletes the specified pod                                                    |
| `kubectl delete namespaces {NAMESPACE_NAME}`                 | delete a specific namespace                                                  |
| `kubectl delete deploy {DEPLOY_NAME}`                        | deletes a specific deployment                                                |
| `kubectl delete sa {SERVICE_ACCOUNT_NAME}`                   | deletes a specific service account                                           |
| `kubectl delete rol {ROLE_NAME}`                             | deletes a specific role                                                      |
| `kubectl delete rolebinding  {ROLE_BINDING_NAME}`            | deletes a specific role binding                                              |
| `kubectl delete pv  {PV_NAME}`                               | deletes a specific persistent volume                                         |
| `kubectl delete pvc  {PVC_NAME}`                             | deletes a specific persistent volume claim                                   |
| `kubectl expose deployment {DEPLOY_NAME} --type="ClusterIP"` | exposes an external IP address                                               |
| `kubectl top node `                                          | Display Resource (CPU/Memory/Storage) usage of nodes                         |

### Viewing Finding Resourses:
`kubectl get pods --all-namespaces` List all pods in all namespaces

`kubectl get pods -o wide` List all pods in the namespace, with more details
