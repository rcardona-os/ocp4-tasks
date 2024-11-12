# Starting with Red Hat Mesh

__Objective__

This procedure shows how to install the faulty-fleetman application. This piece of software is not meant to be used as an example of a well built microservice based application. Instead it is just a test application that helps to visualize the different components of the Red Hat Mesh.

__Prerequisites__

- Red Hat Mesh 2.0 already installed (ref: https://gitlab.com/rcardona/ocp4-tasks/-/blob/master/operators/servicemesh/mesh-operator-cli.md)

- Existing *default* project

- Existing user *developer* with editing capabilities in *default* project (ref: https://gitlab.com/rcardona/ocp4-tasks/-/blob/master/identity-management/creating-developer-user.md)

__Steps__

1 - Check that default project exist, otherwise create it

> oc get projects | grep -i default

or

> oc new-project default

2 - Enable user "developer" with *edit* capabilities

> oc adm policy add-role-to-user edit __developer__ -n default

3 - Enable service account *default* with *anyuid* in project *default* order to allow it to perform needed volume mounting for this application.

> oc adm policy add-scc-to-user anyuid system:serviceaccount:__default__:__default__

4 - Deploy application

> oc apply -f https://gitlab.com/rcardona/ocp4-tasks/-/raw/master/operators/servicemesh/apps/faulty-fleetman/application-full-stack.yaml -n default

5 - Expose the fleetman-webapp NodePort service

> oc expose svc fleetman-webapp -n default
