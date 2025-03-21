
STARTS HERE!

----
#### - Pre-checks

- If the output from the preceding command is empty NOT empty {}, like in the example below, then teh setting is fine, otherwise the cluster is affected and it must configure the registry to use storage.
```bash
$ oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.storage}{"\n"}'
```
... 
```text
{"managementState":"Managed","s3":{"bucket":"ds-qtx5l-image-registry-eu-west-1-jpoyujajdfxtbqqqheboqnrfrhbn","encrypt":true,"region":"eu-west-1","trustedCA":{"name":""},"virtualHostedStyle":false}}
```

- Verify your cluster has the OpenShift Driver toolkit

```bash
$ oc get -n openshift is/driver-toolkit
```
...

```text
NAME             IMAGE REPOSITORY                                                            TAGS                           UPDATED
driver-toolkit   image-registry.openshift-image-registry.svc:5000/openshift/driver-toolkit   417.94.202501071621-0,latest   55 minutes ago
```

----

#### - Installing the Node Feature Discovery Operator
- In the GUI

  - In the OpenShift Container Platform web console, click **Operators > OperatorHub**
  - Choose **Node Feature Discovery** from the list of available Operators, and then click **Install**
  - On the **Install Operator** page, select **A specific namespace on the cluster**, and then click **Install**. You do not need to create a namespace because it is created for you.

- Verify that the Node Feature Discovery Operator is functioning correctly. The Node Feature Discovery Operator uses vendor PCI IDs to identify hardware in a node. NVIDIA uses the **PCI ID 10de**.

```bash
$ oc describe $NODE | grep -iE 'Roles|pci' | grep -v master
```

```text
Roles:              worker
                    feature.node.kubernetes.io/pci-10de.present=true
                    feature.node.kubernetes.io/pci-1d0f.present=true
Roles:              worker
                    feature.node.kubernetes.io/pci-1013.present=true
                    feature.node.kubernetes.io/pci-8086.present=true
```