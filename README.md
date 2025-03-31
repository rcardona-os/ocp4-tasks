

### COMPILATION OF OPENSHIFT CLUSTER TASKS

update
=======
#### ocp4-dr-ha


$ cat << EOF | oc create -f -
apiVersion: ramendr.openshift.io/v1alpha1
kind: DRPolicy
metadata:
  name: app-ha-drpolicy
spec:
  drClusters:
    - aws1
    - az2
  schedulingInterval: 1m
EOF
