#!/bin/bash

set -e
set +H	# disable !foo style history expansion - no need to quote '!'

install_perlbrew_and_perl()
{
	curl -L https://install.perlbrew.pl | bash
	source $PERLBREW_ROOT/etc/bashrc
	echo 'test -f $PERLBREW_ROOT/etc/bashrc && source $PERLBREW_ROOT/etc/bashrc' >>~/.bashrc

	perlbrew list

	if ! perlbrew switch $TRAVIS_PERL_VERSION; then
		perl_version=$(perlbrew available | sed -nE 's/^\s*((perl-)?'$TRAVIS_PERL_VERSION'\.\S+).*$/\1/p' | head -1)

		perlbrew install $perl_version

		perlbrew alias create $perl_version $TRAVIS_PERL_VERSION

		perlbrew switch $TRAVIS_PERL_VERSION
	fi
}

rvm system
brew update
brew install perl
perl -V

perl5_root=~/perl5
if [ -d $perl5_root -a ! -O $perl5_root ]; then
	# the pre-installed (by Travis infra) ~/perl5 and its subdirs are owned
	# by root due to a Travis bug

	cp -a ~/perl5 ~/perl5-local

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
