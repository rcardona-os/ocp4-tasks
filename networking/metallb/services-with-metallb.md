### 0 - create an IP address pool

    echo -n 'apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      namespace: metallb-system
      name: non-expensive-ip-address-pool
    spec:
      addresses:
        - 10.0.100.0/28
      autoAssign: false' | tee ip-address-pool.yaml

  $ oc apply -f ip-address-pool.yaml

### 1 - create a L2 advertisement

    echo -n 'apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: non-expensive-l2advertisement
      namespace: metallb-system
    spec:
      ipAddressPools:
       - non-expensive-pool' | tee l2-advertisiment.yaml

  $ oc apply -f l2-advertisiment.yaml


### 2 - create a service to use a loadbalancer ennpoint with metallb

    echo -n 'apiVersion: v1
    kind: Service
    metadata:
      name: nginx-stable-svc
      annotations:
        metallb.universe.tf/address-pool: non-expensive-pool
    spec:
      selector:
        app: nginx-stable
      ports:
        - port: 8080
          targetPort: 8081
          protocol: TCP
      type: LoadBalancer
      loadBalancerIP: 10.0.100.3' | tee service-lb-metallb.yaml

  $ oc apply -f service-lb-metallb.yaml