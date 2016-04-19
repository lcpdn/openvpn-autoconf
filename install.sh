echo "Script d'autoconfiguration d'un serveur OpenVPN. Verifiez que ce script répond à vos besoins, vous êtes seuls responsables de sa bonne utilisation"
echo "Entree des parametres de personnalisation du VPN"

echo -n "Entrez l'adresse IP du serveur dans le réseau du VPN   "
read IP_SERVEUR_SERVER
sed -i 's/IP_SERVEUR_SERVER/'$IP_SERVEUR_SERVER'/g' /tmp/openvpn-autoconf/server.conf

echo -n "Entrez le masque du réseau VPN (au format 255.255.0.0)   "
read MASQUE_SERVEUR_SERVER
sed -i 's/MASQUE_SERVEUR_SERVER/'$MASQUE_SERVEUR_SERVER'/g' /tmp/openvpn-autoconf/server.conf

echo -n "Entrez l'hote externe (sur Internet) du serveur VPN   "
read HOTE_SERVEUR_EXTERNE
sed -i 's/HOTE_SERVEUR_EXTERNE/'$HOTE_SERVEUR_EXTERNE'/g' /tmp/openvpn-autoconf/client.conf

echo " "
echo "Parametrage des certificats du VPN"
echo -n "Entrez votre code pays (2 caractères)   "
read KEY_COUNTRY
sed -i 's/VAR_KEY_COUNTRY/'$KEY_COUNTRY'/g' /tmp/openvpn-autoconf/vars
echo "Parametrage des certificats du VPN"
echo -n "Entrez votre code région (3 caractères)   "
read KEY_PROVINCE
sed -i 's/VAR_KEY_PROVINCE/'$KEY_PROVINCE'/g' /tmp/openvpn-autoconf/vars
echo -n "Entrez votre ville   "
read KEY_CITY
sed -i 's/VAR_KEY_CITY/'$KEY_CITY'/g' /tmp/openvpn-autoconf/vars
echo -n "Entrez votre organisation   "
read KEY_ORG
sed -i 's/VAR_KEY_ORG/'$KEY_ORG'/g' /tmp/openvpn-autoconf/vars
echo -n "Entrez votre organisation   "
read KEY_ORG
sed -i 's/VAR_KEY_ORG/'$KEY_ORG'/g' /tmp/openvpn-autoconf/vars
echo -n "Entrez votre adresse mail de contact   "
read KEY_EMAIL
sed -i 's/VAR_KEY_EMAIL/'$KEY_EMAIL'/g' /tmp/openvpn-autoconf/vars
echo -n "Entrez l'unite de votre organisation   "
read KEY_EMAIL
sed -i 's/VAR_KEY_OU/'$KEY_OU'/g' /tmp/openvpn-autoconf/vars

echo "Fin de parametrage des certificats "
echo " "
echo "Mise a jour des paquets logiciels"
apt-get update
apt-get upgrade
echo "Installation d'OpenVPN"
apt-get install openvpn
mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa	

echo "Generation de la conf et creation des clefs"
rm vars
cp /tmp/vars/
source vars
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
openvpn --genkey --secret keys/ta.key
cp keys/ca.crt keys/ta.key keys/server.crt keys/server.key keys/dh2048.pem /etc/openvpn/ 
mkdir /etc/openvpn/jail
mkdir /etc/openvpn/clientconf

echo "Recuperation des fichiers de configuration serveur"
cd /tmp/openvpn-autoconf/
cp ./server.conf /etc/openvpn/server.conf
rm server.conf

echo "Configuration du routage"
sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j MASQUERADE

echo "Configuration des clefs clients"
cd /etc/openvpn/easy-rsa
source vars
./build-key-pass mon-serveur-vpn
mkdir /etc/openvpn/clientconf/mon-serveur-vpn
cp /etc/openvpn/ca.crt /etc/openvpn/ta.key keys/mon-serveur-vpn.crt keys/mon-serveur-vpn.key /etc/openvpn/clientconf/mon-serveur-vpn/
cd /etc/openvpn/clientconf/mon-serveur-vpn/

echo "Creation d'un package de configuration pour les clients"
cp /tmp/openvpn-autoconf/client.conf ./
cp client.conf client.ovpn
cd ..
tar zcvf vpnconf.tgz mon-serveur-vpn
echo "L'archive d'installation est disponible dans le repertoire /etc/openvpn/clientconf/"
echo "Suppression du repertoire d'installation"
rm -rf /tmp/openvpn-autoconf/
