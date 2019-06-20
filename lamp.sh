#! /bin/bash

# This script is a one click install of httpd, Mariadb, phpmyadmin
# with full configuration of virtual hosts and ssl certificate with
# support of python(mod_wsgi), php(mod_php)

# Syncing time

echo "http://classroom.example.com" >> /etc/chrony.conf
systemctl restart chronyd.service

# Taking server machine number

read -p "Machine Number : " X
echo "172.25.$X.11 		server$X.example.com" > hostname
# Installing packages

echo "================== Installation of packages ===================" >> output
echo "================== Installation of packages ===================" >> error
yum install httpd mod_ssl mod_wsgi mod_php mariadb mariadb-client postfix -y >> output 2>> error

# Restarting services

echo "================== Restarting services ===================" >> output
echo "================== Restarting services ===================" >> error
systemctl restart httpd >> output 2>> error
systemctl restart mysql >> output 2>> error
systemctl restart postfix >> output 2>> error
systemctl enable httpd >> output 2>> error
systemctl enable mysql >> output 2>> error
systemctl enable postfix >> output 2>> error

# Storing service status

echo "================== Services status of packages ===================" >> output
echo "================== Services status of packages ===================" >> error
systemctl status httpd >> output 2>> error
systemctl status mysql >> output 2>> error
systemctl status postfix >> output 2>> error

# Applying firewall on services

echo "================== Applying firewall ===================" >> output
echo "================== Applying firewall ===================" >> error
firewall-cmd --permanent --add-service=https >> output 2>> error
firewall-cmd --permanent --add-service=http >> output 2>> error
firewall-cmd --permanent --add-service=smtp >> output 2>> error
firewall-cmd --permanent --add-service=mysql >> output 2>> error
firewall-cmd --reload
firewall-cmd --list-all
# Time date INFO

date > dateInfo
timedatectl >> dateInfo

# Configureing Apache, creating apache conf file and creating two virtual sites

touch /etc/httpd/conf.d/MohitServer.conf
read -p "Name of first site (http) : " SITE1
read -p "Directory of first site : " SITE1DIR
read -p "Name of second site (https) : " SITE2
read -p "Directory of second site : " SITE2DIR

echo "<VirtualHost *:80>" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerAdmin 		root@server$X.example.com" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerName 			$SITE1" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerAlias 		www.$SITE1" >> /etc/httpd/conf.d/MohitServer.conf
echo "	DocumentRoot 		$SITE1DIR" >> /etc/httpd/conf.d/MohitServer.conf
echo "</VirtualHost>" >> /etc/httpd/conf.d/MohitServer.conf

# Downloading certificate files

echo "================== Applying firewall ===================" >> error

echo "wget -p /etc/pki/tls/certs/ http://classroom.example.com/pub/tls/certs/server$X.crt" > certfile.sh 2>> error
echo "wget -p /etc/pki/tls/private/ http://classroom.example.com/pub/tls/private/server$X.key" >> certfile.sh 2>> error
echo "wget -p /etc/pki/tls/certs/ http://classroom.example.com/pub/tls/certs/example-ca.crt" >> certfile.sh 2>> error
./certfile.sh
#rm certfile.sh

# Second Site entry

echo "<VirtualHost *:443>" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerAdmin 		root@server$X.example.com" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerName 			$SITE2" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerAlias 		www.$SITE2" >> /etc/httpd/conf.d/MohitServer.conf
echo "	DocumentRoot 		$SITE2DIR" >> /etc/httpd/conf.d/MohitServer.conf
echo "	sslengine 		on" >> /etc/httpd/conf.d/MohitServer.conf
echo "	sslcertificatefile 		/etc/pki/tls/certs/server$X.crt" >> /etc/httpd/conf.d/MohitServer.conf
echo "	sslcertificatekeyfile 		/etc/pki/tls/certs/server$X.key" >> /etc/httpd/conf.d/MohitServer.conf
echo "	sslcertificatechainfile 		/etc/pki/tls/certs/example-ca.crt" >> /etc/httpd/conf.d/MohitServer.conf
echo "</VirtualHost>" >> /etc/httpd/conf.d/MohitServer.conf

# Redirecting entries

echo "<VirtualHost *:80>" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerName 			$SITE2" >> /etc/httpd/conf.d/MohitServer.conf
echo "	ServerAlias 		www.$SITE2" >> /etc/httpd/conf.d/MohitServer.conf
echo "	RewriteEngine	on" >> /etc/httpd/conf.d/MohitServer.conf
echo "	RewriteRule		^(/.*)$ https://%{HTTP_HOST)$1 [redirect=301]" >> /etc/httpd/conf.d/MohitServer.conf
echo "</VirtualHost>" >> /etc/httpd/conf.d/MohitServer.conf

# Giving root directories permisson

echo "<Directory $SITE1DIR>" >> /etc/httpd/conf.d/MohitServer.conf
echo "require all granted" >> /etc/httpd/conf.d/MohitServer.conf
echo "</Directory>" >> /etc/httpd/conf.d/MohitServer.conf

echo "<Directory $SITE2DIR>" >> /etc/httpd/conf.d/MohitServer.conf
echo "require all granted" >> /etc/httpd/conf.d/MohitServer.conf
echo "</Directory>" >> /etc/httpd/conf.d/MohitServer.conf

# Giving entries in system DNS

echo "172.25.$X.11		$SITE1" >> /etc/hosts
echo "172.25.$X.11		$SITE2" >> /etc/hosts
echo "172.25.$X.11		www.$SITE1" >> /etc/hosts
echo "172.25.$X.11		www.$SITE2" >> /etc/hosts

# Making website data with SElinux context

echo "mkdir $SITE1DIR" > content.sh
echo "mkdir $SITE2DIR" >> content.sh
echo "touch $SITE1DIR/index.html" >> content.sh
echo "touch $SITE2DIR/index.html" >> content.sh
echo "echo \"<h1 style=\"text-align: center;\">Welcome to $SITE1</h1>\" >> $SITE1DIR/index.html" >> content.sh
echo "echo \"<h1 style=\"text-align: center;\">Welcome to $SITE2</h1>\" >> $SITE2DIR/index.html" >> content.sh
echo "semanage fcontext $SITE1DIR/index.html" >> content.sh
echo "touch $SITE2DIR/index.html" >> content.sh
./content.sh
#rm content.sh

# Configuring mariadb (mysql)

ss -tulpn | grep mysql > mysqlfile
echo "skip-networking=1" >>/etc/my.cnf
systemctl restart mariadb &>> mysqlfile 
ss -tulpn | grep mysql >> mysqlfile
#rm mysqlfile

# Configuring postfix (Mail-server)









echo "================== Restarting services IN END ===================" >> output
echo "================== Restarting services IN END ===================" >> error
systemctl restart httpd >> output 2>> error
systemctl restart mysql >> output 2>> error
systemctl restart postfix >> output 2>> error
systemctl enable httpd >> output 2>> error
systemctl enable mysql >> output 2>> error
systemctl enable postfix >> output 2>> error
firewall-cmd --reload