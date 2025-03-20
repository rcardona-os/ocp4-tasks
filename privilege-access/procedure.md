#### - datascience service account
```bash
$ oc create sa datascience
```

#### - create security context constrain
```bash
$ oc adm policy add-scc-to-user privileged -z datascience
```