# Upgrading silta-cluster chart to 0.2.43

## pxc-operator upgrade (run before upgrading silta-cluster chart)

1. Upgrade CRD's:

```bash
kubectl apply -f https://raw.githubusercontent.com/percona/percona-helm-charts/859cbbb5f54ba30df12e758e10e3f941bf4cc956/charts/ps-operator/crds/crd.yaml
```

Remove old validating webhook configuration:

```bash
kubectl delete validatingwebhookconfiguration validate-percona-xtradbcluster
```
