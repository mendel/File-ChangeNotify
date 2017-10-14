#!/bin/bash

set -e

rvm system
brew update
brew install perl
perl -V

sudo chown -R $USER /Users/travis/perl5
curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'test -f ~/perl5/perlbrew/etc/bashrc && source ~/perl5/perlbrew/etc/bashrc' >>~/.bashrc
