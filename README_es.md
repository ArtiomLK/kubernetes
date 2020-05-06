# Commandos de kubectl

- [`create`](#Comando-create)
- [`get`](#Comando-get)
- [`describe`](#Comando-describe)
- [`delete`](#Comando-delete)
- [`config`](#Comando-config)

## Comando create

| Comando                                     | Descripción                                                  |
| ------------------------------------------- | ------------------------------------------------------------ |
| `kubectl create -f {FILE/S}`                | Crea los recursos detallados en el archivo, directorio o url |
| `kubectl create namespace {NAMESPACE_NAME}` | Crea un namespace                                            |
| `kubectl run {POD_NAME} --image={IMAGE}`    | Crea y inicializa un pod de la imagen provista               |

## Comando get

| Comando                                     | Descripción                                        |
| ------------------------------------------- | -------------------------------------------------- |
| `kubectl get po \| pods`                    | Muestra todos los pods. [`Flags`](#Algunos-Flags)  |
| `kubectl get no \| nodes`                   | Muestra todos los nodes. [`Flags`](#Algunos-Flags) |
| `kubectl get svc \| services`               | Muestra todos los services en el namespace         |
| `kubectl get deploy \| deployments`         | Muestra todos los deployments                      |
| `kubectl get ep \| endpoints`               | Muestra todos los endpoints                        |
| `kubectl get ing \| ingress`                | Muestra todos los ingress                          |
| `kubectl get cs \| componentstatuses`       | Muestra el estado de salud de los componentes      |
| `kubectl get ns \| namespaces`              | Muestra todos los namespaces                       |
| `kubectl get rs \| replicasets`             | Muestra todos los Replicasets                      |
| `kubectl get sa \| serviceaccounts`         | Muestra todos los Service Accounts                 |
| `kubectl get clusterroles`                  | Muestra todos los Cluster Roles por defecto        |
| `kubectl get roles`                         | Muestra todos los Roles                            |
| `kubectl get pv \| persistentvolumes`       | Muestra todos los persistent volumes               |
| `kubectl get pvc \| persistentvolumeclaims` | Muestra todos los persistent volume claims         |
| `kubectl get secret`                        | Muestra todos los secrets/Tokens                   |
| `kubectl get rolebinding`                   | Muestra todos los rolebinding                      |

## Comando describe

| Comando                                                | Descripción                                                |
| ------------------------------------------------------ | ---------------------------------------------------------- |
| `kubectl describe po {POD_NAME}`                       | Información detallada de un pod                            |
| `kubectl describe no {NODE_NAME}`                      | Información del sistema (CPU y memoria) donde esta un nodo |
| `kubectl describe rs {REPLICA_SET_NAME}`               | Información detallada de un specific ReplicaSet            |
| `kubectl describe sa {SERVICE_ACCOUNT_NAME}`           | Información detallada de un specific Service Account       |
| `kubectl describe secret {SECRET_NAME}`                | Información detallada de un secret/Token                   |
| `kubectl describe rolebinding {ROLE_BINDING_NAME}`     | Información detallada de un role binding                   |
| `kubectl describe pv {PERSISTENT_VOLUME_NAME}`         | Información detallada de un persistent volume              |
| `kubectl describe pvc {PERSISTENT_VOLUME_CLAIMS_NAME}` | Información detallada de un persistent volume claim        |

## Comando delete

| Comando                                          | Descripción                                      |
| ------------------------------------------------ | ------------------------------------------------ |
| `kubectl delete po {POD_NAME}`                   | Elimina un pod                                   |
| `kubectl delete ns {NAMESPACE_NAME}`             | Elimina un namespace                             |
| `kubectl delete deploy {DEPLOY_NAME}`            | Elimina todo lo que fue creado con un deployment |
| `kubectl delete sa {SERVICE_ACCOUNT_NAME}`       | Elimina un service account                       |
| `kubectl delete role {ROLE_NAME}`                | Elimina un role                                  |
| `kubectl delete rolebinding {ROLE_BINDING_NAME}` | Elimina un role binding                          |
| `kubectl delete pv {PV_NAME}`                    | Elimina un persistent volume                     |
| `kubectl delete pvc {PVC_NAME}`                  | Elimina un persistent volume claim               |

## Comando config

| Comando                                                             | Descripción                 |
| ------------------------------------------------------------------- | --------------------------- |
| `kubectl config get-contexts`                                       | Muestra todos los clusters  |
| `kubectl config use-context {CLUSTER_NAME}`                         | Cambia el cluster en uso    |
| `kubectl config view \| grep namespace`                             | Muestra el namespace en uso |
| `kubectl config set-context --current --namespace={NAMESPACE_NAME}` | Cambia el namespace en uso  |

## Otros Commandos

| Comando                                                      | Descripción                                     |
| ------------------------------------------------------------ | ----------------------------------------------- |
| `kubectl expose deployment {DEPLOY_NAME} --type="ClusterIP"` | Expone una dirección IP externa                 |
| `kubectl proxy --port=8080`                                  | Inicia un proxi contra el Kubernetes API server |

### Algunos Flags:

| Flag               | Ejemplo                           | Descripción                                     |
| ------------------ | --------------------------------- | ----------------------------------------------- |
| `--all-namespaces` | `kubectl get po --all-namespaces` | Muestra todos los pods en todos los namespaces  |
| `-o wide`          | `kubectl get pods -o wide`        | Muestra todos los pods con detalles adicionales |
