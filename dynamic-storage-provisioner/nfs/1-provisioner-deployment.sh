#!/bin/bash

# NFS SERVER IP or HOSTNAME
NFS_SERVER_IP='10.0.0.1'
# NFS exported share
NFS_SERVER_PATH='/nfs'

echo -e "apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: openshift
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs
            - name: NFS_SERVER
              value: ${NFS_SERVER_IP}
            - name: NFS_PATH
              value: ${NFS_SERVER_PATH}
      volumes:
        - name: nfs-client-root
          nfs:
            server: ${NFS_SERVER_IP}
            path: ${NFS_SERVER_PATH}" | tee 1-provisioner-deployment.yaml
