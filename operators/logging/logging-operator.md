# Elasticsearch Operator and Cluster Logging Operator using the CLI

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
> export CHANNEL_NAME='5.0'
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

## 2 - Installing Cluster Logging operator

- First creete the openshift-logging namespace
>
> OPENSHIFT_LOGGING_NAMESPACE='openshift-logging'
>

    echo -e "apiVersion: v1
    kind: Namespace
    metadata:
      name: ${OPENSHIFT_LOGGING_NAMESPACE}
      annotations:
        openshift.io/node-selector: \"\"
      labels:
        openshift.io/cluster-monitoring: \"true\"  " | tee openshift-logging-namespace.yaml

>
> oc apply -f openshift-logging-namespace.yaml
>

> export OPERATOR_SUBSCRIPTION_NAME='subscription-cluster-logging-operator'
>
> export CHANNEL_NAME='5.0'
>
> export PACKAGE_NAME='cluster-logging'
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
      namespace: ${OPENSHIFT_LOGGING_NAMESPACE}
    spec:
      channel: \"${CHANNEL_NAME}\"
      name: ${PACKAGE_NAME}
      source: ${CATALOG_OPERATOR}
      sourceNamespace: ${SOURCE_NAMESPACE}
      installPlanApproval: ${INSTALL_PLAN_APPROVAL}  " | tee openshift-logging-subscription.yaml


  > oc apply -f openshift-logging-subscription.yaml -n openshift-operators


## 3 - Veryfy installation Cluster Logging operator

>
> oc get csv -n openshift-logging
>

### 4 - Create a OpenShift Logging instance














---
