# OpenShift Monitoring Introduction

OpenShift Container Platform includes a pre-configured, pre-installed, and self-updating monitoring stack that is based on the Prometheus open source project and its wider eco-system. Accessing the Alerting UI in the Administrator and Developer perspectives

The Alerting UI is accessible through the Administrator perspective and the Developer perspective in the OpenShift Container Platform web console.

  - In the Administrator perspective, select Observe → Alerting. The three main pages in the Alerting UI in this perspective are the Alerts, Silences, and Alerting Rules pages.

  - In the Developer perspective, select Observe → <project_name> → Alerts. In this perspective, alerts, silences, and alerting rules are all managed from the Alerts page. The results shown in the Alerts page are specific to the selected project.



### 0 - First login to the OpenShift Web Console with the kubeadmin credentials
> $ oc get routes -A | grep console
>

![`Web Console Login`](media/monitoring-0.png)

### 1 - Examine Alerting Configuration

On the left hand side, click on the __*Observe*__ > __*Alerting*__ drop down.

![`Alerting View`](media/monitoring-1.png)

The Alerting tab shows you information about currently configured and/or active alerts. You can see and do several things:

- Filter alerts by their names.

- Filter the alerts by their states. To fire, some alerts need a certain condition to be true for the duration of a timeout. If a condition of an alert is currently true, but the timeout has not been reached, such an alert is in the Pending state.

- Alert name.

- Description of an alert.

- Current state of the alert and when the alert went into this state.

- Value of the Severity label of the alert.

- Actions you can do with the alert.

### 2 - Examine Metrics UI (Prometheus Console)

In addition to the Alerting screen, OpenShift’s built-in monitoring provides an interface to access metrics collected by Prometheus using the Prometheus Query Language (PromQL).

On the left hand side of the OpenShift Console, under the __*Observe*__ > __*Metrics*__ section, click the link for "Metrics".

Let’s run a query to see the resources memory limit all pod definitions have defined.
>  instance:node_cpu_utilisation:rate1m
>

![`Alerting View 0`](media/monitoring-2.png)

Click the "Run Queries" button

You should now see a timeseries with a value in the list. This value is the latest gathered value for the timeseries as defined by this query. It plots a graph showing the value over the last time period (defaults to 30m).

Now let’s run a query to see the cpu usage for the entire cluster, and click the "Run Queries" button
> instance:node_cpu_utilisation:rate1m{instance="ip-10-0-193-144.eu-west-1.compute.internal"}
>
> node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes*100<50
>
> 


It should be possible to see a timeseries with a value in the list. This value is the latest gathered value for the timeseries as defined by this query. The new query will get plotted on the same graph.

![`Alerting View 1`](media/monitoring-3.png)



---

