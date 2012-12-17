# elevate to sudo to get shit done
su -
apt-get update
apt-get install openswan xl2tpd ppp

# wipe an existing files from the output dir
rm -rf templates/output/*

# set up ipsec
echo "Please enter the external IP address of this box:"
read ip
cp templates/ipsec.conf templates/output/ipsec.conf
sed -ie 's/<IP>/'$ip'/g' templates/output/ipsec.conf
cp -f templates/output/ipsec.conf /etc/ipsec.conf

# set up the ipsec secret
echo "Please enter a secure password (long as possible) for ipsec to use:"
read ipsecpass
cp templates/ipsec.secrets templates/output/ipsec.secrets
sed -ie 's/<PASS>/'$ip'/g' templates/output/ipsec.secrets
cp -f templates/output/ipsec.secrets /etc/ipsec.secrets

# set up l2tp
echo "Enter a name for your VPN (e.g. DeanVPN):"
read vpnname
cp templates/xl2tpd.conf templates/output/xl2tpd.conf
sed -ie 's/<NAME>/'$vpnname'/g' templates/output/xl2tpd.conf
cp -f templates/output/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf

# set up ppp
echo "Enter a DNS server to use (e.g Google DNS is 8.8.8.8):"
read dns
cp templates/options.xl2tpd templates/output/options.xl2tpd
sed -ie 's/<DNS>/'$dns'/g' templates/output/options.xl2tpd
cp -f templates/output/options.xl2tpd /etc/xl2tpd/options.xl2tpd

# set up the ppp secret
echo "Please enter another secure password for ppp to use:"
read otherpass
cp templates/chap-secrets templates/output/chap-secrets
sed -ie 's/<PASS>/'$otherpass'/g' templates/output/chap-secrets
cp -f templates/output/chap-secrets /etc/xl2tpd/chap-secrets

# configure the firewall and open ports 500,4500 & 1701 for UDP
iptables -I INPUT -p udp --dport 500 -j ACCEPT
iptables -I INPUT -p udp --dport 4500 -j ACCEPT
iptables -I INPUT -p udp --dport 1701 -j ACCEPT
service iptables save

# make sure traffic forwarding works
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE

# enable ip forwarding for ipv4
echo 1 > /proc/sys/net/ipv4/ip_forwarding

# restart all services
/etc/init.d/xl2tpd restart
/etc/init.d/ipsec restart

echo "Installer complete."
