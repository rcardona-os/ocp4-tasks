### Enabling Persistent Storage for the OCP Internal Registry

This has been tested with OCP v4.12

- prerequisites
  - Openshift Data Foundation v 4.12.0 already installed

- testing existing storage classes, in this case `ocs-storagecluster-cephfs` has been used

      host@st :  /
      $ oc get sc ocs-storagecluster-cephfs
      NAME                        PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      ocs-storagecluster-cephfs   openshift-storage.cephfs.csi.ceph.com   Delete          Immediate           true                   30m

- creating physical volume claim (in this exameple it was set to 100GB, but take in account your space requirements)

      echo -n 'apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: ocs4registry
        namespace: openshift-image-registry
      spec:
        accessModes:
        - ReadWriteMany
        resources:
          requests:
            storage: 50Gi
        storageClassName: ocs-storagecluster-cephfs
        volumeMode: Filesystem' | tee pvc-internal-registry.yaml

    > $ oc apply -f pvc-internal-registry.yaml
    >

- edit *imageregistry.operator.openshift.io* to add the previously created physical volume
  > $ oc edit config.imageregistry.operator.openshift.io
  >

      ...
        spec:
          ...
          storage:
            pvc:
              claim: ocs4registry

- refresh the internal registry instances by scaling the deployment 0 instances, and bring it back to the desired state
> $ oc scale deployment image-registry --replicas 0 -n openshift-image-registry
>

> $ oc scale deployment image-registry --replicas 2 -n openshift-image-registry
>

- test the existing internal registry instances
> $ oc get pod -n openshift-image-registry
>
