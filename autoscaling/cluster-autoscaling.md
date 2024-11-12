### 0 - Prerequisites

### 1 - ClusterAutoscaler resource definition

    echo -n 'apiVersion: "autoscaling.openshift.io/v1"
    kind: "ClusterAutoscaler"
    metadata:
      name: "default"
    spec:
      podPriorityThreshold: -10
      resourceLimits:
        maxNodesTotal: 20
        cores:
          min: 8
          max: 128
        memory:
          min: 4
          max: 300
      logVerbosity: 4
      scaleDown: 
        enabled: true 
        delayAfterAdd: 10s
        delayAfterDelete: 10s 
        delayAfterFailure: 10s 
        unneededTime: 5m' | tee cluster-autoscaler.yaml

> $ on apply -f cluster-autoscaler.yaml
>

### 2 - MachineAutoscaler resource definition

    echo -n 'apiVersion: "autoscaling.openshift.io/v1beta1"
    kind: "MachineAutoscaler"
    metadata:
      name: "worker-us-east-1a" 
      namespace: "openshift-machine-api"
    spec:
      minReplicas: 0
      maxReplicas: 3
      scaleTargetRef:
        apiVersion: machine.openshift.io/v1beta1
        kind: MachineSet
        name: worker-us-east-1a' | tee machine-autoscaler.yaml

  > oc apply -f machine-autoscaler.yaml
  >

### 3 - Test application to stress the Openshift Cluster

    echo -n 'apiVersion: batch/v1
    kind: Job
    metadata:
      generateName: work-queue-
    spec:
      template:
        spec:
          containers:
          - name: work
            image: busybox
            command: ["sleep",  "300"]
            resources:
              requests:
                memory: 500Mi
                cpu: 500m
          restartPolicy: Never
      backoffLimit: 4
      completions: 50
      parallelism: 50' | tee job-stress-app.yaml

   > $ oc apply -f job-stress-app.yaml
   >

### 4 - Monitoring the autoscaling

  - listing machine
  > $ watch -n1 'oc get nodes; echo; oc get machines -A'
  >

  - list machinesets resources usage
  > $ watch -n1 'oc get machineset -A; echo "Resource Usage: "; echo; oc adm top nodes'
  >
