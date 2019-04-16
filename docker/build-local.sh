#!/bin/bash

DIR=/tmp
VERSION=4.8.1
DISTDIR="/opt/pontus/pontus-samba";
TARFILE=$DIR/pontus-samba-${VERSION}.tar.gz

CURDIR=`pwd`
cd $DIR

echo DIR is $DIR
echo TARFILE is $TARFILE

#if [[ ! -f $TARFILE ]]; then

yum -y install attr bind-utils docbook-style-xsl gcc gdb krb5-workstation        libsemanage-python libxslt perl perl-ExtUtils-MakeMaker        perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python        python-crypto gnutls-devel libattr-devel keyutils-libs-devel        libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel        pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel wget


wget https://download.samba.org/pub/samba/stable/samba-${VERSION}.tar.gz

#6F33915B6568B7EA
tar xvzf samba-${VERSION}.tar.gz

cd samba-${VERSION}
./configure --prefix=/opt/pontus/pontus-samba/${VERSION}
make -j 4
make install


#tar cpzvf ${TARFILE} /opt/pontus/pontus-samba

#fi

if [[ ! -d $DISTDIR ]]; then
  mkdir -p $DISTDIR
fi

#cd $DISTDIR/../../../
#cd $DISTDIR
cd /opt/pontus/pontus-samba
ln -s $VERSION current
cd current

cat <<'EOF' >> config-samba.sh
#!/bin/bash

if [[ -f "/etc/krb5.conf" ]]; then
  mv /etc/krb5.conf /etc/krb5.conf.orig
fi

cat << 'EOF2' >> /etc/krb5.conf
[libdefaults]
  renew_lifetime = 700d
  forwardable = true
  default_realm = PONTUSVISION.COM
  ticket_lifetime = 24d
  dns_lookup_realm = false
  dns_lookup_kdc = false
  default_ccache_name = /tmp/krb5cc_%{uid}
  #default_tgs_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5
  #default_tkt_enctypes = aes des3-cbc-sha1 rc4 des-cbc-md5

[domain_realm]
  pontusvision.com = PONTUSVISION.COM

[logging]
  default = FILE:/var/log/krb5kdc.log
  admin_server = FILE:/var/log/kadmind.log
  kdc = FILE:/var/log/krb5kdc.log

[realms]
  PONTUSVISION.COM = {
    admin_server = pontus-sandbox.pontusvision.com
    kdc = pontus-sandbox.pontusvision.com
  }

EOF2

> /etc/systemd/system/samba.service

cat << 'EOF2' >> /etc/systemd/system/samba.service
[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/opt/pontus/pontus-samba/current/sbin/samba -D
PIDFile=/opt/pontus/pontus-samba/current/var/run/samba.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target

EOF2


export HOSTNAME=`hostname -f`
export IPADDR=`hostname -I`
export PATH=$PATH:/opt/pontus/pontus-samba/current/bin/:/opt/pontus/pontus-samba/current/sbin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
samba-tool domain provision --domain=PONTUSVISION --host-name=$HOSTNAME --host-ip $IPADDR --site=PONTUSVISION.COM --adminpass=pa55wordpa55wordPASSWD999 --krbtgtpass=pa55wordpa55wordPASSWD999 --machinepass=pa55wordpa55wordPASSWD999 --dnspass=pa55wordpa55wordPASSWD999  --ldapadminpass=pa55wordpa55wordPASSWD999 --server-role=dc --use-rfc2307 --realm=PONTUSVISION.COM
if [[ ! -d '/etc/samba' ]] ; then
  ln -s /opt/pontus/pontus-samba/current/etc /etc/samba
fi


>  /opt/pontus/pontus-samba/current/etc/smb.conf
cat << 'EOF2' >> /opt/pontus/pontus-samba/current/etc/smb.conf
# Global parameters
[global]
        dns forwarder = 8.8.8.8
        netbios name = PONTUS-SANDBOX
        realm = PONTUSVISION.COM
        server role = active directory domain controller
        workgroup = PONTUSVISION
        idmap_ldb:use rfc2307 = yes
        kdc:user ticket lifetime = 10000
        kdc:service ticket lifetime = 10000
        kdc:renewal lifetime = 168000
        tls enabled  = yes
        tls keyfile  = /etc/pki/java/localhost.pem
        tls certfile = /etc/pki/java/localhost.crt
        tls cafile   = /etc/pki/java/root-ca.crt




[netlogon]
        path = /opt/pontus/pontus-samba/4.8.1/var/locks/sysvol/pontusvision.com/scripts
        read only = No

[sysvol]
        path = /opt/pontus/pontus-samba/4.8.1/var/locks/sysvol
        read only = No
EOF2



if [[ ! -d '/etc/security/keytabs' ]] ; then 
  mkdir /etc/security/keytabs 
fi

samba_upgradedns --dns-backend=SAMBA_INTERNAL

samba-tool dns add 127.0.0.1  pontusvision.com pontus-sandbox A `hostname -I` --password=pa55wordpa55wordPASSWD999 --username=Administrator

samba-tool dns zonecreate  `hostname` 2.0.17.172.in-addr.arpa --password=pa55wordpa55wordPASSWD999 --username=Administrator
samba-tool dns add 127.0.0.1 2.0.17.172.in-addr.arpa 2.0.17.172.in-addr.arpa  PTR pontus-sandbox.pontusvision.com -UAdministrator --password=pa55wordpa55wordPASSWD999
samba-tool user setexpiry Administrator --noexpiry



samba-tool user create kafka/pontus-sandbox.pontusvision.com pa55wordBig4Data4Admin
samba-tool spn add kafka/pontus-sandbox.pontusvision.com  kafka/pontus-sandbox.pontusvision.com --realm=PONTUSVISION.COM
samba-tool domain exportkeytab /etc/security/keytabs/kafka.service.keytab --principal=kafka/pontus-sandbox.pontusvision.com@PONTUSVISION.COM
samba-tool user setexpiry kafka/`hostname -f` --noexpiry
samba-tool user create hbase/pontus-sandbox.pontusvision.com pa55wordBig4Data4Admin
samba-tool spn add hbase/pontus-sandbox.pontusvision.com  hbase/pontus-sandbox.pontusvision.com --realm=PONTUSVISION.COM
samba-tool domain exportkeytab /etc/security/keytabs/hbase.service.keytab --principal=hbase/pontus-sandbox.pontusvision.com@PONTUSVISION.COM
samba-tool user setexpiry hbase/`hostname -f` --noexpiry
samba-tool user create zookeeper/pontus-sandbox.pontusvision.com pa55wordBig4Data4Admin
samba-tool spn add zookeeper/pontus-sandbox.pontusvision.com zookeeper/pontus-sandbox.pontusvision.com --realm=PONTUSVISION.COM
samba-tool domain exportkeytab /etc/security/keytabs/zookeeper.service.keytab --principal=zookeeper/pontus-sandbox.pontusvision.com@PONTUSVISION.COM
samba-tool user setexpiry zookeeper/`hostname -f` --noexpiry

chown -R pontus: /etc/security/keytabs/

EOF

chmod 755 config-samba.sh
cd $CURDIR

#rm -rf samba-4.8.0*

#export PATH=$PATH:/opt/pontus/pontus-samba/bin/:/opt/pontus/pontus-samba/sbin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

