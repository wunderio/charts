# Silta Cluster Chart

This helm chart helps setting up resources for https://github.com/wunderio/silta-cluster

## Usage

Here is an example of how we instantiate this helm chart: 

```bash
helm upgrade --install --wait  cluster-name silta-cluster \
             --repo "https://wunderio.github.io/charts/" \
             --values local-values.yml            
```

## Components

#### SSH Jumphost

SSH Jumphost authentication is based on [sshd-gitAuth](https://github.com/wunderio/sshd-gitauth) project that will authorize users based on their SSH private key. The key whitelist is built by listing all users that belong to a certain github organisation.

You need to supply Github API Personal access token that will be used to get the list of organisation users. The access can be read only, following permissions are sufficient for the task: `public_repo, read:org, read:public_key, repo:status`.

#### Deployment remover

This is an exposed webhook that listens for branch delete events, logs in to cluster and removes named deployments using helm. Project code can be inspected at [silta-deployment-remover](https://github.com/wunderio/silta-deployment-remover).

