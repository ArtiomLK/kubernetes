# Helm Commands

| Command                          | Description                                                                                              |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `helm init`                      | Install Tiller to your running Kubernetes cluster. It will also set up any necessary local configuration |
| `helm repo update`               | Updates index chart repositories                                                                         |
| `helm search {CHART_NAME}`       | Searches for a specific chart                                                                            |
| `helm install {CHART_REFERENCE}` | Installs a specific chart. E.g. `helm install stable/mariadb`                                            |
| `helm create {CHART_NAME}`       | Create a new chart with the given name                                                                   |
| `helm package {CHART_PATH}`      | Packages a chart directory into a chart archive                                                          |
| `helm delete {RELREASE_NAME}`    | Given a release name, delete the release from Kubernetes                                                 |
