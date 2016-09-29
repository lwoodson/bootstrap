#!/bin/bash

echo Locking down sshd...
sed -i 's/^.*PermitRootLogin\(.*\)/#PermitRootLogin\1/' /etc/ssh/sshd_config
echo PermitRootLogin no >> /etc/ssh/sshd_config
sed -i 's/^.*PasswordAuthentication\(.*\)/#PasswordAuthentication\1/' /etc/ssh/sshd_config
echo PasswordAuthentication no >> /etc/ssh/sshd_config
echo Done.

echo Setting up firewall...
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P INPUT DROP
iptables-save | tee /etc/sysconfig/iptables
echo Done.

echo <<-EOM
Dev Bootstrapping Complete!
===========================
Root can no longer log in and only ports 80, 443 and 22 are
open to the outside world.
EOM
