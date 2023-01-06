# Upgrading silta-cluster chart to 0.2.36

## csi-rclone driver upgrade

csi-rclone 0.3.x subchart relies on tini init and requires 1.3.x+ images. If you have overridden `csi-rclone.version`, replace it with the [latest available](https://hub.docker.com/r/wunderio/csi-rclone/tags) (1.3+). 

```yaml
csi-rclone:
  version: xyz
```

Note: Drive image version is not overriden by default, it uses [value](https://github.com/wunderio/charts/blob/master/csi-rclone/values.yaml) from `csi-rclone` subchart. Don't set the version unless You really need to pin it.

Note 2: Restart pods mounting the silta-shared storage after rclone plugin containers are restarted.
