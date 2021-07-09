#! /bin/bash
apt-get install -y winbind samba smbclient libnss-winbind libpam-winbind krb5-user krb5-config libpam-ccreds libkrb5-dev

mkdir /root/originials

cp /etc/krb5.conf /root/originials/krb5.conf
cp /etc/samba/smb.conf /root/originials/smb.conf
cp /etc/hosts /root/originials/hosts
cp /etc/nsswitch.conf /root/originials/nsswitch.conf

localhostname="eserver"
hostip="172.19.21.*"
adip="172.19.21.*"
domainip="172.19.21.*"
ad="ad FQDN"
workgroup="enter workgroup"
default_domain="domain name"
sharepath="/share"
WriteGroup="username"
ReadGroup="group"

hostnamectl set-hostname "$localhostname"

mkdir "$sharepath"

chmod a+rwx "$sharepath"

## adding /etc/hosts file
echo "
127.0.0.1       localhost
127.0.1.1       "$localhostname"
"$hostip"   "$localhostname"
"$adip"  "$ad"

" > /etc/hosts
# ading /etc/resolve.conf
echo "
search "$default_domain"
nameserver "$domainip"
" >> /etc/resolve.conf


## ading /etc/krb5.conf

echo "
[logging]
    default = FILE:/var/log/krb5.log

[libdefaults]
    default_realm = "$default_domain"
    kdc_timesync = 1
    ccache_type = 4
    forwardable = true
    proxiable = true
 
 
[realms]
    "$default_domain" = {
        kdc = "$ad"
        admin_server = "$ad"
        default_domain = "$default_domain"
    }
 
 
	[domain_realm]
		.philips-neuro.private = "$default_domain"
		 philips-neuro.private = "$default_domain"
    " > /etc/krb5.conf

## ading samba config /etc/samba/smb.conf

echo "

[global]
        security = ads
        realm = "$default_domain"
# If the system doesn't find the domain controller automatically, you may need the following line
        password server = "$adip"
# note that workgroup is the 'short' domain name
        workgroup = "$workgroup"
        idmap uid = 10000-20000
        idmap gid = 10000-20000
        winbind enum users = yes
        winbind enum groups = yes
        client use spnego = yes
        client ntlmv2 auth = yes
        encrypt passwords = yes

[eagle]
        comment = eagle
        path = "$sharepath"
        valid users = "@$workgroup"\\"$WriteGroup"
        writable = yes
        read only = no
        create mask =  0677
        directory mask = 777
        force directory mode = 2770

[eagle]
        comment = eagle
        path = "$sharepath"
        read list = "@$workgroup"\\"$ReadGroup"
        writable = yes
        read only = no
        create mask =  0677
        directory mask = 777
        force directory mode = 2770
" > /etc/samba/smb.conf

		
## adding /etc/nsswitch.conf

echo "
# /etc/nsswitch.conf
#
# Example configuration of GNU Name Service Switch functionality.
# If you have the `glibc-doc-reference' and `info' packages installed, try:
# `info libc "Name Service Switch"' for information about this file.

passwd:         compat winbind
group:          compat winbind
shadow:         compat winbind
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
" > /etc/nsswitch.conf

systemctl stop winbind
systemctl smbd restart
systemctl start winbind 

systemctl enable winbind
systemctl enable smbd


##kinit Administrator

##net ads join -U Administrator




wbinfo –u
wbinfo –g
