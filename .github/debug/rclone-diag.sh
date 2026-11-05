set +e
NS=drupal-project-k8s
CNS=silta-cluster
FILES=/app/web/sites/default/files

echo "::group::host"
uname -a; grep PRETTY /etc/os-release
docker version --format 'docker server {{.Server.Version}}'
docker info --format 'security={{json .SecurityOptions}} cgroup=v{{.CgroupVersion}} driver={{.CgroupDriver}} storage={{.Driver}}'
echo "apparmor_restrict_unprivileged_userns=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>&1)"
sudo aa-status 2>&1 | head -40
echo "--- /etc/fuse.conf"; cat /etc/fuse.conf 2>&1
ls -l /dev/fuse; lsmod | grep -i fuse
echo "::endgroup::"

echo "::group::host dmesg (apparmor/fuse/denied)"
sudo dmesg -T | grep -iE "apparmor|denied|fuse|audit" | tail -100
echo "::endgroup::"

echo "::group::minikube node"
minikube ssh -- 'uname -a; echo "--- fuse.conf"; cat /etc/fuse.conf; ls -l /dev/fuse; echo "--- fuse mounts"; grep -E "fuse" /proc/mounts'
minikube ssh -- 'for d in /var/lib/kubelet/pods/*/volumes/kubernetes.io~csi/*/mount; do echo "== $d"; sudo stat -c "%A %u:%g %n" "$d"; sudo ls -lan "$d" | head -8; done'
echo "::endgroup::"

echo "::group::k8s storage"
kubectl get sc,pv,pvc -A -o wide
kubectl get sc silta-shared -o yaml
kubectl get pv -o yaml | grep -vE "^\s+(uid|resourceVersion|creationTimestamp):"
echo "::endgroup::"

echo "::group::csi-rclone node plugin"
P=$(kubectl -n $CNS get pod -l app=csi-nodeplugin-rclone -o name | head -1)
echo "pod: $P"
kubectl -n $CNS get $P -o jsonpath='{.spec.containers[1].image}{"\n"}{.spec.containers[1].args}{"\n"}'
kubectl -n $CNS exec $P -c rclone -- sh -c 'rclone version | head -3; id; echo "umask=$(umask)"; echo "--- fuse.conf"; cat /etc/fuse.conf; echo "--- rclone mounts"; grep rclone /proc/mounts; echo "--- rclone procs"; ps -o pid,user,args | grep "[r]clone mount"'
echo "--- plugin logs"
kubectl -n $CNS logs $P -c rclone --tail=400
echo "--- controller logs"
kubectl -n $CNS logs -l app=csi-controller-rclone --all-containers --tail=100
echo "::endgroup::"

echo "::group::drupal workloads"
kubectl -n $NS get deploy,sts,job,pod -o wide
for d in $(kubectl -n $NS get deploy -o name); do
  echo "== $d securityContext"
  kubectl -n $NS get $d -o jsonpath='pod={.spec.template.spec.securityContext}{"\n"}{range .spec.template.spec.containers[*]}{.name}={.securityContext}{"\n"}{end}'
done
kubectl -n $NS get job -o jsonpath='{range .items[*]}{.metadata.name}: pod={.spec.template.spec.securityContext} ctr={.spec.template.spec.containers[0].securityContext}{"\n"}{end}'
echo "::endgroup::"

echo "::group::write probe from test-shell (app user)"
kubectl -n $NS exec deploy/test-shell -- sh -c "id; echo umask=\$(umask); grep -E ' /app' /proc/mounts; for p in $FILES /app/private; do stat -c '%A %u:%g %n' \$p; done; ls -lan $FILES | head; touch $FILES/probe-shell && echo WRITE_OK || echo WRITE_FAIL; mkdir $FILES/probe-shell-dir && echo MKDIR_OK || echo MKDIR_FAIL; ls -lan $FILES | head"
echo "::endgroup::"

echo "::group::write probe from php container"
kubectl -n $NS exec deploy/test-drupal -c php -- sh -c "id; stat -c '%A %u:%g %n' $FILES; touch $FILES/probe-php && echo WRITE_OK || echo WRITE_FAIL"
echo "::endgroup::"

echo "::group::write probe as root and as uid 1000 (fresh pods on the same PVC)"
PVC=$(kubectl -n $NS get pvc -o name | grep -i public | head -1 | cut -d/ -f2)
echo "pvc: $PVC"
for u in 0 1000; do
cat <<EOF | kubectl -n $NS apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: probe-uid-$u
spec:
  restartPolicy: Never
  securityContext:
    runAsUser: $u
    runAsGroup: $u
  containers:
  - name: p
    image: busybox:1.36
    command: ["sh","-c","id; stat -c '%A %u:%g %n' /mnt; grep ' /mnt' /proc/mounts; touch /mnt/probe-$u && echo WRITE_OK || echo WRITE_FAIL; ls -lan /mnt | head"]
    volumeMounts:
    - name: v
      mountPath: /mnt
  volumes:
  - name: v
    persistentVolumeClaim:
      claimName: $PVC
EOF
done
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Succeeded pod/probe-uid-0 pod/probe-uid-1000 --timeout=120s
for u in 0 1000; do echo "== probe-uid-$u"; kubectl -n $NS logs probe-uid-$u; kubectl -n $NS describe pod probe-uid-$u | sed -n '/Events:/,$p'; done
echo "::endgroup::"

echo "::group::post-dump dmesg"
sudo dmesg -T | grep -iE "apparmor|denied|fuse|audit" | tail -50
echo "::endgroup::"
exit 0
