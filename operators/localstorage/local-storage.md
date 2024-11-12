- label nodes to use as OCS nodes

> oc label node ip-10-0-219-8.eu-west-2.compute.internal cluster.ocs.openshift.io/openshift-storage=''
>

- create deamonset disk-gatherer

> oc apply -f https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/operators/localstorage/list-local-disks-app.yaml
>
