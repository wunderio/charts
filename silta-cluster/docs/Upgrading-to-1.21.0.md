# Upgrading silta-cluster chart to 1.21.0

## SSH jumphost now uses silta-ssh-bridge by default

The SSH jumphost (`gitAuth`) defaults have changed from [sshd-gitauth](https://github.com/wunderio/sshd-gitauth) to [silta-ssh-bridge](https://hub.docker.com/r/wunderio/silta-ssh-bridge):

```yaml
gitAuth:
  image: wunderio/silta-ssh-bridge
  imageTag: 1
  mode: bridge
```

In `bridge` mode the jumphost no longer opens a second SSH connection to the destination container, it bridges the session to `kubectl exec` instead. User authorization is unchanged: access is still granted based on GitHub organisation membership and repository `push` permission.
After the upgrade, users get a one-time `REMOTE HOST IDENTIFICATION HAS CHANGED` warning, because the host key of the final hop changes. Remove the stale key and reconnect:

```bash
ssh-keygen -R <host>
```

The previous sshd-gitauth based jumphost is still available, but won't be maintained. To keep using it, override the defaults in your cluster values:

```yaml
gitAuth:
  mode: openssh
  image: wunderio/sshd-gitauth
  imageTag: v1.0
```

## csi-rclone image version

`v3.1.2` is the recommended image version. It fixes FUSE mounts on Ubuntu 26.04+ hosts, where the AppArmor `fusermount3` profile denies mounts under `/var/lib/kubelet/pods` ([wunderio/csi-rclone#69](https://github.com/wunderio/csi-rclone/issues/69)). It also brings rclone 1.74.3, Alpine 3.23 and the MPTCP mitigation for CVE-2026-98432 (from v3.1.0 and v3.1.1).
Set it explicitly in your cluster values to avoid accidental downgrades:

```yaml
csi-rclone:
  version: v3.1.2
```
Restart all pods that use the csi-rclone driver to pick up the new image version.