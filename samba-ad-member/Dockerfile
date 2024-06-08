FROM debian:bookworm

ENV TZ=Brazil/East
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get -y update && apt-get dist-upgrade -y && \
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
        acl \
   && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/lib/samba/private
RUN chmod 777 /home
RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY assets/groupmonitor /etc/cron.hourly/groupmonitor
RUN chmod 744 /etc/cron.hourly/groupmonitor
RUN rm /etc/cron.daily/*
COPY assets/userlinks /etc/cron.daily/userlinks
RUN chmod 744 /etc/cron.daily/userlinks
COPY assets/crontab /etc/crontab

EXPOSE 137 138 139 445

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]





