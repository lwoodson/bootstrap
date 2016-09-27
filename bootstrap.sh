#!/bin/bash
set -o nounset
set -o errexit

user=${1}
email=${2}
homedir=/home/${1}
hostname=$(hostname)
ip=$(ifconfig | grep eth0 -A 1| grep inet | awk '{print $2}')
password=$(openssl rand -base64 32)

install_packages() {
    echo Installing packages...
    yum update
    yum install -y epel-release
    yum groupinstall -y "Development Tools"
    yum install -y telnet nmap-ncat nmap bind-utils lsof tcpdump iotop traceroute \
                   tmux vim ctags git docker libyaml-devel readline-devel zlib-devel \
                   libffi-devel openssl-devel sqlite-devel ack jq sysstat
    echo Done.
}

setup_host() {
    echo Setting up host...
    sed -i 's/^%wheel.*/%wheel  ALL=(ALL)   NOPASSWD: ALL/' /etc/sudoers
    echo Done.
}

setup_user() {
    echo Setting up user ${user}...
    if ! [[ $(getent passwd ${user}) ]]; then
        useradd ${user}
    	echo ${password} | passwd ${user} --stdin
    	chage -d 0 ${user}
    fi
    usermod -aG wheel ${user}
    mkdir -p ${homedir}/src
    echo Done.
}

setup_ssh() {
    echo Setting up SSH...
    mkdir -p ${homedir}/.ssh
    chmod 700 ${homedir}/.ssh
    ssh-keygen -N "" -t rsa -b 4096 -f id_rsa -C "${email}"
    mv id_rsa* ${homedir}/.ssh/
    chmod 644 ${homedir}/.ssh/id_rsa.pub
    chmod 600 ${homedir}/.ssh/id_rsa
    chown -R ${user}:${user} ${homedir}/.ssh
    echo Done.
}

setup_dotfiles() {
    echo Setting up ${user}\'s dotfiles...
    cp dots/bashrc ${homedir}/.bashrc
    cp dots/bash_profile ${homedir}/.bash_profile
    cp dots/profile ${homedir}/.profile
    cp dots/tmux.conf ${homedir}/.tmux.conf
    cp dots/vimrc ${homedir}/.vimrc
    cp dots/gitconfig ${homedir}/.gitconfig
    sed -i "s/<USER>/${user}/" ${homedir}/.gitconfig
    sed -i "s/<EMAIL>/${email}/" ${homedir}/.gitconfig
    touch ${homedir}/.local_bashrc
    touch ${homedir}/.local_profile
    echo Done.
}

setup_vim() {
    echo Setting up vim...
    rm -rf ${homedir}/.vim   
    cp -r vim ${homedir}/.vim

    # https://github.com/junegunn/vim-plug
    curl -fLo ${homedir}/.vim/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    chown -R ${user}:${user} ${homedir}
    echo Done.
}

install_python() {
    echo Installing Python
    yum install -y python python-setuptools python-pip
    pip install --upgrade pip
    pip install virtualenv
    echo Done.
}

install_java() {
    echo Installing Java
    yum install -y java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.8.0-openjdk \
                   java-1.8.0-openjdk-devel maven
    echo Done.
}

install_ruby() {
    echo Installing Ruby
    su -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" -l ${user}
    su -c "curl -sSL https://get.rvm.io | bash -s stable" -l ${user}
    su -c "~/.rvm/bin/rvm install ruby" -l ${user}
    su -c "~/.rvm/bin/rvm install jruby" -l ${user}
    su -c "~/.rvm/bin/rvm alias create default ruby" -l ${user}
    echo Done.
}

install_dev_utilities() {
    echo Installing Dev Utilities...
    cp -R bin ${homedir}/bin
    chown -R ${user}:${user} ${homedir}/bin
    chmod +x ${homedir}/bin/*
    echo Done.
}

send_details_email() {
    echo Sending details email...
    sendmail ${email} <<-EOM
From: root@${hostname}
To: ${email}
Subject: New Computer Setup!

Here are the details...

hostname: ${hostname}
ip: ${ip}
user: ${user}
password: ${password}
EOM
    echo Done.
}

start_services() {
    echo Starting services...
    service docker restart
    echo Done.
}

install_packages
setup_host
setup_user
setup_ssh
setup_dotfiles
setup_vim
install_java
install_python
install_ruby
install_dev_utilities
send_details_email
