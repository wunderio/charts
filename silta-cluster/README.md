# Silta Cluster Chart

This helm chart helps setting up resources for https://github.com/wunderio/silta-cluster-tf

## Requirements

### Set up helm repositories

```
# Jetstack helm chart repository for cert-manager
helm repo add jetstack https://charts.jetstack.io

# Wunderio helm chart repository for silta-cluster
helm repo add wunderio https://storage.googleapis.com/charts.wdr.io
```

### cert-manager (required for ssl/tls)

Here are installation steps from official documentation https://cert-manager.io/docs/installation/helm/ -

```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.6.1 \
  --set installCRDs=true \
  --set global.logLevel=1
```

### Calico

Calico works with network policy resource definitions allowing fine grained traffic control for in-cluster resources. Our charts define secure defaults that allow selective access to environments.

GKE: Calico can be enabled using GCP interface or `gcloud` cli tool (`--enable-network-policy`).

AKS: Calico can be enabled using `az` cli tool (`--network-plugin kubenet`, `--network-policy calico`). This can't be changed after cluster is created.

AWS: Requires manual installation, see below:

If Calico networking is needed on AWS hosted cluster
(from https://github.com/aws/eks-charts/tree/master/stable/aws-calico/):
```
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k github.com/aws/eks-charts/tree/master/stable/aws-calico/crds
helm install --name aws-calico --namespace kube-system eks/aws-calico
```

#### Percona XtraDB Cluster for replicated database support (optional)
```
kubectl apply -f https://raw.githubusercontent.com/percona/percona-helm-charts/main/charts/pxc-operator/crds/crd.yaml
```

#### Google Filestore as storage (optional)

Adds a storageclass, backed by Filestore.
Filestore is an NFS server managed by Google.

Requires [Filestore NFS volume](https://cloud.google.com/filestore/pricing) to be accessible from the cluster.
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install \
nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--namespace silta-cluster \
--set nfs.server=x.x.x.x \
--set nfs.path=/exported/path \
--set storageClass.name=nfs-shared \
--set storageClass.onDelete=delete \
--set storageClass.pathPattern="${.PVC.namespace}/${.PVC.annotations.nfs.io/storage-path}"
```

## Usage

Here is an example of how we instantiate and upgrade this helm chart: 

```bash
helm upgrade --install --wait silta-cluster silta-cluster \
    --namespace silta-cluster --create-namespace \
    --repo "https://storage.googleapis.com/charts.wdr.io" \
    --values local-values.yaml            
```

- `local-values.yaml` contains overrides of [chart defaults](values.yaml) 

## Upgrading

Chart upgrades are managed like a normal helm release, though it's suggested to do helm diff first:

```
helm diff upgrade silta-cluster silta-cluster --namespace silta-cluster \
    --values local-values.yaml
    
helm upgrade --install --wait silta-cluster silta-cluster \
    --repo "https://storage.googleapis.com/charts.wdr.io" \
    --namespace silta-cluster --create-namespace \
    --values local-values.yaml
```

## Upgrade path for older versions:

 - Upgrading silta-cluster chart to 0.2.18 ([docs/Upgrading-to-0.2.18.md](docs/Upgrading-to-0.2.18.md))

 - Upgrading silta-cluster chart to 0.2.14 ([docs/Upgrading-to-0.2.14.md](docs/Upgrading-to-0.2.14.md))

## Components 

#### SSH Jumphost

SSH Jumphost authentication is based on [sshd-gitAuth](https://github.com/wunderio/sshd-gitauth) project that will authorize users based on their SSH private key. The key whitelist is built by listing all users that belong to a certain github organisation.

You need to supply Github API Personal access token that will be used to get the list of organisation users. The access can be read only, following permissions are sufficient for the task: `public_repo, read:org, read:public_key, repo:status`.

#### Deployment remover

This is an exposed webhook that listens for branch delete events, logs in to cluster and removes named deployments using helm. Project code can be inspected at [silta-deployment-remover](https://github.com/wunderio/silta-deployment-remover).

#### Rclone storage

https://github.com/wunderio/silta/blob/master/docs/vendor-aks.md#azure-files
Provides persistent volume storageClass `silta-shared`, that allows mounting wide range of remote storage options to cluster pods.
Rclone project: https://rclone.org/
Rclone CSI plugin: https://github.com/wunderio/csi-rclone

#### MinIO server

The 100% Open Source, Enterprise-Grade, Amazon S3 Compatible Object Storage. This is an optional component for csi-rclone storage plugin.
MinIO project: https://min.io/  

#### Instana agent

Instana is an APM solution built for microservices, see more details on the official chart: https://github.com/helm/charts/tree/master/stable/instana-agent
