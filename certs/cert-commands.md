- To check a `*.crt` file

> export CERT_FILE="/registry/certs/domain.crt"
>

> openssl x509 -in ${CERT_FILE} -text -noout
>

> openssl crl2pkcs7 -nocrl -certfile ${CERT_FILE} | openssl pkcs7 -print_certs -noout
>

- check that a key and cert match

> export CERT=control-certonly.crt
>
> openssl x509 -noout -modulus -in ${CERT} | openssl md5

> export KEY=control.key
>
> openssl rsa -noout -modulus -in ${KEY} | openssl md5

NOTE: the MD5 should be equal.

- check a CSR

> openssl req -text -noout -verify -in CSR.csr
>

- Check a private key

> openssl rsa -in privateKey.key -check
>

- check a certificate

> openssl x509 -in certificate.crt -text -noout
>

- Check a PKCS#12 file (.pfx or .p12)

> openssl pkcs12 -info -in keyStore.p12
>

### Creating self-signed cert with own CA

> export DOMAIN="doma.casa"
>

> export SHORT_NAME="control"
>

    echo -e "[req]
    default_bits = 4096
    prompt = no
    default_md = sha256
    distinguished_name = dn
    x509_extensions = usr_cert
    [ dn ]
    C=US
    ST=New York
    L=New York
    O=MyOrg
    OU=MyOU
    emailAddress=me@working.me
    CN = server.example.com
    [ usr_cert ]
    basicConstraints=CA:TRUE
    subjectKeyIdentifier=hash
    authorityKeyIdentifier=keyid,issuer" | tee csr_ca.txt

>

    echo -e "[req]
    default_bits = 4096
    prompt = no
    default_md = sha256
    x509_extensions = req_ext
    req_extensions = req_ext
    distinguished_name = dn
    [ dn ]
    C=US
    ST=New York
    L=New York
    O=MyOrg
    OU=MyOrgUnit
    emailAddress=me@working.me
    CN = ${SHORT_NAME}
    [ req_ext ]
    subjectAltName = @alt_names
    [ alt_names ]
    DNS.1 = ${SHORT_NAME}
    DNS.2 = ${SHORT_NAME}.${DOMAIN}" | tee > ${SHORT_NAME}_answer.txt


- Generate the key CA
>
> openssl genrsa -out ca.key 4096
>

- Generate the cert CA
>
> openssl req -new -x509 -key ca.key -days 730 -out ca.crt -config <( cat csr_ca.txt )
>

- Generate the key server
>
> openssl genrsa -out ${SHORT_NAME}.key 4096
>

- Generate server CSR
>
> openssl req -new -key ${SHORT_NAME}.key -out ${SHORT_NAME}.csr -config < (cat ${SHORT_NAME}_answer.txt)
>

- Test signed server CSR
>
> openssl req -in ${SHORT_NAME}.csr -noout -text | grep DNS
>

- Sign server CSR
>
> openssl x509 -req -in ${SHORT_NAME}.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out ${SHORT_NAME}.crt -days 730 -extensions 'req_ext' -extfile < (cat ${SHORT_NAME}_answer.txt)
>

- Test signed server CSR
>
> openssl req -in ${SHORT_NAME}.csr -noout -text | grep DNS
>

> openssl verify -CAfile ca.crt ${SHORT_NAME}.crt


### Testing The CA

> openssl s_client -connect foo.whatever.com:443 -CApath /etc/ssl/certs
>



---

### Netting procedure

- Creating key for own CA

> export DOMAIN="doma.casa"
>

> export SHORT_NAME="control"
>

    echo -e "[req]
    default_bits = 4096
    prompt = no
    default_md = sha256
    distinguished_name = dn
    x509_extensions = usr_cert
    [ dn ]
    C=US
    ST=New York
    L=New York
    O=MyOrg
    OU=MyOU
    emailAddress=me@working.me
    CN = server.example.com
    [ usr_cert ]
    basicConstraints=CA:TRUE
    subjectKeyIdentifier=hash
    authorityKeyIdentifier=keyid,issuer" | tee csr_ca.txt

>

    echo -e "[req]
    default_bits = 4096
    prompt = no
    default_md = sha256
    x509_extensions = req_ext
    req_extensions = req_ext
    distinguished_name = dn
    [ dn ]
    C=US
    ST=New York
    L=New York
    O=MyOrg
    OU=MyOrgUnit
    emailAddress=me@working.me
    CN = ${SHORT_NAME}
    [ req_ext ]
    subjectAltName = @alt_names
    [ alt_names ]
    DNS.1 = ${SHORT_NAME}
    DNS.2 = ${SHORT_NAME}.${DOMAIN}" | tee > ${SHORT_NAME}_answer.txt


- Generate the key CA
>
> openssl genrsa -out ca.key 4096
>

- Generate the cert CA
>
> openssl rsa -in ca.key -pubout > ca.pem

>

- Generate the key server
>
> openssl genrsa -out ${SHORT_NAME}.key 4096
>


# RSA Key

- generating ssh keys

> ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_rsa
>

- load ssh to env

> eval "$(ssh-agent -s)"
>

- extract public key from private key

> ssh-keygen -f ~/.ssh/id_rsa -y > ~/.ssh/id_rsa.pub
>

- check md5 per rsa key

> ssh-keygen -lf ~/.ssh/id_rsa
>
