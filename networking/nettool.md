### Option A - running directly in Openshift Cluster Platform
  ```shell
  oc new-project test-networking
  ```
  ```shell
  oc create deployment nettool --image=quay.io/rcardona/nettool:latest
  ```

### Option B - create container image from scratch

##### B.1 - create it locally with podman
  - create the nginx Dockerfile
    ```text
    echo -e 'FROM registry.access.redhat.com/ubi8/ubi
    RUN dnf install -y python3 bind-utils net-tools iproute vim telnet nmap-ncat nmap iputils ethtool; dnf clean all
    CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"' | tee Dockerfile
    ```

  - build simple nginx container image
    ```shell
    podman build . -t nettool
    ```

  ##### B.2 - run it in OpenShift Cluster Platform
  - locate the ocp cluster internal registry, and login to it
    ```shell
    podman login -u $(oc whoami) -p $(oc whoami -t) \
    $(oc -n openshift-image-registry get route default-route -o jsonpath='{.spec.host}') \
    --tls-verify=false
    ```

  - make sure that the default route is enabled
    ```shell
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    ```  

  - give the image a proper tag in order to match the target registry. Here bellow `openshift` is the target project to make the image available to all project
    ```shell
    podman tag localhost/simple-nginx \
    $(oc -n openshift-image-registry get route default-route -o jsonpath='{.spec.host}')/openshift/nettool
    ```

  - push image to OCP registry
    ```shell
    podman push \
    $(oc -n openshift-image-registry get route default-route -o jsonpath='{.spec.host}')/openshift/nettool \
    --tls-verify=false
    ```

  - fine the exact name for the image in the internal registry
    ```shell
    oc get images | grep -i nettool
    ```

  - run the application
    ```shell
    oc new-app openshift/nettool
    ```


---


### deploy the nettol pod with secondary interfaces
```bash
echo -n 'apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nettool
  name: nettool
spec:
  selector:
    matchLabels:
      app: nettool
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: network-1
      labels:
        app: nettool
    spec:
      containers:
      - image: quay.io/rcardona/nettool:latest
        name: nettool' | tee nettool-deployment.yaml
```

```bash
oc apply -f nettool-deployment.yaml
```