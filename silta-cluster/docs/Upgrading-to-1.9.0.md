# Upgrading silta-cluster chart to 1.9.0

## Cert-manager upgrade to v1.16.2

It is important to do upgrade in steps, doing an upgrade for every major version. For example - if You are upgrading from v1.8.0 to v1.16.2, You should do upgrade to v1.9.0, then v1.10.0, then v1.11.0, and so on.

The single most important change for upgrades from v1.8.0 to v1.16.2 is in version v1.15 helm chart, where `installCRDs: true` helm value is replaced with `crds.enabled: true`. 
This means, You carry out the upgrade in two steps: first upgrade to v1.15.0 and then to v1.16.2.

For upgrading from v1.8.0 to v1.14.x, use the following commands:

```bash
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.0 --set installCRDs=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.10.0 --set installCRDs=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.0 --set installCRDs=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.14.0 --set installCRDs=true --set global.logLevel=1
```

For upgrading from v1.15.4 to v1.16.2, use the following commands:

```bash
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.15.0 --set crds.enabled=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.15.4 --set crds.enabled=true --set global.logLevel=1
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.16.2 --set crds.enabled=true --set global.logLevel=1
```

Skipping some versions is possible, but it is not recommended. 
Related documentation: 
- [https://cert-manager.io/docs/installation/upgrading/](https://cert-manager.io/docs/installation/upgrading/)
- [https://cert-manager.io/docs/releases/](https://cert-manager.io/docs/releases/)
