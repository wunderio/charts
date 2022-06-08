# Upgrading silta-cluster chart to 0.2.31

## Cert-manager 1.8.0 upgrade

4. Upgrade cert-manager
```bash
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.8.0 \
  --set installCRDs=true \
  --set global.logLevel=1
```
