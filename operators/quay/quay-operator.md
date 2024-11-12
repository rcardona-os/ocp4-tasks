# Installing Red Hat Quay with Operator

Red Hat Quay is an enterprise-quality container registry. Use Red Hat Quay to build and store container images, then make them available to deploy across your enterprise.

The Red Hat Quay Operator provides the QuayRegistry custom resource API to declaratively manage Quay container registries on the cluster.

- Quay Operator components. In the QuayRegistry custom resource, the spec.components field configures components. Each component contains two fields: kind - the name of the component, and managed - boolean whether the component lifecycle is handled by the Operator.

Ex.

    spec:
      components:
        - kind: quay
          managed: true
        - kind: postgres
          managed: true
        - kind: clair
          managed: true
        - kind: redis
          managed: true
        - kind: horizontalpodautoscaler
          managed: true
        - kind: objectstorage
          managed: true
        - kind: route
          managed: true
        - kind: mirror
          managed: true
        - kind: monitoring
          managed: true
        - kind: tls
          managed: true
        - kind: clairpostgres
          managed: true

- Using managed components. Unless your QuayRegistry custom resource specifies otherwise, the Operator will use defaults for the following managed components:

   - `quay`: Holds overrides for the Quay deployment, for example, environment variables and number of replicas. This component is new in Red Hat Quay 3.7 and cannot be set to unmanaged.
   - `postgres`: For storing the registry metadata, uses a version of Postgres 10 from the Software Collections
   - `clair`: Provides image vulnerability scanning
   - `redis`: Handles Quay builder coordination and some internal logging
   - `horizontalpodautoscaler`: Adjusts the number of Quay pods depending on memory/cpu consumption
   - `objectstorage`: For storing image layer blobs, utilizes the ObjectBucketClaim Kubernetes API which is provided by Noobaa/RHOCS
   - `route`: Provides an external entrypoint to the Quay registry from outside OpenShift
   - `mirror`: Configures repository mirror workers (to support optional repository mirroring)
   - `monitoring`: Features include a Grafana dashboard, access to individual metrics, and alerting to notify for frequently restarting Quay pods
   - `tls`: Configures whether Red Hat Quay or OpenShift handles TLS
   - `clairpostgres`: Configures a managed Clair database


   __NOTE: The Operator can manage all the Red Hat Quay components when deploying on OpenShift, and this is the default configuration. Alternatively, you can manage one or more components externally yourself, where you want more control over the set up, and then allow the Operator to manage the remaining components.__

## Cases of deployment and configuration

#### 1 - Case: Red Hat Quay 3.7.8 with ODF as persistent storage

- Make sure that ODF is installed, and that the default storageClass (ocs-storagecluster-ceph-rbd) is defined. In order to allow the Operator to manage object storage for Quay, the cluster needs to be capable of providing object storage via the ObjectBucketClaim API.

  > $ oc annotate sc ocs-storagecluster-ceph-rbd storageclass.kubernetes.io/is-default-class="true"
  >

- Create project

  > $ cat registry-enterprise-project.yaml
  >

      kind: Project
      apiVersion: project.openshift.io/v1
      metadata:
        name: registry-enterprise
        annotations:
          openshift.io/node-selector: 'node-role.kubernetes.io/infra='
          scheduler.alpha.kubernetes.io/defaultTolerations: >-
            [{"operator": "Exists", "effect": "NoSchedule", "key":
            "node.ocs.openshift.io/storage"}
            ]

    > $ oc apply -f registry-enterprise-project.yaml
    >

- Create a Secret using the configuration file

  > $ cat config.yaml
  >

      FEATURE_USER_INITIALIZE: true
      BROWSER_API_CALLS_XHR_ONLY: false
      SUPER_USERS:
      - quayadmin
      FEATURE_USER_CREATION: false

    > $ oc create secret generic --from-file config.yaml=./config.yaml config-bundle-secret -n registry-enterprise
    >

- Deploy a QuayRegistry with YAML file quayregistry.yaml

    > $ cat quayregistry.yaml
    >

      apiVersion: quay.redhat.com/v1
      kind: QuayRegistry
      metadata:
        name: main
        namespace: registry-enterprise
      spec:
        configBundleSecret: config-bundle-secret

    > $ oc create -f quayregistry.yaml
    >

- Check that alll pods are in `Ready` and `Running` state (similar ouput as below is expected)

    > oc get pods -n registry-enterprise
    >

      NAME                                       READY   STATUS    RESTARTS        AGE
      main-clair-app-5968985787-c784c            1/1     Running   1 (3h11m ago)   3h13m
      main-clair-app-5968985787-htqzv            1/1     Running   0               3h10m
      main-clair-postgres-c9b547566-f57px        1/1     Running   0               3h13m
      main-quay-app-5dbcf4bccb-5pb57             1/1     Running   0               3h13m
      main-quay-app-5dbcf4bccb-cf4bp             1/1     Running   0               3h10m
      main-quay-config-editor-5b46d47556-hrv97   1/1     Running   0               3h10m
      main-quay-database-5cbb5d688f-rzn7s        1/1     Running   0               3h10m
      main-quay-mirror-69ccdd7f5d-6scp2          1/1     Running   0               3h13m
      main-quay-mirror-69ccdd7f5d-rd6qc          1/1     Running   0               3h10m
      main-quay-redis-67b67649b-g8pxw            1/1     Running   0               3h13m

- Create the first user, quayadmin, using the API

  > $ oc get routes -n quay-enterprise
  >

      NAME                      HOST/PORT                                                                      PATH   SERVICES                  PORT   TERMINATION     WILDCARD
      main-quay                 main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com                        main-quay-app             http   edge/Redirect   None
      main-quay-builder         main-quay-builder-registry-enterprise.apps.ocp4.sandbox695.opentlc.com                main-quay-app             grpc   edge/Redirect   None
      main-quay-config-editor   main-quay-config-editor-registry-enterprise.apps.ocp4.sandbox695.opentlc.com          main-quay-config-editor   http   edge/Redirect   None


  > $ curl -X POST -k  https://main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password":"quaypass123", "email": "quayadmin@example.com", "access_token": true}'
  >

      {"access_token":"6B4QTRSTSD1HMIG915VPX7BMEZBVB9GPNY2FC2ED", "email":"quayadmin@example.com","encrypted_password":"1nZMLH57RIE5UGdL/yYpDOHLqiNCgimb6W9kfF8MjZ1xrfDpRyRs9NUnUuNuAitW","username":"quayadmin"}

- Using API to return a list of the current users

  > $ curl -X GET -k -H "Authorization: Bearer 6B4QTRSTSD1HMIG915VPX7BMEZBVB9GPNY2FC2ED" https://main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com/api/v1/superuser/users/
  >

      {
       "users": [
           {
               "kind": "user",
               "name": "quayadmin",
               "username": "quayadmin",
               "email": "quayadmin@example.com",
               "verified": true,
               "avatar": {
                   "name": "quayadmin",
                   "hash": "3e82e9cbf62d25dec0ed1b4c66ca7c5d47ab9f1f271958298dea856fb26adc4c",
                   "color": "#e7ba52",
                   "kind": "user"
               },
               "super_user": true,
               "enabled": true
           }
       ]
      }

- Create an organization

  > $ curl -X POST -k --header 'Content-Type: application/json' -H "Authorization: Bearer 6B4QTRSTSD1HMIG915VPX7BMEZBVB9GPNY2FC2ED" https://main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com/api/v1/organization/ --data '{"name": "pro-org", "email": "pro-org@example.com"}'
  >

- To retrieve the details of the organization

  > $ curl -X GET -k --header 'Content-Type: application/json' -H "Authorization: Bearer 6B4QTRSTSD1HMIG915VPX7BMEZBVB9GPNY2FC2ED" https://main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com/api/v1/organization/pro-org
  >

      {
          "name": "pro-org",
          "email": "pro-org@example.com",
          "avatar": {
              "name": "pro-org",
              "hash": "5f113632ad532fc78215c9258a4fb60606d1fa386c91b141116a1317bf9c53c8",
              "color": "#a55194",
              "kind": "user"
          },
          "is_admin": true,
          "is_member": true,
          "teams": {
              "owners": {
                  "name": "owners",
                  "description": "",
                  "role": "admin",
                  "avatar": {
                      "name": "owners",
                      "hash": "6f0e3a8c0eb46e8834b43b03374ece43a030621d92a7437beb48f871e90f8d90",
                      "color": "#c7c7c7",
                      "kind": "team"
                  },
                  "can_view": true,
                  "repo_count": 0,
                  "member_count": 1,
                  "is_synced": false
              }
          },
          "ordered_teams": [
              "owners"
          ],
          "invoice_email": false,
          "invoice_email_address": null,
          "tag_expiration_s": 1209600,
          "is_free_account": true
      }

- (option step) Enable registry in Openshift cluser

  - Registry as insecure and library being public
    > $ oc edit image.config.openshift.io/cluster
    >

        ...
        spec:
          registrySources:
            insecureRegistries:
            - main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com




  - Extract current pull-secret in order to update with the credential of the new registrySources
    > $ oc get secret/pull-secret -n openshift-config -o jsonpath="{.data.\\.dockerconfigjson}"  | base64 -d >> pull-secret.json
    >

  - Encode the `user:password` to base64
    > $ echo -n "quayadmin:quaypass123" | base64
    >

        cXVheWFkbWluOnF1YXlwYXNzMTIz

  - Edit pull-secret.json as follows
    > $ cat pull-secret.json
    >

        {
          "auths": {
            "quay.io": {
              "auth": "xxx",
              "email": "myemail@xxx.com"
            },
            "registry.connect.redhat.com": {
              "auth": "xxx",
              "email": "myemail@xxx.com"
            },
            "registry.redhat.io": {
              "auth": "xxx",
              "email": "myemail@xxx.com"
            },
            "main-quay-registry-enterprise.apps.ocp4.sandbox695.opentlc.com": {
              "auth": "cXVheWFkbWluOnF1YXlwYXNzMTIz",
              "email": "myemail@xxx.com"
            }
          }
        }

  - set the updated secret in the openshift cluster
    > oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=pull-secret.json
    >
---
