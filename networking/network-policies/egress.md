# Configuring an Egress Policy/Firewall

As a cluster administrator, you can use an egress firewall to limit the external hosts that some or all pods can access from within the cluster. An egress firewall supports the following scenarios:

  - A pod can only connect to internal hosts and cannot initiate connections to the public internet.

  - A pod can only connect to the public internet and cannot initiate connections to internal hosts that are outside the OpenShift Container Platform cluster.

  - A pod cannot reach specified internal subnets or hosts outside the OpenShift Container Platform cluster.

  - A pod can connect to only specific external hosts.

For example, configuring one project to access a specified IP range but deny the same access to a different project. Or you can restrict application developers from updating from Python pip mirrors, and force updates to come only from approved sources.

__NOTE__: 	Egress firewall does not apply to the host network namespace. Pods with host networking enabled are unaffected by egress firewall rules. If your egress firewall includes a deny rule for 0.0.0.0/0, access to your OpenShift Container Platform API servers is blocked. You must either add allow rules for each IP address or use the nodeSelector type allow rule in your egress policy rules to connect to API servers. [Docs](https://docs.openshift.com/container-platform/4.13/networking/openshift_sdn/configuring-egress-firewall.html#nw-egressnetworkpolicy-about_openshift-sdn-egress-firewall)

### Prerequisites

  - To have OpenShift SDN configured to use either the network policy or multitenant mode to configure an egress firewall.

### Limitations

  - No project can have more than one EgressNetworkPolicy object.

  - A maximum of one EgressNetworkPolicy object with a maximum of 1,000 rules can be defined per project.

  - The default project cannot use an egress firewall.

  More detailed information [HERE](https://docs.openshift.com/container-platform/4.13/networking/openshift_sdn/configuring-egress-firewall.html#limitations-of-an-egress-firewall_openshift-sdn-egress-firewall)

### Matching order for egress firewall policy rules

The egress firewall policy rules are evaluated in the order that they are defined, from first to last. The first rule that matches an egress connection from a pod applies. Any subsequent rules are ignored for that connection. Configure an egress firewall policy by creating an EgressNetworkPolicy custom resource (CR) object. The egress firewall matches network traffic that meets any of the following criteria:

  - An IP address range in CIDR format

  - A DNS name that resolves to an IP address


### Default Network Policies for Application Access
  ```shell
  echo -n '---
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-from-openshift-ingress
  spec:
    podSelector: {}
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            network.openshift.io/policy-group: ingress
  ---
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-from-openshift-monitoring
  spec:
    podSelector: {}
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            network.openshift.io/policy-group: monitoring' | tee openshift-ingress-monitoring-netpol.yaml
  ```


### Case A - application pod accessing remote data base via _NetworkPolicy_
  ```shell
  echo -n 'apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: base-db-netpol
  spec:
    policyTypes:
      - Egress
    egress:
      - to:
          - ipBlock:
              cidr: 10.0.156.96/32
        ports:
          - protocol: TCP
            port: 31628' | tee base-db-egress-np.yaml
  ```

  ```shell
  oc apply -f base-db-egress-netpol.yaml
  ```

### Case B - application pod accessing remote data base via _EgressNetworkPolicy_
  ```shell
  echo -n 'apiVersion: network.openshift.io/v1
  kind: EgressNetworkPolicy
  metadata:
    name: base-db-egress-netpol
  spec:
    egress: 
    - type: Allow
      to:
        cidrSelector: 10.0.150.117/32
    - type: Deny
      to:
        cidrSelector: 0.0.0.0/0' | tee base-db-egress-netpol.yaml
  ```

  ```shell
  oc apply -f base-db-egress-netpol.yaml
  ```


  ### DATA EXAMPLES

  ---
### Dutch Players

- create db
   ```sql
   CREATE DATABASE contactsdb
   WITH
   OWNER = "contacts"
   IS_TEMPLATE = False
   ;
   ```

- connect to database `contactsdb`
  ```text
  \c contactsdb
  ```

- example create table
  ```sql
  CREATE TABLE contacts(id serial primary key,
                        firstname varchar(30) not null,
                        lastname varchar(30) not null,
                        email varchar(30) not null);
  ```

- insert data
  ```sql
  INSERT INTO contacts(firstname, lastname, email)
  VALUES ('Johan','Cruijff','johan@ajax.com'),
         ('Dennis','Bergkamp','dennis@ajax.com'),
         ('Ronald','Koeman','ronald@feyenoord.com')
         ;
  ```
---

---
### Spanish Players

- create db
   ```sql
   CREATE DATABASE contactsdb
   WITH
   OWNER = "contacts"
   IS_TEMPLATE = False
   ;
   ```

- connect to database `contactsdb`
  ```text
  \c contactsdb
  ```

- example create table
  ```sql
  CREATE TABLE contacts(id serial primary key,
                        firstname varchar(30) not null,
                        lastname varchar(30) not null,
                        email varchar(30) not null);
  ```

- insert data
  ```sql
  INSERT INTO contacts(firstname, lastname, email)
  VALUES ('Andres','Iniesta','andres@barcelona.com'),
         ('Fernando','Torres','fernando@atletico.com'),
         ('Raul','Gonzalez','raul@madrid.com')
         ;
  ```
---

---
### Portuguese Players

- create db
   ```sql
   CREATE DATABASE contactsdb
   WITH
   OWNER = "contacts"
   IS_TEMPLATE = False
   ;
   ```

- connect to database `contactsdb`
  ```text
  \c contactsdb
  ```

- example create table
  ```sql
  CREATE TABLE contacts(id serial primary key,
                        firstname varchar(30) not null,
                        lastname varchar(30) not null,
                        email varchar(30) not null)
                        ;
  ```

- insert data
  ```sql
  INSERT INTO contacts(firstname, lastname, email)
  VALUES ('Vitor','Baia','andres@porto.com'),
         ('Rui','Costa','rui@benfica.com'),
         ('Nuno','Gomes','nuno@benfica.com')
         ;
  ```
---