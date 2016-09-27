# Bootstrap
Bootstrapping for local development on a CentOS box.  It should be
run as root like so:

```
./bootstrap tsmith tony.smith@foo.com
```

This will:

* Install many important dev and ops tools
  * telnet
  * netcat
  * nmap
  * lsof
  * tcpdump
  * iotop
  * traceroute
  * tmux
  * vim
  * ctags
  * git
  * docker
  * ack
* Remove the requirements for sudoers to provide a password
* Create the user tsmith
* Make tsmith a sudoer
* Generate a key pair for tsmith with appropriate permissions in their
`$HOME/.ssh` directory
* Setup tmux as a development tool
* Setup dot files
* Customize Vim as an IDE
* Install Java 1.7 and 1.8
* Install Python 2.7 with virtualenv support
* Install the latest Ruby and JRuby with RVM
* Install dev utilities for TDD workflow
* Send an email to tony.smith@foo.com with a password and other details

The primary purpose of this is to give me the ability to bootstrap
cloud hosts w/development tools that I like to use for development in
lieu of a high-performance/costly laptop.
