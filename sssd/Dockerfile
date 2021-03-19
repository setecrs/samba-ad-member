FROM debian:stable

MAINTAINER Aristeu Jr <aristeu.jr@gmail.com>

ENV TZ=Brazil/East
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8


#        resolvconf \
#        dnsutils \
#        vim \
#        nano \
#        realmd \
#        krb5-user \
#        libpam-krb5 \

        
RUN apt-get -y update && \
    apt-get -yqq --no-install-recommends install \
        crudini \
        dbus \
        adcli \
        winbind \
        libnss-winbind \
        libpam-winbind \
        samba \
        samba-dsdb-modules \
        samba-client \
        samba-vfs-modules \
        logrotate \
        attr \
        libpam-mount \
        policykit-1 \
        packagekit \
        sssd \
        sssd-tools \
        libnss-sss \
        libpam-sss \
        adcli \
        supervisor \
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# --------------------------------------------------
# 'Enabling sssd and Disabling Samba to enable handling by supervisord'
# --------------------------------------------------
RUN systemctl enable sssd \
 && systemctl disable winbind \
 && systemctl disable nmbd \
 && systemctl disable smbd

RUN mkdir -p /var/lib/samba/private

RUN chmod 777 /home

RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 137 138 139 445

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]





