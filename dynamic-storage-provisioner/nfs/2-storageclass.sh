#!/bin/bash

echo -e 'apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: fuseim.pri/ifs # or choose another name, must match deployments env PROVISIONER_NAME
parameters:
  archiveOnDelete: "false"' | tee 2-storageclass.yaml
