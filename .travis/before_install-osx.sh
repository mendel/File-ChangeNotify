#!/bin/bash

set -x
set -e
set +H	# disable !foo style history expansion - no need to quote '!'

rvm system
brew update
brew install perl
perl -V

if [ -d ~/perl5 -a ! -O ~/perl5 ]; then
	sudo chown -R $USER ~/perl5
fi

curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'test -f ~/perl5/perlbrew/etc/bashrc && source ~/perl5/perlbrew/etc/bashrc' >>~/.bashrc

perlbrew switch $TRAVIS_PERL_VERSION
