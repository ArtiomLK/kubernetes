# Helm 3

## Getting started

- [Quickstart Guide](https://helm.sh/docs/intro/quickstart/)

## Helm Commands

| Command                                                     | Description                                                   |
| ----------------------------------------------------------- | ------------------------------------------------------------- |
| [`helm repo add stable https://charts.helm.sh/stable`][100] | Add a chart repository                                        |
| [`helm repo update`][103]                                   | Updates index chart repositories                              |
| [`helm search repo stable`][101]                            | Searches for a specific chart                                 |
| [`helm install {CHART_REFERENCE}`][104]                     | Installs a specific chart. E.g. `helm install stable/mariadb` |
| [`helm uninstall {RELEASE_NAME}`][107]                      | Given a release name, uninstall the release from Kubernetes   |
| [`helm create {CHART_NAME}`][105]                           | Create a new chart with the given name                        |
| [`helm package {CHART_PATH}`][106]                          | Packages a chart directory into a chart archive               |

[100]: https://docs.helm.sh/docs/helm/helm_repo_add/
[101]: https://helm.sh/docs/helm/helm_search_repo/
[103]: https://helm.sh/docs/helm/helm_repo_update/
[104]: https://helm.sh/docs/helm/helm_install/
[105]: https://helm.sh/docs/helm/helm_create/
[106]: https://helm.sh/docs/helm/helm_package/
[107]: https://helm.sh/docs/helm/helm_uninstall/
