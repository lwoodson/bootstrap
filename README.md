# Bootstrap
Bootstrapping for development on a CentOS box in the cloud.  It should
be run as root like so:

```
./bootstrap tsmith tony.smith@foo.com
```

This will:

* Carry out some basic bootstrapping such as removing the requirement
  of sudoers to have to provide a password, firewalling, ssh lockdown,
  ntp setup, etc...
* Create the user tsmith
* Make tsmith a sudoer
* Generate a key pair for tsmith with appropriate permissions in their
`$HOME/.ssh` directory
* Install java 1.7, 1.8, python 2.7, ruby 2.3, jruby 9K, node and go
* Install many important dev/ops tools such as telnet, netcat, nmap,
  lsof, tcpdump, iotop, sar, traceroute, tmux, ctags, git, docker, ack,
  jq, httpie
* Install and customize vim
* Setup other dot files
* Customize Vim as an IDE
* Install dev utilities for TDD workflow
* Fetch tsmith's keys from GitHub into authorized_keys
* Send an email to tony.smith@foo.com with a password and other details

The primary purpose of this is to give me the ability to bootstrap
cloud hosts w/development tools that I like to use for development in
lieu of a high-performance/costly laptop.

## Bootstrapping
1. Find a release you want [here](https://github.com/lwoodson/bootstrap/releases)
1. `wget` the source tarball
2. `tar -xzf` the source tarball
3. `cd` into the unpacked directory
4. `./bootstrap.sh [USER] [EMAIL]` to start bootstrapping

When done, you should be able to log in as the user specified.

## Sources
* [DigitalOcean's initial server setup with centos 7](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-centos-7)
* [DigitalOcean's additional recommended steps for new centos 7 servers](https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-centos-7-servers)
