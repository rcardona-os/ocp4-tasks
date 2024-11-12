openshift-kube-apiserver 

openshift-ingress-operator





oc get -o json cm kube-root-ca.crt -n  openshift-kube-apiserver | jq -r '.data'


oc get -o json cm kube-root-ca.crt -n  openshift-ingress-operator | jq -r '.data'
---

