## Steps to create a non-privilege *developer* user with HTPasswd identity provider

By default, only the kubeadmin user exists on your cluster. To specify an identity provider, you must create a Custom Resource (CR) that describes that identity provider and add it to the cluster.

*Steps*

- 1 - Create or update your flat file *users.htpasswd* with a user name *developer* and hashed password *developer*
  ```bash
  htpasswd -c -B -b users.htpasswd developer developer
  ```

- 2 - Create an OpenShift Container Platform Secret that contains the HTPasswd users file
  ```bash
  oc create secret generic htpasswd-secret --from-file=htpasswd=./users.htpasswd -n openshift-config
  ```

- 3 - Adding an identity provider to your clusters by updating the Custom Resource (CR) shows the parameters and acceptable values for an HTPasswd identity
  ```bash
  oc edit oauths cluster
  ```

   It should looks like this, ensure that the *fileData* file points to the right secret name

  ```yaml
  apiVersion: config.openshift.io/v1
  kind: OAuth
  metadata:
    name: cluster
  spec:
    identityProviders:
    - name: local
      mappingMethod: claim
      type: HTPasswd
      htpasswd:
        fileData:
          name: htpasswd-secret

  ```

- 4 - Wait until the oauth-openshift pods are recreated
  ```bash
  watch -n1 "oc get pods -n openshift-authentication"
  ```

- 5 - Adding more users

  - Edit the htpasswd file (users.htpasswd) created in the first step
    ```bash
    htpasswd -B -b users.htpasswd developer2 developer2
    ```

  - It is possible to extract the existing secret with the current user login information
    ```bash
    oc extract secret/htpasswd-secret -n openshift-config --to .
    ```

  - After the htpasswd file (users.htpasswd) is updated, it needs to be set
    ```bash
    oc set data secret/htpasswd-secret --from-file htpasswd=./users.htpasswd -n openshift-config
    ```

- 6 - Deleting users

  - First update the htpasswd file (users.htpasswd) by removing the user to be deleted
    ```bash
    htpasswd -D users.htpasswd developer2
    ```

  - After the htpasswd file (users.htpasswd) is updated, it needs to be set
    ```bash
    oc set data secret/htpasswd-secret --from-file htpasswd=./users.htpasswd -n openshift-config
    ```

  - Delete the user from Openshift
    ```bash
    oc delete user developer2
    ```

  - Finally make sue that the identity that linked the deleted user is also removed from Openshift
    ```bash
    oc get identity | grep developer2
    ```
    ```bash
    oc delete identity my_htpasswd_provider:developer2
    ```

### In case you are using a custom certificate

It will need to execute the below command in order to login. 
  - The below shown pod ID is the one that runs the *oauth* server, it can be found be executing 
    ```bash
    oc get pods -A | grep oauth-openshift
    ```
    
    ```bash   
    oc rsh -n openshift-authentication *oauth-openshift-56bcdf6554-cb5cp* \
    cat /run/secrets/kubernetes.io/serviceaccount/ca.crt > ingress-ca.crt
    ```

  - Then login as *developer* user
    ```bash
    oc login -u developer -p developer --certificate-authority=ingress-ca.crt
    ```

### Create an admin user. First create the user within the htpasswd identity provider, then assign the admin role
```bash
oc adm policy add-cluster-role-to-user cluster-admin admin
```
