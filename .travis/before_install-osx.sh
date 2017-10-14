#!/bin/bash

set -e
set +H	# disable !foo style history expansion - no need to quote '!'

rvm system
brew update
brew install perl
perl -V

if [ ! -O /Users/travis/perl5 ]; then
	sudo chown -R $USER /Users/travis/perl5
fi

curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'test -f ~/perl5/perlbrew/etc/bashrc && source ~/perl5/perlbrew/etc/bashrc' >>~/.bashrc
