## Mixed Architecture Deployment

Use case, virtual infrastructure for control plane and infra workers, and OCP AI workers on baremetal

#### 1. Step 1: Create the Bare-Metal Pool 

- Create a file named mcp-baremetal.yaml with the following content

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: baremetal
spec:
  machineConfigSelector:
    matchExpressions:
      - key: machineconfiguration.openshift.io/role
        operator: In
        values:
          - worker
          - baremetal
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/baremetal: ""
```

- Apply the file to the cluster

```bash
oc apply -f mcp-baremetal.yaml
```

#### 2. Remove the VMware Cloud Provider

Next, create the actual configuration that stops the bare-metal nodes from looking for vCenter. This injects a systemd drop-in to clear the cloud-provider arguments from the kubelet.

- Create a file named mc-no-cloud-provider.yaml with the following content
```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: baremetal
  name: 99-baremetal-no-cloud-provider
spec:
  config:
    ignition:
      version: 3.2.0
    systemd:
      units:
      - name: kubelet.service
        dropins:
        - name: 20-no-cloud-provider.conf
          contents: |
            [Service]
            Environment="KUBELET_CLOUDPROVIDER_ARGS="
```

- Apply the file to the cluster
```bash
oc apply -f mc-no-cloud-provider.yaml
```

#### 3. Extract the Ignition File

Now the bare-metal nodes need an Ignition file to know how to join the cluster. Since the cluster is already running, go ahead and pull the most up-to-date worker config directly from the internal secrets.

- Extract the worker.ign file
```bash
oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=- > worker.ign
```

- Apply the file to the cluster
```bash
oc apply -f mc-no-cloud-provider.yaml
```

- Host this **worker.ign** file on an internal web server (e.g., Apache, Nginx) that your physical servers can reach via HTTP or HTTPS during their boot process.

#### 4. Boot the Bare-Metal Servers

Now turn on your physical hardware.

1. Boot the servers using the Red Hat Enterprise Linux CoreOS (RHCOS) ISO or PXE image that matches your exact OpenShift version.

2. At the boot prompt, interrupt the process (hit TAB or e depending on the bootloader).

3. Append the kernel arguments to point to your disk and your hosted Ignition file. It will look something like this:

```text
coreos.inst.install_dev=/dev/sda coreos.inst.ignition_url=http://<your-web-server>/worker.ign
```

4. Hit Enter/Ctrl+X to boot. The server will download the ignition, write to the disk, and reboot automatically.

#### 5. Approve the Certificates (CSRs)
When the bare-metal servers boot up, they will attempt to contact the OpenShift API, but they are blocked for security reasons until you approve them.

- List the pending Certificate Signing Requests
```bash
oc get csr
```

- Approve all pending CSRs using this command:
```bash
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
``` 

#### 6. Apply the Critical Label
As soon as the CSRs are approved, at this stage the nodes will appear as NotReady when listed (oc get nodes) and will have the uninitialized VMware taint.

To address this immediately apply the label as follows. This triggers the Machine Config Operator (MCO) to push the cloud-provider fix to them.

```bash
oc label node <bare-metal-node-1> node-role.kubernetes.io/baremetal=
oc label node <bare-metal-node-2> node-role.kubernetes.io/baremetal=
oc label node <bare-metal-node-3> node-role.kubernetes.io/baremetal=
```

#### 7. Verification
Once the label is applied, OpenShift takes over.

The bare-metal nodes will automatically reboot to apply the custom MachineConfig. When they come back online, the VMware taint will be gone. They will transition to Ready status.

- Verify it with the following command:

```bash
oc get mcp baremetal
```