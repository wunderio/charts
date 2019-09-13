# Silta Cluster Chart

This helm chart helps setting up resources for https://github.com/wunderio/silta-cluster

## Requirements

ServiceAccount and Roles for filebeat and metricbeat services. These have to be deployed manually.
 - https://raw.githubusercontent.com/wunderio/silta-cluster/master/filebeat-roles.yaml
 - https://raw.githubusercontent.com/wunderio/silta-cluster/master/metricbeat-roles.yaml

Configure static resource allocation for tiller:
```
set resources deployment tiller-deploy --limits=cpu=30m,memory=160Mi --requests=cpu=30m,memory=128Mi -n kube-system
``` 

Custom resource definitions for cert-manager (from https://github.com/helm/charts/tree/master/stable/cert-manager):
```
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
kubectl label namespace silta-cluster certmanager.k8s.io/disable-validation="true"
```

## Usage

Here is an example of how we instantiate this helm chart: 

```bash
helm upgrade --install --wait cluster-name silta-cluster \
             --repo "https://storage.googleapis.com/charts.wdr.io" \
             --values local-values.yaml            
```

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

#### Newrelic infrastructure monitoring
Monitoring Kubernetes deployments with newrelic:
 - [A Complete Introduction to Monitoring Kubernetes with New Relic](https://newrelic.com/platform/kubernetes/monitoring-guide)
 - [newrelic-infrastructure chart](https://github.com/helm/charts/tree/master/stable/newrelic-infrastructure)
