#!/bin/bash

set -v
set -e
set +H	# disable !foo style history expansion - no need to quote '!'

rvm system
brew update
brew install perl
perl -V

PERLBREW_ROOT=~/perl5
if [ -d $PERLBREW_ROOT -a ! -O $PERLBREW_ROOT ]; then
	# apparently the pre-installed (by Travis infra) ~/perl5 and its
	# subdirs are owned by root ATM
	PERLBREW_ROOT=~/perl5-local
fi
export PERLBREW_ROOT

curl -L https://install.perlbrew.pl | bash
source $PERLBREW_ROOT/perlbrew/etc/bashrc
echo 'test -f $PERLBREW_ROOT/perlbrew/etc/bashrc && source $PERLBREW_ROOT/perlbrew/etc/bashrc' >>~/.bashrc

perlbrew list

perlbrew switch $TRAVIS_PERL_VERSION

# some versions of the pre-installed (by Travis infra) perlbrew perls are
# broken (Config.pm missing)
if ! perl -V; then
	rm -rf "$PERLBREW_ROOT"
	perlbrew init
	perlbrew install $TRAVIS_PERL_VERSION
	perlbrew switch $TRAVIS_PERL_VERSION
fi
