FROM zentekmx/debian:stretch

MAINTAINER Marco A Rojas <marco.rojas@zentek.com.mx>

# Install slapd and requirements
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get \
        install -y \
            slapd \
            ldap-utils

# Clean temporary files and packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LDAP_DEBUG_LEVEL=256

# Create TLS certificate and bootstrap directory
RUN mkdir /etc/ldap/ssl /bootstrap

# Copy bootstrap and run files
COPY ./bootstrap /bootstrap
COPY ./run.sh /run.sh

VOLUME ["/etc/ldap/slapd.d", "/etc/ldap/ssl", "/var/lib/ldap", "/run/slapd"]

EXPOSE 389 636

CMD ["/bin/bash", "/run.sh"]

# End of file
# vim: set ts=2 sw=2 noet:
