# Upgrading silta-cluster chart to 1.8.0

This upgrade requires csi-rclone image upgrade to v3.0.0 or later.

## csi-rclone upgrade

csi-rclone (v3.0.0) implements PersistentVolume provisioner and requires changes to storage class configuration. Since storage class is immutable resource, it is necessary to remove the old storage class and do a silta-cluster chart deployment to create a new one.

```bash
kubectl delete storageclass silta-shared
```

Existing PersistentVolume definitions and PersistentVolumeClaims with selector will keep working with the updated driver.