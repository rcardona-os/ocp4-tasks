#### - pre-checks

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

#### - installing the Node Feature Discovery Operator
- In the GUI

  - In the OpenShift Container Platform web console, click **Operators > OperatorHub**
  - Choose **Node Feature Discovery** from the list of available Operators, and then click **Install**
  - On the **Install Operator** page, select **A specific namespace on the cluster**, and then click **Install**. You do not need to create a namespace because it is created for you.

- Verification

  - Navigate to the **Operators > Installed Operators** page
  - Ensure that **Node Feature Discovery** is listed in the **openshift-nfd** project with a **Status** of **InstallSucceeded**