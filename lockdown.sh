#!/bin/bash

sshd_port=$(($RANDOM + 10000))

echo Locking down sshd...
sed -i 's/^.*PermitRootLogin\(.*\)/#PermitRootLogin\1/' /etc/ssh/sshd_config
echo PermitRootLogin no >> /etc/ssh/sshd_config
sed -i 's/^.*PasswordAuthentication\(.*\)/#PasswordAuthentication\1/' /etc/ssh/sshd_config
echo PasswordAuthentication no >> /etc/ssh/sshd_config
sed "s/^.*Port .*$/Port ${sshd_port}/" /etc/ssh/sshd_config
service ssh restart
echo Done.

echo Setting up firewall...
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 2245 -j ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P INPUT DROP
iptables-save | tee /etc/sysconfig/iptables
echo Done.

echo <<-EOM
Dev Bootstrapping Complete!
===========================
NOTE!   Before you log out, place your public key in
~/.ssh/authorized_keys.  You will not be able to log in again
via password.

Other changes...
- You can no longer log in via password.  You must place your
  public key in ~/.ssh/authorized_keys.
- SSH is now listening on port ${sshd_port}.  You will need
  to use that from now on.
- Root can no longer log in.
- Only ports 80, 443 and ${sshd_port} are open to the outside
  world.
EOM
