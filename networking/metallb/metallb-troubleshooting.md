- check the pods of the speak, which is a deamonset, `daemonset.apps/speaker`
  > $ oc get pods -n metallb-system -o wide | grep speaker
  >

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - third-pool
  interfaces:
  - eno6.1234

- TBA