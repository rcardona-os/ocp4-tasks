# Visualizing and Fixing Performance Issues with Red Hat Service Mesh.

__Objective__

This procedure to install application Exchange

__Prerequisites__

- Red Hat Mesh 2.0 already installed (ref: https://gitlab.com/rcardona/ocp4-tasks/-/blob/master/operators/servicemesh/mesh-operator-cli.md)

- Existing *observe-mesh* project

- Existing user *developer* with editing capabilities in *observe-mesh* project (ref: https://gitlab.com/rcardona/ocp4-tasks/-/blob/master/identity-management/creating-developer-user.md)

__Steps__

1 - Create project *observe-mesh* with an admin capable user

> oc new-project observe-mesh

2 - Enable *developer* user with *edit* capabilities for project *observe-mesh*

> oc adm policy add-role-to-user edit __developer__ -n observe-mesh

3- Make *observe-mesh* be part of the *default*

    echo -e "apiVersion: maistra.io/v1
    kind: ServiceMeshMemberRoll
    metadata:
      name: default
      namespace: istio-system
    spec:
      members:
        # a list of projects joined into the service mesh
        - observe-mesh" | tee servicemeshmemberroll-default.yaml

> oc apply -f servicemeshmemberroll-default.yaml

4 - Deploy application

> git clone https://github.com/RedHatTraining/DO328-apps.git
>
> cd DO328-apps/exchange-application
>
> export CLUSTER_DOMAIN='my.ka'
>
> export CLUSTER_NAME='bm'
>
> oc process -f kubefiles/app-template.yml -p INGRESS_GW=istio-ingressgateway-istio-system.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN} -p NEWS_ENDPOINT=url | oc create -f -

> oc process -o yaml -f kubefiles/exchange-app-template.yaml -p INGRESS_GW=exchange-exchange-app.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN} -p NEWS_ENDPOINT=news-gossip-app.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN} | oc create -f -

5 - Open the application and find out an know issue

__Application Frontend URL__
http://istio-ingressgateway-istio-system.apps.${CLUSTER_NAME}.${CLUSTER_DOMAIN}/frontend

*Tip* There is something wrong with the `Historical Data` service
