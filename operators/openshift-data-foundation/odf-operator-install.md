### Install Openshift Data Foundation Operator


[Openshift Data Foundation 4.9 Docs](https://docs.openshift.com/container-platform/4.9/storage/persistent_storage/persistent-storage-ocs.html)

---

![ODF 4.9 Installation Procedure](media/odf-operator.mp4)


- ODF Ceph tool pod
> $ oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
>
> $ oc -n openshift-storage get pod -l "app=rook-ceph-tools"
>
> $ TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
>
> $ oc rsh -n openshift-storage $TOOLS_POD 
