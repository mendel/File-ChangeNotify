#!/bin/bash

set -x
set -e
set +H	# disable !foo style history expansion - no need to quote '!'

rvm system
brew update
brew install perl
perl -V

PERLBREW_ROOT=~/perl5
if [ -d ~/perl5 -a ! -O ~/perl5 ]; then
	# apparently the pre-installed (by Travis infra) ~/perl5 and its
	# subdirs are owned by root ATM
	PERLBREW_ROOT=~/perl5-local
fi
export PERLBREW_ROOT

curl -L https://install.perlbrew.pl | bash
source ~/perl5/perlbrew/etc/bashrc
echo 'test -f ~/perl5/perlbrew/etc/bashrc && source ~/perl5/perlbrew/etc/bashrc' >>~/.bashrc

perlbrew list

perlbrew switch $TRAVIS_PERL_VERSION
