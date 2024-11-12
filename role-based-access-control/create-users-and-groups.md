### Assigning Administrative Privileges

Once the authentication is granted via the identityProviders, then Openshift would follow the administrative privileges (via RBAC for example). The default privileges for any authenticated user is a `basic-user` role. Privileges are defined by roles, and those roles are assigned to users and/or groups via bindings.

- Red Hat OpenShift defines two groups of roles and bindings depending on the user's scope and responsibility: cluster roles and local roles.

| Role Level | Are |
|-|-|
| Cluster Role | Users or groups with this role level can manage the OpenShift cluster |
| Local Role | Users or groups with this role level can only manage elements at a project level |

- Default Roles

|Default roles|Description|
|-|-|
|admin|Users with this role can manage all project resources, including granting access to other users to access the project|
|basic-user|Users with this role have read access to the project|
|cluster-admin|Users with this role have superuser access to the cluster resources. These users can perform any action on the cluster, and have full control of all projects|
|cluster-status|Users with this role can get cluster status information|
|edit|Users with this role can create, change, and delete common application resources from the project, such as services and deployments. These users cannot act on management resources such as limit ranges and quotas, and cannot manage access permissions to the project|
|self-provisioner|Users with this role can create new projects. This is a cluster role, not a project role|
|view|Users with this role can view project resources, but cannot modify project resources|

## Managing RBAC Using the CLI

- To add a cluster role to a user, use the add-cluster-role-to-user subcommand
    > oc adm policy add-cluster-role-to-user [CLUSTER_ROLE] [USERNAME]

- Create an *admin* user. First create the user within the *htpasswd* identity provider, then assign the admin role
    > oc adm policy add-cluster-role-to-user cluster-admin admin

- List all `clusterroles` (Cluster Roles) and `roles` (Local Roles)
    > oc get clusterroles
    >

    > oc get roles
    >       

- Viewing cluster roles
    > oc describe clusterroles

- List all clusterrolebindings
    > oc get clusterrolebindings

- List all cluster system groups
    > oc describe clusterrolebindings | grep Group

- To remove a cluster role from a user, use the remove-cluster-role-from-user subcommand
    > oc adm policy remove-cluster-role-from-user [CLUSTER_ROLE] [USERNAME]

-  To determine if a user can execute an action on a resource
    > oc adm policy who-can [VERB] [RESOURCE]
    >

    > oc adm policy who-can delete user
    >

- Example: removing the capacity of an user with basic authentication to be able to create projects
    > oc get clusterrole | grep self
    >

    > oc get clusterrolebindings | grep "self-provisioner"
    >

    > oc describe clusterrolebindings self-provisioners
    >

          ➡ oc describe clusterrolebindings self-provisioners
          Name:         self-provisioners
          Labels:       <none>
          Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
          Role:
           Kind:  ClusterRole
           Name:  self-provisioner
          Subjects:
           Kind   Name                        Namespace
           ----   ----                        ---------
           Group  system:authenticated:oauth

    > oc adm policy remove-cluster-role-from-group self-provisioner system:authenticated:oauth
    >

### Create groups and add users

- Creating group
  > oc adm groups new [GROUP_NAME]
  >
  > oc adm groups new app1_admin

- Adding users to groups
  > oc adm groups add-users [GROUP_NAME] [USER1] [USER2]
  >
  > oc adm groups add-users app1_admin user3 user4

- Assigning the respective roles to the Group
  > oc adm policy add-role-to-group [ROLE] [GROUP_NAME] -n [PROJECT_NAME]
  >
  > oc adm policy add-role-to-group admin app1_admin -n app1-project
