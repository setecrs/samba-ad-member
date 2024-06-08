#! /bin/bash
# Reference:
# * https://wiki.debian.org/AuthenticatingLinuxWithActiveDirectory
# * https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members
# * http://www.oreilly.com/openbook/samba/book/ch04_08.html
#
# * https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member

# Update loopback entry
TZ=${TZ:-Etc/UTC}
AD_USERNAME=${AD_USERNAME:-administrator}
AD_PASSWORD=${AD_PASSWORD:-password}
HOSTNAME=${HOSTNAME:-$(hostname)}
IP_ADDRESS=${IP_ADDRESS:-}
DOMAIN_NAME=${DOMAIN_NAME:-domain.loc}
DNS_SERVER=${DNS_SERVER:-}
ADMIN_SERVER=${ADMIN_SERVER:-${DOMAIN_NAME,,}}
KDC_SERVER=${KDC_SERVER:-$(echo ${ADMIN_SERVER,,} | awk '{print $1}')}
PASSWORD_SERVER=${PASSWORD_SERVER:-${ADMIN_SERVER,,}}
ENCRYPTION_TYPES=${ENCRYPTION_TYPES:-rc4-hmac des3-hmac-sha1 des-cbc-crc arcfour-hmac aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 des-cbc-md5}
NAME_RESOLVE_ORDER=${NAME_RESOLVE_ORDER:-host bcast}
SERVER_STRING=${SERVER_STRING:-Samba Server Version %v}
SECURITY=${SECURITY:-ads}
REALM=${REALM:-${DOMAIN_NAME^^}}
PASSWORD_SERVER=${PASSWORD_SERVER:-${DOMAIN_NAME,,}}
WORKGROUP=${WORKGROUP:-${DOMAIN_NAME^^}}
WINBIND_SEPARATOR=${WINBIND_SEPARATOR:-"\\"}
WINBIND_UID=${WINBIND_UID:-50-9999999999}
WINBIND_GID=${WINBIND_GID:-50-9999999999}
WINBIND_ENUM_USERS=${WINBIND_ENUM_USERS:-yes}
WINBIND_ENUM_GROUPS=${WINBIND_ENUM_GROUPS:-yes}
TEMPLATE_HOMEDIR=${TEMPLATE_HOMEDIR:-/home/%U}
TEMPLATE_SHELL=${TEMPLATE_SHELL:-/dev/null}
DEDICATED_KEYTAB_FILE=${DEDICATED_KEYTAB_FILE:-/etc/krb5.keytab}
KERBEROS_METHOD=${KERBEROS_METHOD:-secrets and keytab}
CLIENT_USE_SPNEGO=${CLIENT_USE_SPNEGO:-yes}
CLIENT_NTLMV2_AUTH=${CLIENT_NTLMV2_AUTH:-yes}
ENCRYPT_PASSWORDS=${ENCRYPT_PASSWORDS:-yes}
SERVER_SIGNING=${SERVER_SIGNING:-auto}
SMB_ENCRYPT=${SMB_ENCRYPT:-auto}
WINDBIND_USE_DEFAULT_DOMAIN=${WINBIND_USE_DEFAULT_DOMAIN:-yes}
RESTRICT_ANONYMOUS=${RESTRICT_ANONYMOUS:-2}
DOMAIN_MASTER=${DOMAIN_MASTER:-no}
LOCAL_MASTER=${LOCAL_MASTER:-no}
PREFERRED_MASTER=${PREFERRED_MASTER:-no}
OS_LEVEL=${OS_LEVEL:-0}
WINS_SUPPORT=${WINS_SUPPORT:-no}
WINS_SERVER=${WINS_SERVER:-127.0.0.1}
DNS_PROXY=${DNS_PROXY:-no}
LOG_LEVEL=${LOG_LEVEL:-1}
DEBUG_TIMESTAMP=${DEBUG_TIMESTAMP:-yes}
LOG_FILE=${LOG_FILE:-/var/log/samba/log.%m}
MAX_LOG_SIZE=${MAX_LOG_SIZE:-1000}
PANIC_ACTION=${PANIC_ACTION:-/usr/share/samba/panic-action %d}
HOSTS_ALLOW=${HOSTS_ALLOW:-192.168.0.0/16 172.16.0.0/20 10.0.0.0/8}
SOCKET_OPTIONS=${SOCKET_OPTIONS:-TCP_NODELAY SO_KEEPALIVE IPTOS_LOWDELAY}
READ_RAW=${READ_RAW:-yes}
WRITE_RAW=${WRITE_RAW:-yes}
OPLOCKS=${OPLOCKS:-no}
LEVEL2_OPLOCKS=${LEVEL2_OPLOCKS:-no}
KERNEL_OPLOCKS=${KERNEL_OPLOCKS:-yes}
MAX_XMIT=${MAX_XMIT:-65535}
MAX_OPEN_FILES=${MAX_OPEN_FILES:-32000}
RPC_START_ONDEMAND_HELPERS=${RPC_START_ONDEMAND_HELPERS:-no}
DEAD_TIME=${DEAD_TIME:-0}
SHARED_DIRECTORY=${SHARED_DIRECTORY:-/usr/share/public}
SHARE_NAME=${SHARE_NAME:-public}
GROUP_PREFIX=${GROUP_PREFIX:-}
SAMBA_CONF=/etc/samba/smb.conf

echo --------------------------------------------------
echo "Setting Timezone configuration"
echo --------------------------------------------------
ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo --------------------------------------------------
echo "Setting up Kerberos realm: \"${DOMAIN_NAME^^}\""
echo --------------------------------------------------
cat > /etc/krb5.conf << EOL
#[logging]
#    default = FILE:/var/log/krb5.log
#    kdc = FILE:/var/log/kdc.log
#    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    default_realm = ${DOMAIN_NAME^^}
    dns_lookup_realm = false
    dns_lookup_kdc = false


EOL

echo --------------------------------------------------
echo "Adjusting hosts"
echo --------------------------------------------------
echo $(hostname -i)"     "$HOSTNAME\.$DOMAIN_NAME $HOSTNAME $(hostname -f) $(hostname)   > /etc/hosts
hostname $HOSTNAME\.$DOMAIN_NAME

echo --------------------------------------------------
echo "Creating smb environment"
echo --------------------------------------------------
if [[  -f /etc/samba/smb.conf ]]; then
	echo "Backing up ... "
	mv -vf /etc/samba/smb.conf /etc/samba/smb.conf.original
fi

echo -n "Creating SMB.CONF... "
touch $SAMBA_CONF && echo "ok." || echo "FAILED"
echo -n "Creating Samba Directories ..."
mkdir -p /var/lib/samba/private /var/lib/samba/usershares && echo "ok." || echo "FAILED"
chmod +t /var/lib/samba/usershares

echo --------------------------------------------------
echo "Generating Samba configuration: \"$SAMBA_CONF\""
echo --------------------------------------------------

#crudini --set $SAMBA_CONF global "vfs objects" "acl_xattr"
#crudini --set $SAMBA_CONF global "map acl inherit" "yes"
crudini --set $SAMBA_CONF global "store dos attributes" "no"
crudini --set $SAMBA_CONF global "ea support" "no"
crudini --set $SAMBA_CONF global "wide links" "yes"
crudini --set $SAMBA_CONF global "unix extensions" "no"
# crudini --set $SAMBA_CONF global "guest account" "$GUEST_USERNAME"

crudini --set $SAMBA_CONF global "netbios name" "$HOSTNAME"
crudini --set $SAMBA_CONF global "workgroup" "$WORKGROUP"
crudini --set $SAMBA_CONF global "server string" "$SERVER_STRING"

# Add the IPs / subnets allowed acces to the server in general.
crudini --set $SAMBA_CONF global "hosts allow" "$HOSTS_ALLOW"

# log files split per-machine.
crudini --set $SAMBA_CONF global "log file" "$LOG_FILE"

# Enable debug
crudini --set $SAMBA_CONF global "log level" "$LOG_LEVEL"

# Maximum size per log file, then rotate.
crudini --set $SAMBA_CONF global "max log size" "$MAX_LOG_SIZE"

# Active Directory
crudini --set $SAMBA_CONF global "security" "$SECURITY"
# crudini --set $SAMBA_CONF global "encrypt passwords" "$ENCRYPT_PASSWORDS"
crudini --set $SAMBA_CONF global "passdb backend" "tdbsam"
crudini --set $SAMBA_CONF global "realm" "$REALM"

crudini --set $SAMBA_CONF global "rpc start on demand helpers" "$RPC_START_ONDEMAND_HELPERS"

# Disable Printers.
crudini --set $SAMBA_CONF global "load printers" "no"
crudini --set $SAMBA_CONF global "printing" "bsd"
crudini --set $SAMBA_CONF global "disable spoolss" "yes"
crudini --set $SAMBA_CONF global "printcap name" "/dev/null"
crudini --set $SAMBA_CONF global "panic action" "no"
crudini --set $SAMBA_CONF global "cups options" "raw"

# Name resolution order
crudini --set $SAMBA_CONF global "name resolve order" "$NAME_RESOLVE_ORDER"

# Performance Tuning
crudini --set $SAMBA_CONF global "socket options" "$SOCKET_OPTIONS"
crudini --set $SAMBA_CONF global "read raw" "$READ_RAW"
crudini --set $SAMBA_CONF global "write raw" "$WRITE_RAW"
crudini --set $SAMBA_CONF global "oplocks" "$OPLOCKS"
crudini --set $SAMBA_CONF global "level2 oplocks" "$LEVEL2_OPLOCKS"
crudini --set $SAMBA_CONF global "kernel oplocks" "$KERNEL_OPLOCKS"
crudini --set $SAMBA_CONF global "max xmit" "$MAX_XMIT"
crudini --set $SAMBA_CONF global "dead time" "$DEAD_TIME"
crudini --set $SAMBA_CONF global "max open files" "$MAX_OPEN_FILES"

# Point to specific kerberos server
crudini --set $SAMBA_CONF global "password server" "*"

# #crudini --set $SAMBA_CONF global "winbind separator" "$WINBIND_SEPARATOR"
crudini --set $SAMBA_CONF global "winbind uid" "$WINBIND_UID"
crudini --set $SAMBA_CONF global "winbind gid" "$WINBIND_GID"
crudini --set $SAMBA_CONF global "winbind use default domain" "$WINDBIND_USE_DEFAULT_DOMAIN"
crudini --set $SAMBA_CONF global "winbind enum users" "$WINBIND_ENUM_USERS"
crudini --set $SAMBA_CONF global "winbind enum groups" "$WINBIND_ENUM_GROUPS"

crudini --set $SAMBA_CONF global "idmap config * : backend" "tdb"
crudini --set $SAMBA_CONF global "idmap config * : range" "5000-80000"
crudini --set $SAMBA_CONF global "idmap config $WORKGROUP : backend" "rid"
crudini --set $SAMBA_CONF global "idmap config $WORKGROUP : range" "100000-9999999"

crudini --set $SAMBA_CONF global "template homedir" "$TEMPLATE_HOMEDIR"
crudini --set $SAMBA_CONF global "template shell" "$TEMPLATE_SHELL"
# crudini --set $SAMBA_CONF global "client use spnego" "$CLIENT_USE_SPNEGO"
# crudini --set $SAMBA_CONF global "client ntlmv2 auth" "$CLIENT_NTLMV2_AUTH"
# crudini --set $SAMBA_CONF global "encrypt passwords" "$ENCRYPT_PASSWORDS"
crudini --set $SAMBA_CONF global "server signing" "$SERVER_SIGNING"
crudini --set $SAMBA_CONF global "smb encrypt" "$SMB_ENCRYPT"
crudini --set $SAMBA_CONF global "restrict anonymous" "$RESTRICT_ANONYMOUS"
crudini --set $SAMBA_CONF global "domain master" "$DOMAIN_MASTER"
crudini --set $SAMBA_CONF global "local master" "$LOCAL_MASTER"
crudini --set $SAMBA_CONF global "preferred master" "$PREFERRED_MASTER"
crudini --set $SAMBA_CONF global "os level" "$OS_LEVEL"
# crudini --set $SAMBA_CONF global "wins support" "$WINS_SUPPORT"
# crudini --set $SAMBA_CONF global "wins server" "$WINS_SERVER"
crudini --set $SAMBA_CONF global "dns proxy" "$DNS_PROXY"
crudini --set $SAMBA_CONF global "log level" "$LOG_LEVEL"
crudini --set $SAMBA_CONF global "debug timestamp" "$DEBUG_TIMESTAMP"
crudini --set $SAMBA_CONF global "log file" "$LOG_FILE"
crudini --set $SAMBA_CONF global "max log size" "$MAX_LOG_SIZE"
# crudini --set $SAMBA_CONF global "syslog only" "$SYSLOG_ONLY"
# crudini --set $SAMBA_CONF global "syslog" "$SYSLOG"
# crudini --set $SAMBA_CONF global "panic action" "$PANIC_ACTION"
# crudini --set $SAMBA_CONF global "hosts allow" "$HOSTS_ALLOW"

# Inherit groups in groups
crudini --set $SAMBA_CONF global "winbind nested groups" "no"
crudini --set $SAMBA_CONF global "winbind refresh tickets" "yes"
crudini --set $SAMBA_CONF global "winbind offline logon" "true"
crudini --set $SAMBA_CONF global "winbind expand groups" "1"
crudini --set $SAMBA_CONF global "winbind scan trusted domains" "no"


# Kerberos
crudini --set $SAMBA_CONF global "dedicated keytab file" "$DEDICATED_KEYTAB_FILE"
crudini --set $SAMBA_CONF global "kerberos method" "$KERBEROS_METHOD"


# home shared directory (restricted to owner)
crudini --set $SAMBA_CONF homes "comment" "Home Directories"
crudini --set $SAMBA_CONF homes "path" "%H"
crudini --set $SAMBA_CONF homes "public" "no"
crudini --set $SAMBA_CONF homes "guest ok" "no"
crudini --set $SAMBA_CONF homes "read only" "yes"
crudini --set $SAMBA_CONF homes "writeable" "no"
crudini --set $SAMBA_CONF homes "create mask" "0777"
crudini --set $SAMBA_CONF homes "directory mask" "0777"
crudini --set $SAMBA_CONF homes "browseable" "no"
crudini --set $SAMBA_CONF homes "printable" "no"
crudini --set $SAMBA_CONF homes "oplocks" "yes"
crudini --set $SAMBA_CONF homes "valid users" "%S"
crudini --set $SAMBA_CONF homes "hide unreadable" "yes"
crudini --set $SAMBA_CONF homes "hide dot files" "yes"
crudini --set $SAMBA_CONF homes "inherit acls" "yes"
crudini --set $SAMBA_CONF homes "acl allow execute always" "yes"

# private shared directory (restricted) - $SHARED_DIRECTORY ex: /tmp
#mkdir -p "$SHARED_DIRECTORY"
#crudini --set $SAMBA_CONF $SHARE_NAME "comment" "Shared Directory"
#crudini --set $SAMBA_CONF $SHARE_NAME "path" "$SHARED_DIRECTORY"
#crudini --set $SAMBA_CONF $SHARE_NAME "public" "yes"
#crudini --set $SAMBA_CONF $SHARE_NAME "guest ok" "no"
#crudini --set $SAMBA_CONF $SHARE_NAME "read only" "yes"
#crudini --set $SAMBA_CONF $SHARE_NAME "writeable" "no"
#crudini --set $SAMBA_CONF $SHARE_NAME "create mask" "0774"
#crudini --set $SAMBA_CONF $SHARE_NAME "directory mask" "0050"
#crudini --set $SAMBA_CONF $SHARE_NAME "browseable" "no"
#crudini --set $SAMBA_CONF $SHARE_NAME "printable" "no"
#crudini --set $SAMBA_CONF $SHARE_NAME "oplocks" "yes"
#crudini --set $SAMBA_CONF $SHARE_NAME "hide unreadable" "yes"


echo --------------------------------------------------
echo 'Verifying Keytab file on LIB DIR'
echo '(you should usit as a persistent volume for not '
echo 'creating it each time the pod is created)'
echo --------------------------------------------------
if [[ -f /var/lib/samba/krb5.keytab ]]; then
	echo -n "Exists..."
	ln -s /var/lib/samba/krb5.keytab ${DEDICATED_KEYTAB_FILE} && echo "Linked."
else
	echo "Does NOT exist."
fi

echo --------------------------------------------------
echo 'Registering to Active Directory'
echo --------------------------------------------------
echo -n "Registering Windows Machine ..."
if [[ ! -f ${DEDICATED_KEYTAB_FILE} ]]; then
	#echo --------------------------------------------------
	#echo 'Generating Kerberos ticket'
	#echo --------------------------------------------------
	# echo $AD_PASSWORD | kinit -V $AD_USERNAME@$REALM
	net ads join -U"$AD_USERNAME"%"$AD_PASSWORD" -S $PASSWORD_SERVER --no-dns-updates &&\
	mv ${DEDICATED_KEYTAB_FILE} /var/lib/samba/krb5.keytab && echo -n "Keytab moved..." &&\
	ln -s /var/lib/samba/krb5.keytab ${DEDICATED_KEYTAB_FILE} && echo -n "Keytab Linked." &&\
	echo "OK." || echo "Failed."

else
	echo "Already registered."
	echo "----------------------------------------------"
	echo "Verificando Status"
	echo "----------------------------------------------"
	service winbind start
	sleep 5
	wbinfo --online-status
fi

echo --------------------------------------------------
echo "Updating NSSwitch configuration: \"/etc/nsswitch.conf\""
echo --------------------------------------------------
if [[ ! `grep "winbind" /etc/nsswitch.conf` ]]; then
    sed -i "s#^\(passwd\:\s*files\)\s*\(.*\)\$#\1 \2 winbind#" /etc/nsswitch.conf
    sed -i "s#^\(group\:\s*files\)\s*\(.*\)\$#\1 \2 winbind#" /etc/nsswitch.conf

fi
pam-auth-update

# adjusting environment for cron
sed -i 1i"$(printenv | grep -E "^SHARED_DIRECTORY")" /etc/crontab
sed -i 1i"$(printenv | grep -E "^GROUP_PREFIX")" /etc/crontab


echo --------------------------------------------------
echo 'Stopping Samba to enable handling by supervisord'
echo --------------------------------------------------
service winbind stop
service nmbd stop
service smbd stop


exec "$@"
