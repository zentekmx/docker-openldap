FROM debian:stretch

MAINTAINER Marco A Rojas <marco.rojas@zentek.com.mx>

# Install slapd and requirements
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get \
        install -y --no-install-recommends \
            slapd \
            ldap-utils \
            openssl \
            ca-certificates \
            busybox # for throubleshooting purposes

# Busybox installation
RUN busybox --install

# Clean temporary files and cached packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LDAP_DEBUG_LEVEL=256

# Create TLS certificate and bootstrap directory
RUN mkdir /etc/ldap/ssl /bootstrap

# Copy run and bootstrap files
COPY ./run.sh /run.sh
COPY ./bootstrap /bootstrap

# Receive arguments
ARG LDAP_DOMAIN="zentek.com.mx"
ARG LDAP_ORGANIZATION="Zentek MX"
ARG LDAP_BINDDN="cn=admin,dc=zentek,dc=com,dc=mx"
ARG LDAP_SECRET="verysecretpass"

# Initialize LDAP with data
RUN /bin/bash /bootstrap/slapd-init.sh

VOLUME ["/etc/ldap/slapd.d", "/etc/ldap/ssl", "/var/lib/ldap", "/run/slapd"]

EXPOSE 389 636

CMD ["/bin/bash", "/run.sh"]
ENTRYPOINT []
