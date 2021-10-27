# Upgrading silta-cluster chart to 0.2.18

## Rclone s3/minio settings migration

Rclone s3/minio defaults have been removed from values file to avoid extra override requirement for some users. This means minio parameters need to be defined in your localized yaml file.

Move and adjust following parameters:
```yaml
csi-rclone:
  params:
    remote: "s3"
    remotePath: "projectname"
    
    # Minio as S3 provider
    s3-provider: "Minio"
    s3-endpoint: "http://silta-cluster-minio:9000"
    # Default credentials of minio chart https://github.com/minio/charts/blob/master/minio/values.yaml
    s3-access-key-id: "YOURACCESSKEY"
    s3-secret-access-key: "YOURSECRETKEY"
```

## Cert-manager migration from subchart to standalone installation

Upgrade process is required for clusters using kubernetes 1.20+ since it depreciates some API's and it does not work with older cert-manger releases. Starting silta-cluster 0.2.18, cert-manager subchart is disabled by default.

Following steps will upgrade cert-manager (0.10) that is shipped with silta-cluster helm chart to the latest (1.4), deployed as a standalone helm release. Helm charts (Drupal, Frontend and Simple) are updated and api version agnostic, and next deployment will deploy correct resource structure according to available cert-manager api.  

1. Disable cert-manager in Silta-cluster chart values:

    - Edit cluster values file, set cert-manager.enabled to false

    - Helm diff silta-cluster, make sure it’s correct cluster and values file
        ```bash
        helm diff upgrade silta-cluster charts/silta-cluster \
        --namespace silta-cluster \
        --values path/to/cluster/values.yaml
        ```

    - Helm upgrade --install
        ```bash
        helm upgrade silta-cluster charts/silta-cluster \
        --namespace silta-cluster \
        --values path/to/cluster/values.yaml
        ```

2. LEAVE certmanager crds untouched since helm upgrades are still looking for v1alpha1 api. You can remove old crd’s in few months when there are no more v1alpha1 crd’s left. 

    Hint: CRD’s might be installed in cert-manager namespace as “cert-manager-legacy-crds” release.

    - Query certificates using old crd’s
      ```bash
      kubectl get certificates.certmanager.k8s.io -A --no-headers=true | wc -l
      ```

    - Remove crd’s
      ```bash
      kubectl delete -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.10/deploy/manifests/00-crds.yaml
      ```

3. Remove cert-manager resources

    - Remove webhook
      ```bash
      kubectl delete apiservice v1beta1.webhook.cert-manager.io
      ```

    - Delete cert-manager clusterroles
      ```bash
      kubectl delete clusterrole cert-manager-view cert-manager-edit \
      cert-manager-controller-orders cert-manager-controller-issuers \
      cert-manager-controller-ingress-shim cert-manager-controller-clusterissuers \
      cert-manager-controller-challenges cert-manager-controller-certificates \
      cert-manager-cainjector
      ```

    - Delete cert-manager clusterrolebindings
      ```bash
      kubectl delete clusterrolebindings cert-manager-cainjector \
      cert-manager-controller-certificates cert-manager-controller-challenges \
      cert-manager-controller-clusterissuers cert-manager-controller-ingress-shim \
      cert-manager-controller-issuers cert-manager-controller-orders
      ```

    - Delete cert-manager roles and rolebindings resources (cert-manager:*) in kube-system

4. Install cert-manager
```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.4.1 \
  --set installCRDs=true \
  --set global.logLevel=1
```

5. Diff and upgrade silta-cluster again so it picks up new CRD’s and installs proper apiVersion clusterissuers

    - Helm diff silta-cluster, make sure it’s correct cluster and values file
      ```bash
      helm diff upgrade silta-cluster charts/silta-cluster \
      --namespace silta-cluster \
      --values path/to/cluster/values.yaml
      ```

    - Helm upgrade --install 
      ```bash
      helm upgrade silta-cluster charts/silta-cluster \
      --namespace silta-cluster \
      --values path/to/cluster/values.yaml
      ```

6. Don’t forget to commit and push cluster values file changes!

7. Existing certificate migration

    - Redeploy all related deployments with an empty commit (rerunning in circleci does not use the updated helm chart)
