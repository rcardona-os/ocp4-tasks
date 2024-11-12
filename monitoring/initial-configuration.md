# Initial Configuration of Openshift Cluster Monitoring

Default OpenShift Container Platform metrics for user-defined projects provide information about CPU and memory usage, bandwidth statistics, and packet rate information. Those metrics cannot be included in an alerting rule if you route the rule directly to the Prometheus instance in the openshift-user-workload-monitoring project. Alerting rule optimization should be used only if you have read the documentation and have a comprehensive understanding of the monitoring architecture. Detailed documentation [HERE](https://docs.openshift.com/container-platform/4.12/monitoring/enabling-monitoring-for-user-defined-projects.html)

### 0 - Prerequisites
  - Access to the cluster as a user with the cluster-admin role
  - Create the cluster-monitoring-config ConfigMap object

### 1 - Create cluster-monitoring-config ConfigMap object

    echo -n 'apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cluster-monitoring-config
      namespace: openshift-monitoring
    data:
      config.yaml: |' | tee 0.0-cluster-monitoring-config.yaml

 > $ oc apply -f 0.0-cluster-monitoring-config.yaml
 >

---

### 2 - (optional) Create cluster-monitoring-config ConfigMap object for user projects

    echo -n 'apiVersion: v1
    kind: ConfigMap
    metadata:
      name: cluster-monitoring-config
      namespace: openshift-monitoring
    data:
      config.yaml: |
        enableUserWorkload: true' | tee 0.1-cluster-monitoring-config.yaml

 > $ oc apply -f 0.1-cluster-monitoring-config.yaml
 >

---

    echo -n 'apiVersion: v1
    kind: ConfigMap
    metadata:
      name: user-workload-monitoring-config
      namespace: openshift-user-workload-monitoring
    data:
      config.yaml: |' | tee 0.1-user-workload-monitoring-config.yaml

  > $ oc apply -f 0.2-user-workload-monitoring-config.yaml
  >

  - check that the prometheus-operator, prometheus-user-workload and thanos-ruler-user-workload pods are running in the openshift-user-workload-monitoring project
  > $ oc get pod -n openshift-monitoring
  >
  > $ oc get pod -n openshift-user-workload-monitoring
  >

 