# kubectl Cheat Sheet

- [`create`](#Create-Command)
- [`edit`](#Edit-Command)
- [`get`](#Get-Command)
- [`describe`](#Describe-Command)
- [`delete`](#Delete-Command)
- [`config`](#Config-Command)

## Create Command

| Command                                                                                                   | Description                                                      |
| --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `kubectl create -f {FILE/S}`                                                                              | Creates resources from the given file, files, dir or url         |
| `kubectl create namespace {NAMESPACE_NAME}`                                                               | Creates a new namespace                                          |
| `kubectl apply -f {FILE/S}`                                                                               | Apply changes or create resources based on the provided file     |
| `kubectl run {POD_NAME} --image={IMAGE}`                                                                  | Creates and starts a pod from the given image                    |
| `kubectl run {POD_NAME} --image={IMAGE} --generator=run-pod/v1 --dry-run=true -o yaml > {FILE_NAME.yaml}` | Tests the pod definition file and output it to a local yaml file |

## Edit Command

| Command                      | Description        |
| ---------------------------- | ------------------ |
| `kubectl edit po {POD_NAME}` | Edit the given Pod |

## Get Command

| Command                                     | Description                                     |
| ------------------------------------------- | ----------------------------------------------- |
| `kubectl get po \| pods`                    | Lists all pods. [`Common Flags`](#Common-Flags) |
| `kubectl get no \| nodes`                   | Lists all nodes                                 |
| `kubectl get svc \| services`               | Lists all services in the namespace             |
| `kubectl get deploy \| deployments`         | Lists deployments                               |
| `kubectl get ep \| endpoints`               | Lists all endpoints                             |
| `kubectl get ing \| ingress`                | Lists all ingress                               |
| `kubectl get cs \| componentstatuses`       | Displays the health status of the components    |
| `kubectl get ns \| namespaces`              | Lists namespaces                                |
| `kubectl get rs \| replicasets`             | Lists Replica Resources                         |
| `kubectl get sa \| serviceaccounts`         | Lists Service Accounts                          |
| `kubectl get clusterroles`                  | Lists default Cluster Roles                     |
| `kubectl get roles`                         | Lists Roles                                     |
| `kubectl get pv \| persistentvolumes`       | List persistent volumes                         |
| `kubectl get pvc \| persistentvolumeclaims` | Lists persistent volume claims                  |
| `kubectl get secret`                        | Lists secrets/Tokens                            |
| `kubectl get rolebinding`                   | Lists rolebinding                               |
| `kubectl get cm \| configmaps`              | Lists ConfigMaps                                |
| `kubectl get netpol \| networkpolicies`     | Lists Network Policies                          |

## Describe Command

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

## Delete Command

| Command                                          | Description                                              |
| ------------------------------------------------ | -------------------------------------------------------- |
| `kubectl delete -f {FILE/S}`                     | Deletes resources from the given file, files, dir or url |
| `kubectl delete po {POD_NAME}`                   | Deletes the specified pod                                |
| `kubectl delete ns {NAMESPACE_NAME}`             | Deletes a specific namespace                             |
| `kubectl delete deploy {DEPLOY_NAME}`            | Deletes a specific deployment                            |
| `kubectl delete sa {SERVICE_ACCOUNT_NAME}`       | Deletes a specific service account                       |
| `kubectl delete role {ROLE_NAME}`                | Deletes a specific role                                  |
| `kubectl delete rolebinding {ROLE_BINDING_NAME}` | Deletes a specific role binding                          |
| `kubectl delete pv {PV_NAME}`                    | Deletes a specific persistent volume                     |
| `kubectl delete pvc {PVC_NAME}`                  | Deletes a specific persistent volume claim               |

## Config Command

| Command                                                             | Description                       |
| ------------------------------------------------------------------- | --------------------------------- |
| `kubectl config get-contexts`                                       | display list of clusters          |
| `kubectl config use-context {CLUSTER_NAME}`                         | changes the current cluster       |
| `kubectl config view \| grep namespace`                             | displays current namespace in use |
| `kubectl config set-context --current --namespace={NAMESPACE_NAME}` | changes the current namespace     |
| `kubectl config delete-context {CONTEXT_NAME}`                      | deletes the provided context      |

## Other Commands

| Command                                                      | Description                                          |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| `kubectl expose deployment {DEPLOY_NAME} --type="ClusterIP"` | Exposes an external IP address                       |
| `kubectl proxy --port=8080`                                  | Starts a proxy to the Kubernetes API server          |
| `kubectl port-forward {POD_NAME} 8080:80`                    | Forwards traffic from outside the cluster to the pod |
| `{SVC_NAME.NS.svc.cluster.local}`                            | Access a svc from a different namespace              |

### Common Flags:

| Flag               | Examples                                               | Description                                       |
| ------------------ | ------------------------------------------------------ | ------------------------------------------------- |
| `--all-namespaces` | `kubectl get po --all-namespaces`                      | List all pods in all namespaces                   |
| `-o wide`          | `kubectl get pods -o wide`                             | List all pods in the namespace, with more details |
| `-o yaml`          | `kubectl get po {POD_NAME} -o yaml > {FILE_NAME.yaml}` | Extract the definition into a yaml file           |

### Create Definition Files

- Pods
  - `kubectl run nginx --image nginx --dry-run=client -o yaml > pod-nginx.yaml`
  - `kubectl run nginx-open-port --image nginx --port 80 --dry-run=client -o yaml > pod-nginx-open-port.yaml`
  - `kubectl run nginx-alpine --image nginx:alpine --dry-run=client -o yaml > pod-nginx-alpine.yaml`
- Deployments
  - `kubectl create deploy nginx --image nginx --dry-run=client -o yaml > deploy-nginx.yaml`
  - `kubectl create deploy nginx-w-replicas --image nginx --replicas 3 --dry-run=client -o yaml > deploy-nginx-w-replicas.yaml`
  - `kubectl create deploy nginx-alpine-w-replicas --image nginx:alpine --replicas 3 --dry-run=client -o yaml > deploy-nginx-alpine-w-replicas.yaml`
- Services
  - NodePort
    - `kubectl expose pod nginx --port=80 --name nginx-service-to-pod --type=NodePort --dry-run=client -o yaml > svc-nginx-to-pod.yaml`
    - `kubectl expose pod nginx-open-port --port=80 --name nginx-service-to-pod-w-open-port --type=NodePort --dry-run=client -o yaml > svc-nginx-to-pod-w-open-container-port.yaml`
    - `kubectl expose deploy nginx-w-replicas --port=80 --name nginx-service-to-deploy --type=NodePort --dry-run=client -o yaml > svc-nginx-to-deploy.yaml`
  - ClusterIP
    - `kubectl expose pod nginx --port=80 --name nginx-service-to-pod --type=ClusterIP --dry-run=client -o yaml > svc-nginx-to-pod.yaml`
    - `kubectl expose deploy nginx-w-replicas --port=80 --name nginx-service-to-deploy --type=ClusterIP --dry-run=client -o yaml > svc-nginx-to-deploy.yaml`

### Alias

```
alias k="kubectl"
alias ka="k apply"
alias kc="k create"
alias kd="k describe"
alias kdel="k delete"
alias ke="k explain"
alias ke2="k expose"
alias kg="k get"
alias kl="k label"
alias klog="k logs"
alias kr="k run"
alias krol="k rollout"
alias kt="k taint"
alias ktop="k top"
```
