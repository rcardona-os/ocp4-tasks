#### Count All Pods
```bash
oc get pods --all-namespaces --no-headers | wc -l
```
#### Count Pods with JSON Output
```bash
oc get pods --all-namespaces -o json | jq '.items | length'
```

#### Count Deployments
```bash
oc get deployments --all-namespaces -o json | jq '.items | length'
```

#### Count Services
```bash
oc get services --all-namespaces -o json | jq '.items | length'
```

---
## Using etcdctl

#### List All Keys
```bash
etcdctl get --prefix "/" --keys-only
```

#### Count All Keys
```bash
etcdctl get --prefix "/" --keys-only | wc -l
```

---
## Checkig networking

#### Deploy iperf3 Server
```bash
oc run iperf-server --image=networkstatic/iperf3 --port=5201 --command -- iperf3 -s
```

#### Deploy iperf3 Client
```bash
oc run iperf-client --image=networkstatic/iperf3 --restart=Never --command -- iperf3 -c <iperf-server-IP>
```

#### Check Results
```bash
oc logs iperf-client
```

#### 
---
## Test Application
```bash
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
```

---
## Amount of resources

#### Count of pods per node (python)
```python
#!/usr/bin/env python3

import subprocess
import json
from collections import defaultdict

def get_oc_output(command):
    """Run an oc command and return the output as a string."""
    result = subprocess.run(command.split(), check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.stdout.decode('utf-8')

def main():
    # Check if oc command is available
    try:
        subprocess.run(["oc", "version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError:
        print("oc command not found. Please ensure you have the OpenShift CLI installed and configured.")
        return

    # Get list of nodes
    nodes_output = get_oc_output("oc get nodes -o json")
    nodes = [node['metadata']['name'] for node in json.loads(nodes_output)['items']]

    # Initialize a dictionary to store pod counts
    pod_count = defaultdict(int)

    # Get list of running pods and their nodes
    pods_output = get_oc_output("oc get pods --all-namespaces -o json")
    pods = json.loads(pods_output)['items']

    for pod in pods:
        if pod['status']['phase'] == 'Running':
            node_name = pod['spec'].get('nodeName')
            if node_name:
                pod_count[node_name] += 1

    # Print the results
    print("Running Pods Per Node:")
    for node in nodes:
        print(f"{node}: {pod_count[node]}")

if __name__ == "__main__":
    main()
```

#### Count of pods per node (bash)
```bash
#!/bin/bash

# Check if oc command is available
if ! command -v oc &> /dev/null; then
    echo "oc command not found. Please ensure you have the OpenShift CLI installed and configured."
    exit 1
fi

# Get list of nodes
nodes=$(oc get nodes -o jsonpath="{.items[*].metadata.name}")

# Initialize an associative array to store pod counts
declare -A pod_count

# Initialize pod counts to zero
for node in $nodes; do
    pod_count[$node]=0
done

# Get list of running pods and their nodes
pods=$(oc get pods --all-namespaces -o jsonpath="{range .items[?(@.status.phase=='Running')]}{.spec.nodeName}{"\n"}{end}")

# Count running pods per node
while read -r node; do
    if [[ -n "$node" ]]; then
        ((pod_count[$node]++))
    fi
done <<< "$pods"

# Print the results
echo "Running Pods Per Node:"
for node in "${!pod_count[@]}"; do
    echo "$node: ${pod_count[$node]}"
done
```