- Important to mention that the following infrastructure workloads do not incur OpenShift Container Platform worker subscriptions:

  - Kubernetes and OpenShift Container Platform control plane services that run on masters
  - The default router
  - The integrated container image registry
  - The cluster metrics collection, or monitoring service, including components for monitoring user-defined projects
  - Cluster aggregated logging
  - Service brokers
  - Red Hat Quay
  - Red Hat OpenShift Container Storage
  - Red Hat Advanced Cluster Manager

Red Hat documentation about creating a machineSet [HERE](https://docs.openshift.com/container-platform/4.7/machine_management/creating-infrastructure-machinesets.html)

---

- 1. Create the machienSet(s) on each Availability Zone. The below example has tested in the context of an OCP cluster running on AWS, however the steps will not differ greatly with other public cloud platforms.

  - 1.1. Editing the machineSet(s)

    > oc get machinesets.machine.openshift.io -A
    >

    > oc get -o yaml machinesets.machine.openshift.io aws-managed1-zfwnn-worker-eu-west-2a -n openshift-machine-api > aws-managed1-zfwnn-worker-eu-west-2a.yaml

    > vim aws-managed1-zfwnn-worker-eu-west-2a.yaml
    >

    - [HERE](https://gitlab.com/rcardona/ocp4-tasks/-/blob/master/infra-nodes/machineSetInfra.yaml) There is an example of a complete (minimal) machineSet definition file. Take in account the variable **${INFRA}** should be updated with the **"infra"** label.

  - 1.2. Create the machineSet(s)
    > oc apply -f aws-managed1-zfwnn-worker-eu-west-2a.yaml
    >

  - 1.3. Scale out the infra nodes to the desired number of nodes
    > oc scale machinesets.machine.openshift.io aws-managed1-zfwnn-infra-eu-west-2a --replicas 1 -n openshift-machine-api
    >

---

- 2. Binding infrastructure node workloads using tolerations, as taints has been set already on the infra workers in the previous step.

  - 2.1. Add tolerations for the pod configurations you want to schedule on the infra node, like router, registry, and monitoring workloads. Add the following code to the Pod object specification. The proper way to configure this is by updating the operator controllers (e.g step 2.2 for router).

        tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/infra
          operator: Exists

  - 2.2. Moving the **router** component to the infra worker nodes

    - 2.2.1. Edit the ingresscontroller resource and change the nodeSelector to use the infra label
      > oc edit ingresscontroller default -n openshift-ingress-operator
      >

    - 2.2.2. Add the nodeSelector stanza that references the infra label to the spec section

          spec:
            nodePlacement:
              nodeSelector:
                matchLabels:
                  node-role.kubernetes.io/infra: ""
              tolerations:
              - effect: NoSchedule
                key: node-role.kubernetes.io/infra
                operator: Exists

    - 2.2.3. Confirm that the router pod is running on the infra node
      > oc get pod -n openshift-ingress -o wide
      >

  - 2.3. Moving the **default registry**

    - 2.3.1. Edit the config/instance object
      > oc edit configs.imageregistry.operator.openshift.io/cluster
      >

    - 2.3.2. Add the following lines of text the spec section of the object

          spec:
            nodeSelector:
              node-role.kubernetes.io/infra: ""
            tolerations:
            - effect: NoSchedule
              key: node-role.kubernetes.io/infra
              operator: Exists

    - 2.3.3. Verify the registry pod has been moved to the infrastructure node
      > oc get pods -o wide -n openshift-image-registry
      >

  - 2.4. Moving the **monitoring** component

    - 2.4.1. Create the ConfigMap definition as the cluster-monitoring-configmap.yaml
      > oc apply -f https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/infra-nodes/cluster-monitoring-configmap.yaml
      >

    - 2.4.2. Watch the monitoring pods move to the new machines
      > watch 'oc get pod -n openshift-monitoring -o wide'
      >

    - 2.4.3. If a component has not moved to the infra node, delete the pod in order to be recreated
      > oc delete pod -n openshift-monitoring <pod>
      >

  - 2.5. Moving OpenShift Logging component

    - 2.5.1. Edit the ClusterLogging custom resource (CR) in the openshift-logging project
      > oc edit ClusterLogging instance
      >

      ![example](media/cluster-logging.png)

      * Add a nodeSelector parameter with the appropriate value to the component you want to move. You can use a nodeSelector in the format shown.

          nodeSelector:
            matchLabels:
              node-role.kubernetes.io/infra: ""
          tolerations:
          - effect: NoSchedule
            key: node-role.kubernetes.io/infra
            operator: Exists

  - 2.6. Enable openshift-dns daemonset to toleration to run on nodes with taints

        $ oc edit dns.operator/default

        apiVersion: operator.openshift.io/v1
        kind: DNS
        metadata:
          name: default
        spec:
          nodePlacement:
            tolerations:
            - operator: Exists

    - confirming ds deployment
      > oc -n openshift-dns get ds
      >

---

- 3. Watch the OpenShift Logging pods move to the new machines
    > watch 'oc get pod -n openshift-logging -o wide'
    >

---

- 4. If a component has not moved to the infra node, delete the pod in order to be recreated
    > oc delete pod -n openshift-logging <pod>
    >


---
