## Installing Kyverno policies

This folder contains some example Kyverno policies that can be used to enforce security best practices in a Kubernetes cluster.

```bash
kubectl apply -f .
```

## Adding privileged pod security policy for system namespaces

```bash
kubectl label namespace silta-cluster pod-security.kubernetes.io/enforce=privileged
kubectl label namespace kube-system pod-security.kubernetes.io/enforce=privileged
```

### Adding users to cluster-admin cluster role (optional, see disallow-privileged-containers policy)

```bash
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin \
    --user=USER_ONE \
    --user=USER_TWO
```

## Adding PSA labels to existing namespaces

Option "A" Add PSA labels to existing using bash:

```bash
for namespace in $( kubectl get namespaces --no-headers -o custom-columns=":metadata.name"); do
    kubectl label namespace "${namespace}" pod-security.kubernetes.io/enforce=baseline
    kubectl label namespace "${namespace}" pod-security.kubernetes.io/enforce-version=latest
    kubectl label namespace "${namespace}" pod-security.kubernetes.io/warn=baseline
    kubectl label namespace "${namespace}" pod-security.kubernetes.io/warn-version=latest
done
```

Option "B" Add PSA labels to existing using kubectl and kyverno policy:

```bash
kubectl apply -f ../kyverno-add-psa-labels-existing-ns.yaml
kubectl delete -f ../kyverno-add-psa-labels-existing-ns.yaml
```
