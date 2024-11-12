# Configuring Additional Openshift Networks

As a cluster administrator, you can configure an additional network for your cluster. The following network types are supported:

   - [Bridge](https://docs.openshift.com/container-platform/4.13/networking/multiple_networks/configuring-additional-network.html#nw-multus-bridge-object_configuring-additional-network)

   - [Host device](https://docs.openshift.com/container-platform/4.13/networking/multiple_networks/configuring-additional-network.html#nw-multus-host-device-object_configuring-additional-network)

   - [IPVLAN](https://docs.openshift.com/container-platform/4.13/networking/multiple_networks/configuring-additional-network.html#nw-multus-ipvlan-object_configuring-additional-network)

   - [MACVLAN](https://docs.openshift.com/container-platform/4.13/networking/multiple_networks/configuring-additional-network.html#nw-multus-macvlan-object_configuring-additional-network)

   - [OVN-Kubernetes](https://docs.openshift.com/container-platform/4.13/networking/multiple_networks/configuring-additional-network.html#configuration-ovnk-additional-networks_configuring-additional-network)

---
- prerequisites

  - [x] [NMstate Operator should be installed](https://docs.openshift.com/container-platform/4.13/networking/k8s_nmstate/k8s-nmstate-about-the-k8s-nmstate-operator.html)

---

- this step is common to all configuiration cases, which consists on finding the active connected interfaces on the worker nodes with the following command
  ```bash
  for NODE in `oc get nodes -l node-role.kubernetes.io/worker -o name`
  do 
  echo "==========================="
  echo "Node: " $NODE
  echo "==========================="
  oc debug $NODE -- chroot /host nmcli d s | grep -i connected
  done
  ```
 
##### CASE A: configuring secondary kubernentes network with {+linux bridge type+} 

- configuring the __NodeNetworkConfigurationPolicy__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/node-network-configuration-policy-bridge.yaml):
  ```bash
  echo -n 'apiVersion: nmstate.io/v1
  kind: NodeNetworkConfigurationPolicy
  metadata:
    name: linux-br1
  spec:
    nodeSelector:
      node-role.kubernetes.io/worker: ""
    desiredState:
      interfaces:
        - name: linux-br1
          description: Linux bridge with enp3s0 as a port
          type: linux-bridge
          state: up
          ipv4:
            dhcp: false
            enabled: false
          bridge:
            options:
              stp:
                enabled: false
            port:
              - name: enp3s0' | tee node-network-configuration-policy-bridge.yaml
  ```

- create the NodeNetworkConfigurationPolicy object
  ```bash
  oc apply -f node-network-configuration-policy-bridge.yaml
  ```
    
- create __NetworkAttachmentDefinition__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/network-attachtment-definition-bridge.yaml):
  ```bash
  echo -n "apiVersion: k8s.cni.cncf.io/v1
  kind: NetworkAttachmentDefinition
  metadata:
    annotations:
      k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/linux-br1
    name: network-1
  spec:
    config: '{ 
      \"cniVersion\": \"0.3.1\",
      \"name\": \"network-1\",
      \"type\": \"bridge\",
      \"isGateway\": true,
      \"ipam\":{
        \"type\": \"whereabouts\",
        \"range\": \"192.168.1.0/24\"
       }
    }'" | tee network-attachtment-definition-bridge.yaml
  ```
- create NAD
  ```bash
  oc apply -f network-attachtment-definition-bridge.yaml
  ```

---

#### Case B: configuring secondary kubernentes network with {+linux bridge type with vlan tag+} 

- configuring the __NodeNetworkConfigurationPolicy__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/node-network-configuration-policy-bridge-vlan.yaml):
  ```bash
  echo -n "apiVersion: nmstate.io/v1
  kind: NodeNetworkConfigurationPolicy
  metadata:
    name: vlan102-br
  spec:
    nodeSelector:
      node-role.kubernetes.io/worker: ""
    desiredState:
      interfaces:
        - name: vlan102-br
          description: Linux bridge with enp3s0 as a port
          type: linux-bridge
          state: up
          ipv4:
            dhcp: false
            enabled: false
          bridge:
            options:
              stp:
                enabled: false
            port:
              - name: enp3s0" | tee node-network-configuration-policy-bridge-vlan.yaml
  ```
- create the NodeNetworkConfigurationPolicy object
  ```bash
  oc apply -f node-network-configuration-policy-bridge-vlan.yaml
  ```
    
- create __NetworkAttachmentDefinition__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/network-attachtment-definition-bridge-vlan.yaml):
  ``` bash
  echo -n "apiVersion: k8s.cni.cncf.io/v1
  kind: NetworkAttachmentDefinition
  metadata:
    annotations:
      k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/vlan102-br
    name: network-vlan102
  spec:
    config: '{
        \"name\": \"network-vlan102\",
        \"type\": \"cnv-bridge\",
        \"cniVersion\": \"0.3.1\",
        \"bridge\": \"vlan102-br\",
        \"macspoofchk\": true,
        \"vlan\": 102,
        \"ipam\":{}
      }'" | tee network-attachtment-definition-bridge-vlan.yaml
  ```
- create NAD
  ```bash
  oc apply -f network-attachtment-definition-bridge-vlan.yaml
  ```

---

#### CASE C: configuring secondary kubernentes network with {+host device type+} 

- configuring the __NodeNetworkConfigurationPolicy__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/node-network-configuration-policy-host-device.yaml):
  ```bash
  echo -n 'apiVersion: nmstate.io/v1
  kind: NodeNetworkConfigurationPolicy
  metadata:
    name: my-bridge
  spec:
    nodeSelector:
      node-role.kubernetes.io/worker: ""
    desiredState:
      interfaces:
        - name: my-bridge
          description: Linux bridge with enp3s0 as a port
          type: linux-bridge
          state: up
          ipv4:
            dhcp: false
            enabled: false
          bridge:
            options:
              stp:
                enabled: false
            port:
              - name: enp3s0' | tee node-network-configuration-policy-host-device.yaml
    ```   

- create the NodeNetworkConfigurationPolicy object
  ```shell
  oc apply -f node-network-configuration-policy-host-device.yaml
  ```
    
- create __NetworkAttachmentDefinition__, example [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/networking/network-attachtment-definition-host-device.yaml):
  ```bash
  echo -n "apiVersion: k8s.cni.cncf.io/v1
  kind: NetworkAttachmentDefinition
  metadata:
    annotations:
      k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/my-bridge
    name: mynetwork
  spec:
    config: '{
        \"name\": \"mynetwork\",
        \"type\": \"cnv-bridge\",
        \"cniVersion\": \"0.3.1\",
        \"bridge\": \"my-bridge\",
        \"macspoofchk\": true,
        \"ipam\": {}
      }'" | tee network-attachtment-definition-bridge.yaml
  ```

- create NAD
  ```shell
  oc apply -f network-attachtment-definition-host-device.yaml
  ```

#### example of dynamic ipam

- linux bridge
  ```yaml
  config: '{
  "cniVersion": "0.3.1",
  "name": "work-network",
  "type": "bridge",
  "isGateway": true,
  "vlan": 2,
  "ipam": {
    "type": "dhcp"
    }
  }'
  ```

- linux bridge with static IP assigment
  ```yaml
  config: '{
  "cniVersion": "0.3.1",
  "name": "work-network",
  "type": "bridge",
  "isGateway": true,
  "vlan": 2,
  "ipam": {
    "type": "static",
      "addresses": [
        {
          "address": "191.168.1.10/24"
        }
      ]
    }
  }'
  ```

- macvlan
  ```yaml
  config: '{
   "cniVersion": "0.3.1",
   "type": "macvlan",
   "master": "ens2",
   "mode": "bridge",
   "ipam": {
         "type": "whereabouts",
         "range": "192.168.1.0/24"
    }
  }'
  ```

- specific configutaion NDAs to be user for Openshift Virtualization
  ```yaml
  config: '{
    "cniVersion": "0.3.1",
    "name": "groot",
    "plugins": [
      {
        "type": "cnv-bridge",
        "bridge": "br1"
      },
      {
        "type": "tuning"
      }
    ]
  }'
  ```


#### troubleshooting
 - finding interfaces
   ```shell
   oc get nns/ocp4-worker1.aio.example.com -o json |jq .status.currentState.interfaces[].name
   ```
   
 - find interface types
   ```shell
   oc get nns/ocp4-worker1.aio.example.com -o json |jq .status.currentState.interfaces[].type
   ```

 - find ipv4 addresses
   ```shell
   oc get nns/ocp4-worker1.aio.example.com -o json |jq .status.currentState.interfaces[].ipv4.address
   ```

 - check oc get Nodenetwork Configuration Enactments
   ```shell
   oc get nnce -A
   ```

   

 ---