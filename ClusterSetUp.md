# Setting up the K8s Cluster

- [`kubectl`](#install-kubectl)
- [`docker`](#docker)
- [`minikube`](#minikube-optional)

## Install-kubectl

| Commands                           | OS                                                     |
| ---------------------------------- | ------------------------------------------------------ |
| `brew install kubectl`             | Linux and MacOS (Option1)                              |
| `snap install kubectl --classic`   | Linux and MacOS (Option2)                              |
| `choco install kubernetes-cli`     | Windows (Option1)                                      |
| `scoop install kubectl`            | Windows (Opt   ion2)                                   |
| `kubectl version --client --short` | Test to ensure the version you installed is up-to-date |

### Additional info on

- [Installing Chocolatey](https://chocolatey.org/install)
- [Installing kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Managing multiple client kubectl versions with asdf](https://asdf-vm.com/#/)

## Docker

| Installation Links                                                        | OS                                      |
| ------------------------------------------------------------------------- | --------------------------------------- |
| [docker-for-mac](https://docs.docker.com/docker-for-mac/install/)         | Linux and MacOS                         |
| [docker-for-windows](https://docs.docker.com/docker-for-windows/install/) | Windows                                 |
| `docker version`                                                          | Test docker from terminal               |
| About Docker Desktop                                                      | Test docker from the Docker Desktop App |

Enable Kubernetes on Docker ( only if you're not using Minikube)
![Drag Racing](enable_k8s_on_docker.png)

## Minikube (Optional)

### Express Installation

| Installation Command     | OS                         |
| ------------------------ | -------------------------- |
| `brew install minikube`  | Linux and MacOS            |
| `choco install minikube` | Windows                    |
| `minikube version`       | Test minikube installation |

[Custom Installation](https://kubernetes.io/docs/tasks/tools/install-minikube/)

### Minikube Commands

| Commands                                                                                                  | Description                                                                                                                                                                                                  |
| --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `minikube start --driver=docker --kubernetes-version v1.21.0 --nodes 3 --network-plugin=cni --cni=calico` | Start a cluster using the docker driver with the specified kubernetes version and 3 nodes. [Additional VM drivers](https://kubernetes.io/docs/setup/learning-environment/minikube/#specifying-the-vm-driver) |
| `minikube stop`                                                                                           | Stop the local cluster                                                                                                                                                                                       |
| `minikube delete`                                                                                         | Delete the local cluster                                                                                                                                                                                     |
| `eval $(minikube docker-env)`                                                                             | Reuse the Docker daemon inside the VM                                                                                                                                                                        |
| `minikube service <svc-name>`                                                                             | [Open the provided service in your default browser][1]                                                                                                                                                       |

[1]: https://stackoverflow.com/a/40774861/5212904
