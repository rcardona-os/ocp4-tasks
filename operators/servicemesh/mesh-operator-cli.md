# Installing the Red Hat Mesh Operator with the CLI

- View the list of operators available to the cluster from OperatorHub

> oc get packagemanifests -n openshift-marketplace | grep -i mesh


- Inspect the mesh operator to verify its supported install modes and available channels
> oc describe packagemanifests servicemeshoperator -n openshift-marketplace

To defined by an OperatorGroup object, that selects target namespaces in which to generate required RBAC access for all Operators in the same namespace as the operator group.
The namespace to which you subscribe the Operator must have an operator group that matches the install mode of the Operator, either the AllNamespaces or SingleNamespace mode. If the Operator you intend to install uses the AllNamespaces, then the openshift-operators namespace already has an appropriate operator group in place.
However, if the Operator uses the SingleNamespace mode and you do not have an appropriate operator group in place, you must create one.

> oc describe  operatorgroups global-operators -n openshift-operators

## 1 - Install elasticsearch operator
- create operator group

> export OPERATOR_GROUP_NAME='operators-group-redhat'
>
> export OPERATOR_NAMESPACE_REDHAT='openshift-operators-redhat'

    echo -e "apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: ${OPERATOR_GROUP_NAME}
      namespace: ${OPERATOR_NAMESPACE_REDHAT}
    spec: {}" | tee operators-group-redhat.yaml

>  kubectl create ns ${OPERATOR_NAMESPACE_REDHAT}

>  oc apply -f operators-group-redhat.yaml -n openshift-operators-redhat

- create operator subscription

> export OPERATOR_SUBSCRIPTION_NAME='subscription-elasticsearch-operator'
>
> export CHANNEL_NAME='4.6'
>
> export PACKAGE_NAME='elasticsearch-operator'
>
> export CATALOG_OPERATOR='redhat-operators'
>
> export SOURCE_NAMESPACE='openshift-marketplace'
>
> export INSTALL_PLAN_APPROVAL='Automatic'

    echo -e "apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: '${OPERATOR_SUBSCRIPTION_NAME}'
      namespace: ${OPERATOR_NAMESPACE_REDHAT}
    spec:
      channel: \"${CHANNEL_NAME}\"
      name: ${PACKAGE_NAME}
      source: ${CATALOG_OPERATOR}
      sourceNamespace: ${SOURCE_NAMESPACE}
      installPlanApproval: ${INSTALL_PLAN_APPROVAL} " | tee elasticsearch-subscription.yaml

> oc apply -f elasticsearch-subscription.yaml -n openshift-operators-redhat

NOTE: if you want to remove the operator you need to remove the csv from the related project

`oc delete csv elasticsearch-operator.4.6.0-202102130420.p0 -n openshift-operators-redhat`

`kubectl delete project openshift-operators-redhat`

`oc get csv -n openshift-operators`

`oc get subscriptions.operators.coreos.com -n openshift-operators`

`oc get operatorgroups.operators.coreos.com -n openshift-operators`

`oc get csv -n openshift-operators-redhat`

`oc get subscriptions.operators.coreos.com -n openshift-operators-redhat`

`oc get operatorgroups.operators.coreos.com -n openshift-operators-redhat`

## 2 - Installing jaeger operator

> export OPERATOR_SUBSCRIPTION_NAME='subscription-jaeger-operator'
>
> export OPERATOR_NAMESPACE='openshift-operators'
>
> export CHANNEL_NAME='stable'
>
> export PACKAGE_NAME='jaeger-product'
>
> export CATALOG_OPERATOR='redhat-operators'
>
> export SOURCE_NAMESPACE='openshift-marketplace'
>
> export INSTALL_PLAN_APPROVAL='Automatic'

    echo -e "apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: ${OPERATOR_SUBSCRIPTION_NAME}
      namespace: ${OPERATOR_NAMESPACE}
    spec:
      channel: \"${CHANNEL_NAME}\"
      name: ${PACKAGE_NAME}
      source: ${CATALOG_OPERATOR}
      sourceNamespace: ${SOURCE_NAMESPACE}
      installPlanApproval: ${INSTALL_PLAN_APPROVAL}  " | tee jaeger-subscription.yaml


  > oc apply -f jaeger-subscription.yaml -n openshift-operators

## 3 - Installing kiali operator

> export OPERATOR_SUBSCRIPTION_NAME='subscription-kiali-operator'
>
> export OPERATOR_NAMESPACE='openshift-operators'
>
> export CHANNEL_NAME='stable'
>
> export PACKAGE_NAME='kiali-ossm'
>
> export CATALOG_OPERATOR='redhat-operators'
>
> export SOURCE_NAMESPACE='openshift-marketplace'
>
> export INSTALL_PLAN_APPROVAL='Automatic'

    echo -e "apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: ${OPERATOR_SUBSCRIPTION_NAME}
      namespace: ${OPERATOR_NAMESPACE}
    spec:
      channel: \"${CHANNEL_NAME}\"
      name: ${PACKAGE_NAME}
      source: ${CATALOG_OPERATOR}
      sourceNamespace: ${SOURCE_NAMESPACE}
      installPlanApproval: ${INSTALL_PLAN_APPROVAL}  " | tee kiali-subscription.yaml

> oc apply -f kiali-subscription.yaml -n openshift-operators


## 4 - Installing Red Hat Mesh operator

> export OPERATOR_SUBSCRIPTION_NAME='subscription-servicemesh-operator'
>
> export OPERATOR_NAMESPACE='openshift-operators'
>
> export CHANNEL_NAME='stable'
>
> export PACKAGE_NAME='servicemeshoperator'
>
> export CATALOG_OPERATOR='redhat-operators'
>
> export SOURCE_NAMESPACE='openshift-marketplace'
>
> export INSTALL_PLAN_APPROVAL='Automatic'

    echo -e "apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: ${OPERATOR_SUBSCRIPTION_NAME}
      namespace: ${OPERATOR_NAMESPACE}
    spec:
      channel: \"${CHANNEL_NAME}\"
      name: ${PACKAGE_NAME}
      source: ${CATALOG_OPERATOR}
      sourceNamespace: ${SOURCE_NAMESPACE}
      installPlanApproval: ${INSTALL_PLAN_APPROVAL}  " | tee servicemesh-subscription.yaml


> oc apply -f servicemesh-subscription.yaml -n openshift-operators


## To this point the RH Mesh operator is already install, now it needs to deploy the control plane and to configure the required projects as part of a ServiceMeshMemberRoll.

(here below an example)

- Deploy the control plane

*Create project*

> oc new-project istio-system

- Creating ServiceControlPlane object

      echo -e "apiVersion: maistra.io/v2
      kind: ServiceMeshControlPlane
      metadata:
        name: basic
        namespace: istio-system
      spec:
        version: v2.0
        tracing:
          type: Jaeger
          sampling: 10000
        addons:
          jaeger:
            name: jaeger
            install:
              storage:
                type: Memory
          kiali:
            enabled: true
            name: kiali
          grafana:
            enabled: true" | tee sm-controlplane-installation.yaml

> oc apply -f sm-controlplane-installation.yaml -n istio-system

- Check the components created

> oc get smcp -n istio-system

- The ServiceMeshMemberRoll lists the projects belonging to the control plane. Only projects listed in the ServiceMeshMemberRoll are affected by the control plane.

*Create the project that will be a memember of the mesh*

> oc new-project default

- Create a ServiceMeshMemberRoll resource in the same project as the ServiceMeshControlPlane resource, in our example that is istio-system

      echo -e "apiVersion: maistra.io/v1
      kind: ServiceMeshMemberRoll
      metadata:
        name: default
        namespace: istio-system
      spec:
        members:
          # a list of projects joined into the service mesh
          - default" | tee servicemeshmemberroll-default.yaml

> oc apply -f servicemeshmemberroll-default.yaml -n istio-system

______
