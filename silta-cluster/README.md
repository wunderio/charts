# Silta Cluster Chart

This helm chart helps setting up resources for https://github.com/wunderio/silta-cluster-tf

## Requirements

### Set up helm repositories

```
# Jetstack helm chart repository for cert-manager
helm repo add jetstack https://charts.jetstack.io

# Wunderio helm chart repository for silta-cluster
helm repo add wunderio https://storage.googleapis.com/charts.wdr.io

# Docker Registry Helm Chart (optional)
helm repo add twuni https://helm.twun.io

# ingress-nginx (optional)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# nginx-stable (optional)
# CRD's need to be installed manually, see below
helm repo add nginx-ingress https://helm.nginx.com/stable
```

Note: nginx-ingress requires CRD installation before installing the chart. See https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/#installing-the-crds for instructions.

### cert-manager (required for ssl/tls)

Here are installation steps from official documentation https://cert-manager.io/docs/installation/helm/ -

```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.8.0 \
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
### Kyverno policy agent (optional)

Kyverno is a policy engine designed for Kubernetes. It allows cluster administrators to enforce policies on resources in a Kubernetes cluster. 

1. Install Kyverno using helm chart:
```
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace --set features.logging.verbosity=1
```

2. Install required policies using kubectl or install [kyverno-policies helm chart](https://github.com/kyverno/kyverno/tree/main/charts/kyverno-policies). Policy examples can be found at [official documentation](https://kyverno.io/policies/) and in [docs/kyverno-policies](docs/kyverno-policies) directory.
See [kyverno-policies README](docs/kyverno-policies/README.md) for more information.

### ingress-nginx load balancer on GKE private cluster

When using GKE private cluster, enabling `ingress-nginx` (and `nginx-traefik`) will require additional steps. See [gcs vendor page](https://github.com/wunderio/silta/blob/master/docs/vendor-gcs.md#ingress-nginx-load-balancer-on-gke-private-cluster) in silta documentation for instructions.

### Percona XtraDB Cluster for replicated database support (optional)
```
# CRD for pxc-operator 1.12.x. Depends on pxc-operator version in Chart.yaml.
kubectl apply -f https://raw.githubusercontent.com/percona/percona-helm-charts/dcfc35a1158862da60a89010e4cabaa2b94560f5/charts/pxc-operator/crds/crd.yaml
```

### Google Filestore as storage (optional)

Adds a storageclass, backed by Filestore.
Filestore is an NFS server managed by Google.

Requires [Filestore NFS volume](https://cloud.google.com/filestore) to be accessible from the cluster.

- Export NFS volume as `main_share`
- Enable nfs-subdir chart, pass the NFS server IP in values file.

```
nfs-subdir-external-provisioner:
  enabled: true
  nfs:
    server: x.x.x.x
```

### Docker image registry

It is possible to enable `docker-registry` component for `silta-cluster`. This allows running local image registry, but there are few extra steps to do:

1. Set username and password at `docker-registry.secrets.htpasswd`. Generate user:passwordhash using `htpasswd -Bbn user password` command.
2. Allow deployments to use image registry by either setting `imagePullSecrets` in chart values or creating default imagePullSecrets -
```bash
kubectl create secret docker-registry silta-registry \
  --docker-server=registry.[cluster-domain] \
  --docker-username=registry \
  --docker-password=silta \
  --docker-email=silta-registry@[cluster-domain]

kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "silta-registry"}]}' 
```
Do the last patch command for the each project namespace that will use images from repository.

## Usage

Here is an example of how we instantiate and upgrade this helm chart: 

```bash
helm upgrade --install --wait silta-cluster silta-cluster \
    --namespace silta-cluster --create-namespace \
    --repo "https://storage.googleapis.com/charts.wdr.io" \
    --values local-values.yaml            
```

- `local-values.yaml` contains overrides of [chart defaults](values.yaml) 

Make sure silta-cluster namespace has `name=silta-cluster` label set or environment connections will time out.
```bash
kubectl label namespace silta-cluster name=silta-cluster
```

## Compatibility
- More recent versions are tested frequently, see versions and test results in [github actions page](https://github.com/wunderio/charts/actions/workflows/pull-request.yml?query=branch%3Amaster).
- Kubernetes 1.24 requires at least 0.2.32
- Kubernetes 1.23 requires at least 0.2.32
- Kubernetes 1.22 requires at least 0.2.30
- Kubernetes 1.20 requires at least 0.2.18
- Should work with kubernetes 1.13+

## Upgrading

Chart upgrades are managed like a normal helm release, though it's suggested to do helm diff first:

```
helm diff upgrade silta-cluster silta-cluster \
    --repo "https://storage.googleapis.com/charts.wdr.io" \
    --namespace silta-cluster \
    --values local-values.yaml
    
helm upgrade --install --wait silta-cluster silta-cluster \
    --repo "https://storage.googleapis.com/charts.wdr.io" \
    --namespace silta-cluster --create-namespace \
    --values local-values.yaml
```

## Upgrade path for older versions:

 - Upgrading silta-cluster chart to 1.8.0 ([docs/Upgrading-to-1.8.0.md](docs/Upgrading-to-1.8.0.md))

 - Upgrading silta-cluster chart to 0.2.43 ([docs/Upgrading-to-0.2.43.md](docs/Upgrading-to-0.2.43.md))

 - Upgrading silta-cluster chart to 0.2.36 ([docs/Upgrading-to-0.2.36.md](docs/Upgrading-to-0.2.36.md))
 
 - Upgrading silta-cluster chart to 0.2.32 ([docs/Upgrading-to-0.2.32.md](docs/Upgrading-to-0.2.32.md))
 
 - Upgrading silta-cluster chart to 0.2.18 ([docs/Upgrading-to-0.2.18.md](docs/Upgrading-to-0.2.18.md))

 - Upgrading silta-cluster chart to 0.2.14 ([docs/Upgrading-to-0.2.14.md](docs/Upgrading-to-0.2.14.md))

## Components 

#### Ingress controller

Silta cluster uses traefik (1) ingress controller by default but it supports running other controllers too. More about compatible ingress controllers can be found in [ingress controller](docs/ingress-controller.md) documentation page. Traefik is still kept for non-breaking updates, but it's highly suggested to use nginx load balancer instead. If it's impossible to migrate to nginx, look into `nginx-traefik` section of [chart values file](https://github.com/wunderio/charts/blob/master/silta-cluster/values.yaml).

#### SSH Jumphost

SSH Jumphost authentication is based on [sshd-gitAuth](https://github.com/wunderio/sshd-gitauth) project that will authorize users based on their SSH private key. The key whitelist is built by listing all users that belong to a certain github organisation and allowing acccess to projects when user has at least `push` permission to the repository.

You need to supply Github API Personal access token that will be used to get the list of organisation users. The access can be read only, following permissions are sufficient for the task: `public_repo, read:org, read:public_key, repo:status`.

#### Deployment remover

This is an exposed webhook that listens for branch delete events, logs in to cluster and removes named deployments using helm. Project code can be inspected at [silta-deployment-remover](https://github.com/wunderio/silta-deployment-remover).

#### Deployment downscaler

How it works:

- CronJob runs the following
  - Get Ingresses with a `auto-downscale/last-update` annotation, this is used to check which should be downscaled.
  - The `auto-downscale/services` annotation on the ingress indicates which service should be redirected to the placeholder page.
  - The `auto-downscale/label-selector` indicates which deployments, statefulsets and cronjobs should be downscaled. This is typically set to `release=<release-name>`.
    
- When someone hits the placeholder
  - Get Ingress matching current hostname
  - Show message to user with option to upscale the deployment
  - When resources are scaled to original values and in ready state, page is reloaded.

#### Rclone storage

Provides persistent volume storageClass `silta-shared`, that allows mounting wide range of remote storage options to cluster pods.
Rclone project: https://rclone.org/
Rclone CSI plugin: https://github.com/wunderio/csi-rclone

#### MinIO server

The 100% Open Source, Enterprise-Grade, Amazon S3 Compatible Object Storage. This is an optional component for csi-rclone storage plugin.
MinIO project: https://min.io/  

#### Instana agent

Instana is an APM solution built for microservices, see more details on the official chart: https://github.com/helm/charts/tree/master/stable/instana-agent
