# OpenLDAP Docker image with memmorable people

This image provides an OpenLDAP Server with data for testing purposes with really memmorable people. The image is based on latest Debian stable ("stretch" at the momment). Parts of the the Dockerfile was based on the work from Nick Stenning [docker-slapd][1] and Rafael Römhild [docker-test-openldap][2].

It brings a basic configuration of OpenLDAP server, slapd, with support for data volumes. Out-of-the-box uses zentek.com.mx domain but you can easily change with the following command:

`docker run -it -p 389:389 -e LDAP_DOMAIN=acme.com -e LDAP_ORGANIZATION="Acmen Inc" -e LDAP_SECRET=secret zentekmx/openldap:2.4`

Features
Support for TLS (snake oil cert on build)
Initialized with data of
 - famous artists
 - famous scientists
 - famous explorers
 - image size of ~180MB

# Usage
You can configure the following by providing environment variables to docker run:

 - LDAP_DOMAIN sets the LDAP root domain. (e.g. if you provide acme.com here, the root of your directory will be dc=acme,dc=com)
 - LDAP_ORGANIZATION sets the human-readable name for your organization (e.g. Acme Inc.)
 - LDAP_SECRET sets the LDAP admin user password (i.e. the password for cn=admin,dc=acme,dc=com if your domain was acme.com)

```bash
docker pull zentekmx/openldap
docker run -d -p 389:389 -e LDAP_DOMAIN=acme.com -e LDAP_ORGANIZATION="Acmen Inc" -e LDAP_SECRET=secret zentekmx/openldap:2.4
ldapsearch -x -h localhost -b "dc=acme,dc=com" -D "cn=admin,dc=acme,dc=com" -w secret "(objectclass=*)"
```
**NB** The binddn will be always "cn=admin,\<your-root-directory\>" in this case cn=admin,*dc=acme,dc=com*
# Exposed ports

* 389
* 636

# Exposed volumes

* /etc/ldap/slapd.d
* /etc/ldap/ssl
* /var/lib/ldap
* /run/slapd


[1]: https://github.com/nickstenning/docker-slapd "docker-slapd"
[2]: https://github.com/rroemhild/docker-test-openldap "docker-test-openldap"
