# Silta Cluster Chart

This helm chart helps setting up resources for https://github.com/wunderio/silta-cluster-tf

## Requirements

### cert-manager
```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.4.1 \
  --set installCRDs=true \
  --set global.logLevel=1
```

### Calico
If Calico networking is needed on AWS hosted cluster
(from https://github.com/aws/eks-charts/tree/master/stable/aws-calico/):
```
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k github.com/aws/eks-charts/tree/master/stable/aws-calico/crds
helm install --name aws-calico --namespace kube-system eks/aws-calico
```


#### Percona XtraDB Cluster for replicated database support
```
kubectl apply -f https://raw.githubusercontent.com/percona/percona-helm-charts/main/charts/pxc-operator/crds/crd.yaml
```

### PriorityClass
 PriorityClass resources `scheduling.k8s.io/v1beta1` `scheduling.k8s.io/v1alpha1` requires at least kubernetes v1.14. `scheduling.k8s.io/v1` API requires kubernetes v1.17.

## Usage

Here is an example of how we instantiate and upgrade this helm chart: 

```bash
helm upgrade --install --wait cluster-name silta-cluster \
             --repo "https://storage.googleapis.com/charts.wdr.io" \
             --values local-values.yaml            
```

## Upgrading

Chart upgrades are managed like a normal helm release, though it's suggested to do helm diff first:

```
helm diff upgrade cluster-name silta-cluster \
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

Provides persistent volume storageClass `silta-shared`, that allows mounting wide range of remote storage options to cluster pods.
Rclone project: https://rclone.org/
Rclone CSI plugin: https://github.com/wunderio/csi-rclone

#### MinIO server

The 100% Open Source, Enterprise-Grade, Amazon S3 Compatible Object Storage. This is an optional component for csi-rclone storage plugin.
MinIO project: https://min.io/  

#### Instana agent

Instana is an APM solution built for microservices, see more details on the official chart: https://github.com/helm/charts/tree/master/stable/instana-agent
