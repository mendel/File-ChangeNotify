#!/bin/bash

set -e
set +H	# disable !foo style history expansion - no need to quote '!'

rvm system
brew update
brew install perl
perl -V

if [ ! -O ~/perl5 ]; then
	# Fix permissions of ~/perl5/ - w/o requiring sudo
	mv ~/perl5 ~/perl5-original
	cp -a ~/perl5-original ~/perl5
fi

curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'test -f ~/perl5/perlbrew/etc/bashrc && source ~/perl5/perlbrew/etc/bashrc' >>~/.bashrc
