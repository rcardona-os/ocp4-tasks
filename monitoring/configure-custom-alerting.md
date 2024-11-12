# Configure Custom Monitoring Alert

- Prerequisites for this lab

- Configure htpasswd identity provider [HERE](identity-management/htpasswd/configuring-identity-provider.md)

#### 0 - Create cluster-monitoring-config ConfigMap object for user projects
```bash
echo -n 'apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true' | tee 0.1-cluster-monitoring-config.yaml
```
```shell
oc apply -f 0.1-cluster-monitoring-config.yaml
```

---

```bash
echo -n 'apiVersion: v1
kind: ConfigMap
metadata:
  name: user-workload-monitoring-config
  namespace: openshift-user-workload-monitoring
data:
  config.yaml: |' | tee 0.2-user-workload-monitoring-config.yaml
```
```shell
oc apply -f 0.2-user-workload-monitoring-config.yaml
```

- check that the prometheus-operator, prometheus-user-workload and thanos-ruler-user-workload pods are running in the openshift-user-workload-monitoring project
```shell
oc get pod -n openshift-monitoring
```
```shell
oc get pod -n openshift-user-workload-monitoring
```

#### 1 - Deploy the application with a non privilege user (ex. dev1)

```shell
oc login --token=sha256~jsAqbvJQiwmY1dV5XUMVKjse3452DPq9ZQHH6-jiFw --server=https://api.ocp4.sandbox2278.opentlc.com:6443
```

```bash
echo -n 'apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: ns1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: prometheus-example-app
  name: prometheus-example-app
  namespace: ns1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus-example-app
  template:
    metadata:
      labels:
        app: prometheus-example-app
    spec:
      containers:
      - image: ghcr.io/rhobs/prometheus-example-app:0.4.1
        imagePullPolicy: IfNotPresent
        name: prometheus-example-app
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-example-app
  name: prometheus-example-app
  namespace: ns1
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
    name: web
  selector:
    app: prometheus-example-app
  type: ClusterIP' | tee prometheus-example-app.yaml
```
```shell
oc apply -f prometheus-example-app.yaml
```

#### 2 - Create ServiceMonitor

```bash
echo -n 'apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    k8s-app: prometheus-example-monitor
  name: prometheus-example-monitor
  namespace: ns1
spec:
  endpoints:
  - interval: 10s
    port: web
    scheme: http
  selector:
    matchLabels:
      app: prometheus-example-app' | tee example-app-service-monitor.yaml
```
```shell
oc apply -f example-app-service-monitor.yaml
```

#### 3 - Check the metrics in WebConsole

- Procedure
 - Select the __Developer perspective__ in the OpenShift Container Platform web console.
 - Select Observe → Metrics.
 - Select the project that you want to view metrics for in the Project: list.
 - Select a query from the Select query list, or create a custom PromQL query based on the selected query by selecting Show PromQL.

    __*Optional*__: Select Custom query from the Select query list to enter a new query. As you type, autocomplete suggestions appear in a drop-down list. These suggestions include functions and metrics. Click a suggested item to select it.

#### 4 - Create custom alert
```bash
echo -n 'apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-alert
  namespace: ns1
spec:
  groups:
  - name: example
    rules:
    - alert: HostMemoryIsUnderUtilized
      expr: 100 - (rate(node_memory_MemAvailable_bytes[30s]) / node_memory_MemTotal_bytes * 100) < 20
      for: 1m
      labels:
        severity: info
      annotations:
        summary: Host Memory is under utilized (instance {{ $labels.instance }})
        description: "Node memory is < 20% for 1 week. Consider reducing memory space.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"' | tee example-app-alerting-rule.yaml
```
```shell
oc apply -f example-app-alerting-rule.yaml
```

#### 5 - Configurating notification with email

- example of the default configuration of the alertmanager-main secret, [DOCS](https://docs.openshift.com/container-platform/4.12/monitoring/managing-alerts.html#managing-alerts). Other options to configure notification are; PagerDuty, Webhook, Email and Slack

      "global":
        "resolve_timeout": "5m"
        "smtp_smarthost": "utility.lab.example.com:25" (1) 
        "smtp_from": "alerts@ocp4.example.com" (2)
        "smtp_auth_username": "smtp_training" (3) 
        "smtp_auth_password": "Red_H4T@!" (4)
        "smtp_require_tls": false (5)
      "receivers":
      - "name": "email-notification" (6)
        "email_configs": (7)
          - "to": "ocp-admins@example.com" (8)
      - "name": "default"
      "route":
        "group_by":
        - "job"
        "group_interval": "5m"
        "group_wait": "30s"
        "receiver": "default"
        "repeat_interval": "12h"
        "routes":
        - "match":
            "alertname": "Watchdog"
          "receiver": "default"
        - "match":
            "severity": "critical"
          "receiver": "email-notification" (9)


   - (1) The global SMTP host. If you do not define smarthost in the email_configs field for a receiver, then this is the default host in use.
   - (2) The global email sender address. If you do not define from in the email_configs field for a receiver, then this is the default address in use.
   - (3) The global SMTP username for optional authentication. If you do not define auth_username in the email_configs field for a receiver, then this is the default username in use.
   - (4) The global SMTP password for optional authentication. This password is used if auth_password is not defined in the email_configs for a receiver. If you do not define auth_password in the email_configs field for a receiver, then this is the default password in use.
   - (5) A global setting specifying if TLS is required for SMTP. You can override this setting by using require_tls in the email_configs for a receiver.
   - (6) An arbitrary name for the receiver. A route specifies this receiver name for a match. 
   - (7) This setting indicates that the receiver sends alerts by email.
   - (8) The to setting must be specified under email_configs and does not have an equivalent global SMTP setting.
   - (9) The receiver to use if the match evaluates as true for the alert.

---
It is possible to access the __Observe > Metrics__ interface to execute *Prometheus Query Language (PromQL)* queries against an entire Red Hat OpenShift Virtualization environment. Use this tool to examine information about the cluster and user-defined workloads as a dashboard or a graph. Here sole PromQL queries for virtualization monitoring:

`kubevirt_vmi_vcpu_wait_seconds`
Returns the wait time (in seconds) for a VM's vCPU.

`kubevirt_vmi_network_receive_bytes_total`
Returns the total amount of traffic received (in bytes) on the VM's network.

`kubevirt_vmi_network_transmit_bytes_total`
Returns the total amount of traffic transmitted (in bytes) on the VM's network.

`kubevirt_vmi_storage_read_traffic_bytes_total`
Returns the total amount of storage read (in bytes) by the VM.

`kubevirt_vmi_storage_write_traffic_bytes_total`
Returns the total amount of storage writes (in bytes) of the VM's storage related traffic.

`kubevirt_vmi_storage_iops_read_total`
Returns the amount of read I/O operations the VM is performing per second.

`kubevirt_vmi_storage_iops_write_total`
Returns the amount of write I/O operations the VM is performing per second.

`kubevirt_vmi_memory_swap_in_traffic_bytes_total`
Returns the total amount (in bytes) of memory the virtual guest is swapping in.

`kubevirt_vmi_memory_swap_out_traffic_bytes_total`
Returns the total amount (in bytes) of memory the virtual guest is swapping out.

---

- View the results of a custom PromQL query for the testing-vms project as the developer user. Retrieve the vcpu wait metric from all virtual machines located in the testing- vms project. Execute the following query:

`topk(3, sum by (name, namespace) (rate(kubevirt_vmi_vcpu_wait_seconds[5m])))`