# Upgrading silta-cluster chart to 0.2.43

## pxc-operator upgrade (run before upgrading silta-cluster chart)

1. Upgrade CRD's:

```bash
kubectl apply -f https://raw.githubusercontent.com/percona/percona-helm-charts/dcfc35a1158862da60a89010e4cabaa2b94560f5/charts/pxc-operator/crds/crd.yaml
```

Remove old validating webhook configuration:

```bash
kubectl delete validatingwebhookconfiguration validate-percona-xtradbcluster
```
