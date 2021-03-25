FROM debian:stable

MAINTAINER Aristeu Jr <aristeu.jr@gmail.com>

ENV TZ=America/Sao_Paulo
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8


#        resolvconf \
#        dnsutils \
#        vim \
#        nano \
#        sssd \
#        sssd-tools \
#        libnss-sss \
#        libpam-sss \
#        adcli \

        
RUN apt-get -y update && \
    apt-get -yqq --no-install-recommends install \
        crudini \
        dbus \
        realmd \
        krb5-user \
        libpam-krb5 \
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
        supervisor \
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



## --------------------------------------------------
## 'Enabling sssd '
## --------------------------------------------------
#RUN systemctl enable sssd

RUN mkdir -p /var/lib/samba/private

RUN chmod 777 /home

RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY assets/groupmonitor /etc/cron.hourly/groupmonitor
RUN chmod +x /etc/cron.hourly/groupmonitor
RUN rm /etc/cron.daily/*
COPY assets/userlinks /etc/cron.daily/userlinks
RUN chmod +x /etc/cron.daily/userlinks



EXPOSE 137 138 139 445

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]





