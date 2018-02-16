#!/bin/sh

LDAPADDCMD="ldapadd"
SLAPPASSWORD="slappasswd"
SECRET="redhat"
LDAPPASS="crevise"
HOMEDIR="/home/users"
SKEL="/etc/skel"
GID="501"
TMP="/home/ubuntu/openldapscript/tmp/"
DOMAIN="dc=ec2-13-127-170-246,dc=ap-south-1,dc=compute,dc=amazonaws,dc=com"


if [ -z $1 ];  then
	echo "addldapuser.sh <username>"
	exit 1
fi

USERNAME=$1

stty_orig=`stty -g`
echo -n "Enter user Password: "
stty -echo
read USERPASS
stty $stty_orig

echo
PASSWORD=`$SLAPPASSWORD -h "{SSHA}" -s $USERPASS`

UID=`echo $[ 1000 + $[ RANDOM % 65535 ]]`

(
cat <<add-user
dn: cn=$USERNAME,ou=users,$DOMAIN
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: $USERNAME
uid: $USERNAME
uidNumber: $UID
gidNumber: $GID
userPassword: $PASSWORD
loginShell: /bin/bash
homeDirectory: /home/users/$USERNAME
add-user
) > $TMP/adduser.ldif

$LDAPADDCMD -x -w $LDAPPASS -D "cn=admin,$DOMAIN" -f $TMP/adduser.ldif && rm $TMP/adduser.ldif 

if [ $? -ne "0" ]; then
	echo "Add user failed"
	echo "Please review $TMP/adduser.ldif and add the account manually"
else
#	mkdir -p $HOMEDIR/$USERNAME
	cp -Rv $SKEL $HOMEDIR/$USERNAME
	chown -Rv $LUID:$LUID $HOMEDIR/$USERNAME
fi
