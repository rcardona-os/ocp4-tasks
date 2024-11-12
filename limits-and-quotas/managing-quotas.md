## Managing and Applying Quotas

- OpenShift Container Platform can enforce quotas that track and limit the use of two kinds of resources:

    - __Object counts__: the number of Kubernetes resources, such as pods, services, and routes.

    - __Compute resources__: the number of physical or virtual hardware resources, such as CPU, memory, and storage capacity.

      Note: Although a single quota resource can define all of the quotas for a project, a project can also contain multiple quotas. For example, one quota resource might limit compute resources, such as total CPU allowed or total memory allowed. Another quota resource might limit object counts, such as the number of pods allowed or
      the number of services allowed. The effect of multiple quotas is cumulative, but it is expected that two different ResourceQuota resources for the same project do not limit the use of the same type of Kubernetes or compute resource. For example, two different quotas in a project should not both attempt to limit the maximum number of pods allowed.

- The following table describes some resources that a quota can restrict by their count or number

    |Resource Name|Quota Description|
    |-|-|
    |pods|Total number of pods|
    |replicationcontrollers|Total number of replication controllers|
    |services|Total number of services|
    |secrets|Total number of secrets|
    |persistentvolumeclaims|Total number of persistent volume claims|


- The following table describes some compute resources that can be restricted by a quota

    |Compute Resource Name|Quota Description|
    |-|-|
    |cpu (requests.cpu)|Total CPU use across all containers|
    |memory (requests.memory)|Total memory use across all containers|
    |storage (requests.storage)|Total storage requests by containers across all persistent volume claims|

- This example specifies quotas for both the number of resources and the use of compute resources

      echo -e 'apiVersion: v1
      kind: ResourceQuota
      metadata:
        name: dev-quota
      spec:
        hard:
          services: "10"
          cpu: "1300m"
          memory: "1.5Gi"' | tee dev-quota.yml


  > oc create --save-config -f dev-quota.yml

- This example does exactly as the previous command, but it implements the quota in one command
  > oc create quota dev-quota --hard services=10,cpu=1300,memory=1.5Gi

- List existing quotas
  > oc get resourcequota

- Delete quotas
  > oc delete resourcequota [QUOTA]

## Applying Limit Ranges

A LimitRange resource, also called a limit, defines the default, minimum, and maximum values for compute resource requests, and the limits for a single pod or container defined inside the project. A resource request or limit for a pod is the sum of its containers.
To understand the difference between a limit range and a resource quota, consider that a limit range defines valid ranges and default values for a single pod, and a resource quota defines only top values for the sum of all pods in a project. A cluster administrator concerned about resource usage in an OpenShift cluster usually defines both limits and quotas for a project.

- The following listing shows a limit range defined using YAML syntax

      echo -e 'apiVersion: "v1"
      kind: "LimitRange"
      metadata:
        name: "dev-limits"
      spec:
        limits:
          - type: "Pod"
            max:
              cpu: "500m"
              memory: "750Mi"
            min:
              cpu: "10m"
              memory: "5Mi"
          - type: "Container"
            max:
              cpu: "500m"
              memory: "750Mi"
            min:
              cpu: "10m"
              memory: "5Mi"
            default:
              cpu: "100m"
              memory: "100Mi"
            defaultRequest:
              cpu: "20m"
              memory: "20Mi"
          - type: openshift.io/Image
            max:
              storage: 1Gi
          - type: openshift.io/ImageStream
            max:
              openshift.io/image-tags: 10
              openshift.io/images: 20
          - type: "PersistentVolumeClaim"
            min:
              storage: "1Gi"
            max:
              storage: "50Gi"' | tee dev-limits.yml

    > oc create --save-config -f dev-limits.yml

- List / describe limitrange command to view the limit constraints enforced in a project
  > oc describe limitrange dev-limits

- Delete limitrange
  > oc delete limitrange dev-limits

### Applying Quotas to Multiple Projects

The ClusterResourceQuota resource is created at cluster level, similar to a persistent volume, and specifies resource constraints that apply to multiple projects.

Cluster administrators can specify which projects are subject to cluster resource quotas in two ways:

  - Using the __openshift.io/requester__ annotation to specify the project owner. All projects with the specified owner are subject to the quota.

  - Using a selector. All projects whose labels match the selector are subject to the quota.


- The following is an example of creating a cluster resource quota for all projects owned by the __qa__ user:
  > oc create clusterquota [CLUSTER_QUOTA_NAME] --project-annotation-selector openshift.io/requester=[USER] --hard [RESOURCES_QUOTAS]

  > oc create clusterquota user-qa --project-annotation-selector openshift.io/requester=qa --hard pods=12,secrets=20

- The following is an example of creating a cluster resource quota for all projects that have been assigned the __environment=qa__ label:
  > oc create clusterquota env-qa --project-label-selector environment=qa --hard pods=10,services=5

- Deleting clusterquota
  > oc delete clusterquota [QUOTA]
