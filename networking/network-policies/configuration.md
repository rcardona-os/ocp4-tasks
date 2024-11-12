#### 0 - observe network access with tmux

- first load this cluster variables
```bash
export CLUSTERDOMAIN=`oc whoami --show-console | sed 's/https\?:\/\/console-openshift-console.//'`
```

```bash
echo -n '#!/usr/bin/env bash

PID=$$

set -x
if [ -z "${CLUSTERDOMAIN}" ]; then
  echo "set CLUSTERDOMAIN variable"
  exit 1;
fi

if [ -z $TMUX ] ; then
  echo "Start new tmux session"
  tmux new-session -d -s demo-$PID "watch curl -s -k https://homer-simpson.${CLUSTERDOMAIN}/demo"
fi
tmux split-window -d -t 0 -v  "watch curl -s -k https://marge-simpson.${CLUSTERDOMAIN}/demo"
tmux split-window -d -t 0 -h  "watch curl -s -k https://selma-bouvier.${CLUSTERDOMAIN}/demo"
tmux split-window -d -t 2 -h  "watch curl -s -k https://patty-bouvier.${CLUSTERDOMAIN}/demo"
if [ -z $TMUX ] ; then
  echo "Attach to session"
  tmux attach-session -t demo-$PID
else
  watch curl -s -k http://homer-simpson.${CLUSTERDOMAIN}/demo
fi' | tee run-tmux.sh
```

```bash
chmod 0750 run-tmux.sh
```

```bash
./run-tmux.sh
```

#### 1 - deploy application

```bash
oc new-project bouvier
```
```bash
oc new-app quay.io/openshift-examples/simple-http-server:micro --name patty
```
```bash
oc create route edge patty --service=patty
```
```bash
oc new-app quay.io/openshift-examples/simple-http-server:micro --name selma
```
```bash
oc create route edge selma --service=selma
```
```bash
oc new-project simpson
```
```bash
oc new-app quay.io/openshift-examples/simple-http-server:micro --name homer
```
```bash
oc create route edge homer --service=homer
```
```bash
oc new-app quay.io/openshift-examples/simple-http-server:micro --name marge
```
```bash
oc create route edge marge --service=marge
```

####  2 - list application pods
```bash
oc get pods -o wide -n simpson; oc  get pods -o wide -n bouvier
```

#### 3 - cases

3.0 - simpson project - default-deny
```bash
oc create -n simpson  -f - <<EOF
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
spec:
  podSelector: {}
EOF
```

3.1 - simpson project - allow from openshift-ingress namespaces
```bash
cat << EOF| oc create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-openshift-ingress
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: ingress
  podSelector: {}
  policyTypes:
  - Ingress
EOF
```

3.2 - simpsom project - allow internal communcation
```bash
cat << EOF| oc create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-same-namespace
spec:
  podSelector:
  ingress:
  - from:
    - podSelector: {}
EOF
```