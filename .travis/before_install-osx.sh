#!/bin/bash

set -e
set +H	# disable !foo style history expansion - no need to quote '!'

install_perlbrew_and_perl()
{
	curl -L https://install.perlbrew.pl | bash
	source $PERLBREW_ROOT/etc/bashrc
	echo 'test -f $PERLBREW_ROOT/etc/bashrc && source $PERLBREW_ROOT/etc/bashrc' >>~/.bashrc

	perlbrew list

	perlbrew switch $TRAVIS_PERL_VERSION
	if [ $? -ne 0 ]; then
		perlbrew install $TRAVIS_PERL_VERSION
		perlbrew switch $TRAVIS_PERL_VERSION
	fi
}

rvm system
brew update
brew install perl
perl -V

perl5_root=~/perl5
if [ -d $perl5_root -a ! -O $perl5_root ]; then
	# apparently the pre-installed (by Travis infra) ~/perl5 and its
	# subdirs are owned by root ATM
	perl5_root=~/perl5-local
fi
export PERLBREW_ROOT=$perl5_root/perlbrew

install_perlbrew_and_perl

# some versions of the pre-installed (by Travis infra) perlbrew perls are
# broken (Config.pm missing)
if ! perl -V; then
	rm -rf "$perl5_root"

	install_perlbrew_and_perl
fi
