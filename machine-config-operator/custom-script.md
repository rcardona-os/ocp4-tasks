### START ###

cat << EOF | base64 -w 0
echo "Who controls the past controls the future: who controls the present controls the past." > /tmp/my-test.txt
EOF

cat << EOF > ~/99_my-custom-script-worker.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  creationTimestamp: null
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-my-custom-script-worker
spec:
  osImageURL: ''
  config:
    ignition:
      config:
        replace:
          verification: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,ZWNobyAiV2hvIGNvbnRyb2xzIHRoZSBwYXN0IGNvbnRyb2xzIHRoZSBmdXR1cmU6IHdobyBjb250cm9scyB0aGUgcHJlc2VudCBjb250cm9scyB0aGUgcGFzdC4iID4gL3RtcC9teS10ZXN0LnR4dAo=
          verification: {}
        filesystem: root
        mode: 0755
        path: /usr/local/bin/my-custom-script
EOF
oc apply -f ~/99_my-custom-script-worker.yaml
