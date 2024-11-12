oc get pods -n openshift-local-storage

oc get localvolumes -n openshift-local-storage 

oc get localvolumesets -n openshift-local-storage

oc get sc

oc get pv

oc debug node/${NODE} -- chroot /host ls -ltr /mnt/local-storage