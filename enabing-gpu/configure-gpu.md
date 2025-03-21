
STARTS HERE!

----
#### 0 - Pre-checks

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

#### 1 - Installing the Node Feature Discovery Operator
- In the GUI, For additional [information](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator)

  - In the OpenShift Container Platform web console, click **Operators > OperatorHub**
  - Choose **Node Feature Discovery** from the list of available Operators, and then click **Install**
  - On the **Install Operator** page, select **A specific namespace on the cluster**, and then click **Install**. You do not need to create a namespace because it is created for you.

- Verify that the Node Feature Discovery Operator is functioning correctly. The Node Feature Discovery Operator uses vendor PCI IDs to identify hardware in a node. NVIDIA uses the **PCI ID 10de**.

```bash
$ for node in $(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[*].metadata.name}')
do
  echo " Node: $node"
  oc describe node "$node" | grep -iE 'roles|pci'
done

```

```text
Node: ip-10-0-43-106.eu-west-1.compute.internal
Roles:              worker
                    feature.node.kubernetes.io/pci-10de.present=true
                    feature.node.kubernetes.io/pci-1d0f.present=true
Node: ip-10-0-7-27.eu-west-1.compute.internal
Roles:              worker
                    feature.node.kubernetes.io/pci-10de.present=true
                    feature.node.kubernetes.io/pci-1d0f.present=true
Node: ip-10-0-85-102.eu-west-1.compute.internal
Roles:              worker
                    feature.node.kubernetes.io/pci-10de.present=true
                    feature.node.kubernetes.io/pci-1d0f.present=true
```

#### 2 - Installing the NVIDIA GPU Operator by using the web console
- In the OpenShift Container Platform web console from the side menu, navigate to **Operators > OperatorHub** and select **All Projects**.

- In **Operators > OperatorHub**, search for the **NVIDIA GPU Operator**. For additional [information](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/operators/administrator-tasks#olm-adding-operators-to-a-cluster)

- Select the NVIDIA GPU Operator, click Install. In the subsequent screen click Install.

💥 check 💥
When installing the NVIDIA GPU Operator, a custom resource definition for a ClusterPolicy is created. If a ClusterPolicy that contains an empty specification, such as spec{}, the ClusterPolicy fails to deploy. If there is the case, follow the below steps:

- In the OpenShift Container Platform web console, from the side menu, select Operators > Installed Operators, and click NVIDIA GPU Operator.

- Select the ClusterPolicy tab, then click Create ClusterPolicy. The platform assigns the default name gpu-cluster-policy. The default are sufficient to get the GPU configured and running.

- Click Create. This step might take 10-20 minutes depending on the network latency.

- The status of the newly deployed ClusterPolicy *gpu-cluster-policy* for the NVIDIA GPU Operator changes to **State:ready** when the installation succeeds.

$`\textcolor{red}{\text{NOTE: These steps differ when using NVIDIA vGPU}}`$