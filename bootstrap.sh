#!/bin/bash
set -o nounset
set -o errexit

user=${1}
email=${2}
homedir=/home/${1}
hostname=$(hostname)
ip=$(ifconfig | grep eth0 -A 1| grep inet | awk '{print $2}')
password=$(openssl rand -base64 32 | cut -c 1-6)
workdir=$(pwd)

install_packages() {
    echo Installing packages...
    yum -y update
    yum install -y epel-release
    yum groupinstall -y "Development Tools"
    yum install -y telnet nmap-ncat nmap bind-utils lsof tcpdump iotop \
                   traceroute tmux vim ctags git libyaml-devel readline-devel \
                   zlib-devel libffi-devel openssl-devel sqlite-devel ack jq \
                   sysstat unzip bash-completion yum-cron ntp
    echo Done.
}

setup_host() {
    echo Allowing sudoers to without password...
    sed -i 's/^%wheel.*/%wheel  ALL=(ALL)  NOPASSWD: ALL/' /etc/sudoers
    echo Done.

    echo Setting up automatic updates with yum-cron
    sed -i 's/^.*apply_updates.*=.*no$//' /etc/yum/yum-cron.conf
    echo "apply_updates = yes" > /etc/yum/yum-cron.conf
    echo Done.

    echo Setting up ntp...
    # TODO this should be a parameter
    timedatectl set-timezone America/Chicago
    systemctl start ntpd
    systemctl enable ntpd
    echo Done.

    echo Setting up firewalld...
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --list-all
    firewall-cmd --reload
    systemctl enable firewalld
    echo Done.

    echo Locking down sshd...
    echo "" >> /etc/ssh/sshd_config
    echo "# customizations..." >> /etc/ssh/sshd_config
    sed -i 's/^.*PermitRootLogin\(.*\)/#PermitRootLogin\1/' /etc/ssh/sshd_config
    echo PermitRootLogin no >> /etc/ssh/sshd_config
    sed -i 's/^.*PasswordAuthentication\(.*\)/#PasswordAuthentication\1/' /etc/ssh/sshd_config
    echo PasswordAuthentication no >> /etc/ssh/sshd_config
    systemctl reload sshd
    echo Done.
}

setup_user() {
    echo "Setting up user ${user}..."
    if ! [[ $(getent passwd "${user}") ]]; then
        useradd "${user}"
    	echo "${password}" | passwd "${user}" --stdin
    	chage -d 0 "${user}"
    fi
    usermod -aG wheel "${user}"
    mkdir -p "${homedir}/src"
    echo Done.
}

setup_ssh() {
    echo Setting up SSH...
    mkdir -p "${homedir}/.ssh"
    chmod 700 "${homedir}/.ssh"
    ssh-keygen -N "" -t rsa -b 4096 -f id_rsa -C "${email}"
    mv id_rsa* "${homedir}/.ssh/"
    chmod 644 "${homedir}/.ssh/id_rsa.pub"
    chmod 600 "${homedir}/.ssh/id_rsa"
    chown -R "${user}":"${user}" "${homedir}/.ssh"
    echo Done.
}

setup_dotfiles() {
    echo "Setting up ${user}'s dotfiles..."
    cp dots/bashrc "${homedir}/.bashrc"
    cp dots/bash_profile "${homedir}/.bash_profile"
    cp dots/profile "${homedir}/.profile"
    cp dots/tmux.conf "${homedir}/.tmux.conf"
    cp dots/vimrc "${homedir}/.vimrc"
    cp dots/gitconfig "${homedir}/.gitconfig"
    sed -i "s/<USER>/${user}/" "${homedir}/.gitconfig"
    sed -i "s/<EMAIL>/${email}/" "${homedir}/.gitconfig"
    touch "${homedir}/.local_bashrc"
    touch "${homedir}/.local_profile"
    echo Done.
}

setup_vim() {
    echo Setting up vim...
    rm -rf "${homedir}/.vim"
    cp -r vim "${homedir}/.vim"

    # https://github.com/junegunn/vim-plug
    curl -fLo "${homedir}/.vim/autoload/plug.vim" --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    chown -R "${user}":"${user}" "${homedir}"
    echo Done.
}

setup_java_dev() {
    echo Setting up for Java development
    yum install -y java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.8.0-openjdk \
                   java-1.8.0-openjdk-devel maven
    cd /usr/local/src
    wget http://downloads.sourceforge.net/project/checkstyle/checkstyle/7.1.1/checkstyle-7.1.1-all.jar
    jar xf checkstyle-7.1.1-all.jar google_checks.xml sun_checks.xml
    mkdir -p /usr/local/lib/checkstyle
    mv checkstyle-7.1.1-all.jar /usr/local/lib/checkstyle/checkstyle-7.1.1-all.jar
    mkdir -p /usr/local/etc/checkstyle
    mv *_checks.xml /usr/local/etc/checkstyle
    cd "${workdir}"
    echo Done.
}

setup_python_dev() {
    echo Setting up for Python development
    yum install -y python python-setuptools python-pip
    pip install --upgrade pip
    pip install pep8 virtualenv httpie
    echo Done.
}

setup_ruby_dev() {
    echo Setting up for Ruby development
    yum install -y ruby
    su -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" -l "${user}"
    su -c "curl -sSL https://get.rvm.io | bash -s stable" -l "${user}"
    su -c "~/.rvm/bin/rvm install ruby" -l "${user}"
    su -c "~/.rvm/bin/rvm install jruby" -l "${user}"
    su -c "~/.rvm/bin/rvm alias create default ruby" -l "${user}"
    echo Done.
}

setup_javascript_dev() {
    echo Setting up for Javascript development
    curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
    yum -y install nodejs
    npm i -g jshint
    echo Done.
}

setup_go_dev() {
    echo Setting up for Go development
    cd /usr/local/src
    wget https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.7.1.linux-amd64.tar.gz
    ln -s /usr/local/go1.7.1 /usr/local/go
    ln -s /usr/local/go/bin/go /usr/local/bin/go
    ln -s /usr/local/go/bin/godoc /usr/local/bin/godoc
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    mkdir -p /usr/local/lib/go
    echo "export GOPATH=/usr/local/lib/go" > /etc/profile.d/go.sh
    rm /usr/local/src/go1.7.1.linux-amd64.tar.gz
    cd "${workdir}"
    echo Done.
}

setup_web_dev() {
    echo Setting up for web development
    cd /usr/local/src
    wget http://binaries.html-tidy.org/binaries/tidy-5.2.0/tidy-5.2.0-64bit.rpm
    yum install -y tidy-5.2.0-64bit.rpm
    gem install sass
    rm tidy-5.2.0-64bit.rpm
    cd "${workdir}"
    echo Done.
}

setup_cloud_tools() {
    echo Installing Cloud Tools...
    pip install awscli --ignore-installed six

    cd /usr/local/src
    wget https://github.com/digitalocean/doctl/releases/download/v1.4.0/doctl-1.4.0-linux-amd64.tar.gz
    tar -xzf doctl-1.4.0-linux-amd64.tar.gz
    mv doctl /usr/local/bin/doctl
    rm doctl-1.4.0-linux-amd64.tar.gz
    cd "${workdir}"
    echo Done.
}

setup_docker() {
    echo Installing Docker...
    tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
    yum -y install docker-engine
    systemctl start docker
    systemctl enable docker
    echo Done.
}

install_dev_utilities() {
    echo Installing Dev Utilities...
    cp -R bin "${homedir}/bin"
    chown -R "${user}":"${user}" "${homedir}/bin"
    chmod +x "${homedir}"/bin/*

    wget https://github.com/alecthomas/devtodo2/archive/master.zip
    unzip master.zip
    cd devtodo2-master
    GOPATH=/usr/local/lib/go go get gopkg.in/alecthomas/kingpin.v2
    GOPATH=/usr/local/lib/go make install
    cd "${workdir}"
    echo Done.
}

install_keys_from_github() {
    echo "Installing ${user}'s keys from GitHub..."
    authorized_keys="${homedir}/.ssh/authorized_keys"
    url="https://api.github.com/users/${user}/keys"
    curl "${url}" | jq '.[] | .key' | sed 's/"//g' >> "${authorized_keys}"
    chown "${user}":"${user}" "${authorized_keys}"
    chmod 600 "${authorized_keys}"
    echo "Done."
}

send_details_email() {
    echo Sending details email...
    sendmail "${email}" <<-EOM
From: root@${hostname}
To: ${email}
Subject: New Computer Setup!

Here are the details...
""
hostname: ${hostname}
ip: ${ip}
user: ${user}
password: ${password}
EOM
    echo Done.
}

install_packages
setup_host
setup_user
setup_ssh
setup_dotfiles
setup_vim
setup_java_dev
setup_python_dev
setup_ruby_dev
setup_javascript_dev
setup_go_dev
setup_web_dev
setup_docker
install_dev_utilities
install_keys_from_github
send_details_email
