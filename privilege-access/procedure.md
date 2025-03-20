#### - datascience service account
```bash
$ oc crete sa datascience
```

#### - create security context constrain
```bash
$ oc adm policy add-scc-to-user privileged -z datascience
```