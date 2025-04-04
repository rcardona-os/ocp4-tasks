
STARTS HERE!

----
#### 0 - Pre-checks

- If the output from the preceding command is empty NOT empty {}, like in the example below, then the setting is fine, otherwise the cluster is affected and it must configure the registry to use storage.
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
  - On the **Install Operator** page, all default will work for the installation. There is no need to create a namespace for the operator.
  - Create the NodeFeatureDiscovery instance in the Node Feature Discovery Operator page.

- Verify that the Node Feature Discovery Operator is functioning correctly. The Node Feature Discovery Operator uses vendor PCI IDs to identify hardware in a node. NVIDIA uses the **PCI ID 10de**.

```bash
$ for node in $(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[*].metadata.name}')
do
  echo "Node: $node"
  oc describe node "$node" | grep -iE 'roles|pci'
done

```

The output should be as follows:

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

- Create the ClusterPolicy (in case it did not happen on operator installation). If you install the NVIDIA GPU Operator using OperatorHub (via the OpenShift Web Console) and choose the "Automatic" install strategy, then the Operator will install itself. If it fails to happen create it manually. 

A **ClusterPolicy** is a Custom Resource Definition (CRD) that acts as a high-level configuration controller for deploying and managing NVIDIA GPU components in an OpenShift or Kubernetes cluster. It defines how the NVIDIA GPU Operator should deploy its stack, including:

   - Drivers (for GPU hardware support)
   - Container runtime (NVIDIA Container Toolkit for GPU-accelerated containers)
   - Device plugins (to expose GPUs to workloads)
   - Monitoring tools (DCGM, DCGM Exporter)
   - Feature discovery (GPU detection and labeling)

- To create a ClusterPolicy follow the steps:

   - In the OpenShift Container Platform web console, from the side menu, select Operators > Installed Operators, and click NVIDIA GPU Operator.

   - Select the ClusterPolicy tab, then click Create ClusterPolicy. The platform assigns the default name gpu-cluster-policy. The default are sufficient to get the GPU configured and running.

   - Click Create. This step might take 5-10 minutes depending on the network latency and cluster resoruces.

   - The status of the newly deployed ClusterPolicy *gpu-cluster-policy* for the NVIDIA GPU Operator changes to **State:ready** when the installation succeeds.

$`\textcolor{red}{\text{NOTE: These steps differ when using NVIDIA vGPU}}`$

#### 3 - Run GPU test pod

```bash
$ oc new-project test-gpu
```

```bash
$ cat << EOF | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
 restartPolicy: OnFailure
 containers:
 - name: cuda-vectoradd
   image: "nvidia/samples:vectoradd-cuda11.2.1"
   resources:
     limits:
       nvidia.com/gpu: 1
EOF
```

```bash
$ oc logs cuda-vectoradd
```

The output should be as follows:

```text
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
````

#### 4 - Getting information about the GPU device

```bash
$ oc project nvidia-gpu-operator && \
POD_NAME=$(oc get pod -o name -l openshift.driver-toolkit=true | grep nvidia-driver-daemonset | head -n 1) && \
oc exec -it $POD_NAME -- nvidia-smi
```

The output should be as follows:

```text
Now using project "nvidia-gpu-operator" on server "https://api.ds.sandbox2905.opentlc.com:6443".
Fri Mar 21 14:49:22 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.144.03             Driver Version: 550.144.03     CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA A10G                    On  |   00000000:00:1E.0 Off |                    0 |
|  0%   21C    P8             23W /  300W |       1MiB /  23028MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
```