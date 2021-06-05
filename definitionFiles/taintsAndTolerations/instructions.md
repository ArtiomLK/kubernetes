# Instructions

## Set Up

1. `kubectl taint node minikube key0=val0:NoSchedule`
1. `kubectl taint node minikube key0=val0:NoExecute`
1. `kubectl apply -f pod-w-tolerations.yaml`
1. `kubectl get pods -o wide`

## Clean up

1. `kubectl taint node minikube key0=val0:NoSchedule-`
1. `kubectl taint node minikube key0=val0:NoExecute-`
1. `kubectl delete -f pod-w-tolerations.yaml`
