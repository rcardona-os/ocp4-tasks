### 0 - Prerequisites

- User to be logged in with cluster-admin privileges
- Openshift Data Foundation
- OpenShift API for Data Protection with OpenShift Data Foundation [Operator Installed](https://docs.openshift.com/container-platform/4.13/backup_and_restore/application_backup_and_restore/installing/installing-oadp-ocs.html)

### 1 - Create bucket in ODF with Noobaa storage class

    echo -n 'apiVersion: objectbucket.io/v1alpha1
    kind: ObjectBucketClaim
    metadata:
      name: adp-bucket
      namespace: openshift-adp
    spec:
      additionalConfig:
        bucketclass: noobaa-default-bucket-class
      generateBucketName: adp
      storageClassName: openshift-storage.noobaa.io' | tee obc.yaml

   > $ oc apply -f obc.yaml
   >

### 2 - Extract bucket credentials
  
    echo -e "[default]
    aws_access_key_id=`oc get -o json secret adp-bucket | jq -r '.data.AWS_ACCESS_KEY_ID' | base64 -d`
    aws_secret_access_key=`oc get -o json secret adp-bucket | jq -r '.data.AWS_SECRET_ACCESS_KEY' | base64 -d`" | tee credentials-velero

### 3 - Create the secret/credential for adp

     $ cat credentials-velero
     [default]
     aws_access_key_id=${AWS_ACCESS_KEY_ID}
     aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

> $ oc create secret generic cloud-credentials --from-file cloud=credentials-velero -n openshift-adp
>
   
### 4 - Create `DataProtectionApplication` instance. It have to be configure depending on the platform target, the example here come the examples of ODF on baremetal, and ODF on AWS.

 __NOTE: update **objectStorage** detail__

  ##### (option a) - ODF on baremetal
  > $ curl -O  https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/data-protection/files/configure-data-protection_odf_baremetal.yaml
  >

  __NOTE: update **objectStorage** details__

  > $ oc apply -f configure-data-protection_odf_baremetal.yaml
  >

  ##### (option b) - ODF on aws
  > $ curl -O  https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/data-protection/files/configure-data-protection_odf_aws.yaml
  >
  
  __NOTE: update **objectStorage** details__

  > $ oc apply -f configure-data-protection_odf_aws.yaml
  >



__NOTE: proceed to the next step once OADP components are deployed__

### 5 - Deploy application to backup
  > $ oc apply -f https://gitlab.com/rcardona/ocp4-apps-examples/-/raw/master/demo-apps-composite/apps/rocket-chat/manifests/deployment.yaml
  >

### 6 - Create the manual backup

    echo -n 'apiVersion: velero.io/v1
    kind: Backup
    metadata:
      name: backup
      namespace: openshift-adp
    spec:
      includedNamespaces:
      - rocket-chat' | tee adp-backup.yaml

    
   > $ oc apply -f adp-backup.yaml
   > 

### 6 - Delete project

  > $ oc delete project rocket-chat
  >

### Restore application

    echo -n 'apiVersion: v1
    kind: List
    metadata:
    items:
    - apiVersion: velero.io/v1
      kind: Restore
      metadata:
        name: restore
        namespace: openshift-adp
      spec:
        backupName: backup
        excludedResources:
        - nodes
        - events
        - events.events.k8s.io
        - backups.velero.io
        - restores.velero.io
        - resticrepositories.velero.io
        includedNamespaces:
        - rocket-chat
        restorePVs: true' | tee adp-restore.yaml

   > $ oc apply -f adp-restore.yaml
   >


---

### Troubleshoot

- backup phase
  > $ oc -n openshift-adp exec deployment/velero -c velero -- ./velero backup describe backup 
  >

  > $ oc -n openshift-adp exec deployment/velero -c velero -- ./velero backup logs backup
  >

- tackle the below error, by labeling the `volumesnapshotclass`

   ... failed to get volumesnapshotclass for storageclass ocs-storagecluster-ceph-rbd: failed to get volumesnapshotclass for provisioner openshift-storage.rbd.csi.ceph.com, ensure that the desired volumesnapshot class has the velero.io/csi-volumesnapshot-class label"...

> $ oc label volumesnapshotclass/ocs-storagecluster-rbdplugin-snapclass velero.io/csi-volumesnapshot-class=true
>
