- create an container image for authenticating proxy

FROM centos

RUN dnf install httpd mod_auth_gssapi mod_session apr-util-openssl mod_ssl mod_auth_openidc -y
    dnf module enable mod_auth_openidc -y
    dnf clean all

COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY ca.crt /etc/pki/ca-trust/source/anchors/rh-sso.crt
RUN update-ca-trust extract

RUN mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.bak
RUN echo "IncludeOptional /opt/app-root/*.conf" >> /etc/httpd/conf/httpd.conf
RUN mkdir /opt/app-root/ && chown apache:apache /opt/app-root/ && chmod 0777 /opt/app-root/
COPY htpasswd /opt/app-root/

USER apache

EXPOSE 8080 8443

ENTRYPOINT ["/usr/sbin/run-httpd.sh"]
