# Upgrading silta-cluster chart to 0.2.14

This upgrade only matters if upgrading from RWO to RWX storage *or* when changing the storage class used for SSH keys

## SSH Jumpserver key storage upgrade

Moving SSH keys storage to RWX volumes, backed by S3 compatible buckets. This enables multiple jumpserver, keyserver pods to use the keys at the same time.


1. Download SSH keys via jumpserver pod, replace `ID` with existing pod's ID

    ```bash
    mkdir keys && kubectl cp -n silta-cluster silta-cluster-jumpserver-<ID>:etc/ssh/keys ./keys
    ``` 

2. Scale down keyserver, jumphost deployments

    ```bash
    kubectl scale deployment/silta-cluster-ssh-key-server -n silta-cluster --replicas=0
    kubectl scale deployment/silta-cluster-jumpserver -n silta-cluster --replicas=0
    ```

3. Delete old rwo PVC, will be replaced on deployment

    ```bash
    kubectl delete pvc silta-cluster-shell-keys -n silta-cluster
    ```

4. Diff and upgrade silta-cluster, check if new PVC is getting made

    - Helm diff silta-cluster, make sure it’s correct cluster and values file
      ```bash
      helm diff upgrade silta-cluster charts/silta-cluster \
      --namespace silta-cluster \
      --values path/to/cluster/values.yaml
      ```

    - Helm upgrade --install 
      ```bash
      helm upgrade silta-cluster charts/silta-cluster \
      --namespace silta-cluster \
      --values path/to/cluster/values.yaml
      ```

5. Check if jumpserver, keyserver pods are running, then scale down both deployments again

    ```bash
    kubectl scale deployment/silta-cluster-ssh-key-server -n silta-cluster --replicas=0
    kubectl scale deployment/silta-cluster-jumpserver -n silta-cluster --replicas=0
    ```
<br>
Following steps are tailored to GKE and assume bucket storage is used.

For others, change the commands to accomodate for copying SSH keys into new storage

6. Find the bucket used for key storage and check existence of newly created keys, named `ssh_host-*`

    ```bash
    gsutil ls gs://<BUCKET NAME>/silta-cluster/jumpserver
    ```

7. Migrate the old SSH keys in

    - Delete the new keys, made by deployment
      ```bash
      gsutil -m rm -r  gs://<BUCKET NAME>/silta-cluster/jumpserver/
      ```
    
    - Copy in the old SSH keys to this new storage
      ```bash
      gsutil cp keys/ssh_host_*  gs://<BUCKET NAME>/silta-cluster/jumpserver
      ```

End of GKE specifics, general instructions continue

8. Scale keyserver,jumphost deployments back to their original values, in this case 2.

    ```bash
    kubectl scale deployment/silta-cluster-jumpserver -n silta-cluster --replicas=2

    kubectl scale deployment/silta-cluster-ssh-key-server -n silta-cluster --replicas=2
    ```

9. Check if jumpserver has accepted the old keys, it must output for each key type
    `/etc/ssh/keys/ssh_host_*_key already exists.`<br>followed by `Server listening on 0.0.0.0 port 22.`
