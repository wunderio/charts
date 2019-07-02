# CSI plugin for rclone mount

This helm chart helps setting up resources for https://github.com/wunderio/csi-rclone storage plugin

## Requirements

Service account for setting up resources into kube-system namespace. 

## Usage

1. Set up storage backend. You can use [Minio](https://min.io/), Amazon S3 compatible cloud storage service.

2. Either:
 a. configure rclone defaults by creating a [secret](https://github.com/wunderio/csi-rclone/blob/master/example/kubernetes/rclone-secret-example.yaml) in current namespace; 
 b. Or setting credentials via `values.yaml` override.

3. Install `csi-rclone` chart as release or release dependency.
Here is an example of how we instantiate this helm chart: 

```bash
helm upgrade --install --wait release-name csi-rclone \
             --repo "https://storage.googleapis.com/charts.wdr.io" \
             --values values.yaml            
```

and this is how we include it in another chart (via `requirements.yaml`)
```
- name: csi-rclone
  version: 0.1.x
  repository: https://storage.googleapis.com/charts.wdr.io
```

## Components

- [csi-rclone storage plugin](https://github.com/wunderio/csi-rclone)
