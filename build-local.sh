#!/bin/bash
yum -y install attr bind-utils docbook-style-xsl gcc gdb krb5-workstation        libsemanage-python libxslt perl perl-ExtUtils-MakeMaker        perl-Parse-Yapp perl-Test-Base pkgconfig policycoreutils-python        python-crypto gnutls-devel libattr-devel keyutils-libs-devel        libacl-devel libaio-devel libblkid-devel libxml2-devel openldap-devel        pam-devel popt-devel python-devel readline-devel zlib-devel systemd-devel


wget https://download.samba.org/pub/samba/stable/samba-4.8.0.tar.gz

#6F33915B6568B7EA
tar xvzf samba-4.8.0.tar.gz

cd samba-4.8.0
./configure --prefix=/opt/pontus/pontus-samba
make -j 4
make install

tar cpzvf ../pontus-samba-4.8.0.tar.gz /opt/pontus/pontus-samba


export PATH=$PATH:/opt/pontus/pontus-samba/bin/:/opt/pontus/pontus-samba/sbin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

