#!/bin/bash

set -e
set +H	# disable !foo style history expansion - no need to quote '!'

_run()
{
	set +e

	echo "$ $*" >&2
	"$@"
	local exit_status=$?

	set -e

	return $exit_status
}

install_perlbrew_and_perl()
{
	_run curl -L https://install.perlbrew.pl | bash
	_run source $PERLBREW_ROOT/etc/bashrc
	echo 'test -f $PERLBREW_ROOT/etc/bashrc && source $PERLBREW_ROOT/etc/bashrc' >>~/.bashrc

	_run perlbrew list

	if ! _run perlbrew switch $TRAVIS_PERL_VERSION; then
		_run perlbrew available

		perl_version=$(perlbrew available | sed -n 's/^[[:space:]]*\(\(perl-\)\{0,1\}'"${TRAVIS_PERL_VERSION//./\\.}"'\.[0-9]\{1,\}\).*$/\1/p' | head -1)

		_run travis_wait 30 perlbrew install $perl_version

		_run perlbrew alias create $perl_version $TRAVIS_PERL_VERSION

		_run perlbrew switch $TRAVIS_PERL_VERSION
	fi
}

_run rvm system
_run brew update
_run brew install perl
_run perl -V

perl5_root=~/perl5
if [ -d $perl5_root -a ! -O $perl5_root ]; then
	# the pre-installed (by Travis infra) ~/perl5 and its subdirs are owned
	# by root due to a Travis bug

	_run cp -a ~/perl5 ~/perl5-local

	perl5_root=~/perl5-local
fi
export PERLBREW_ROOT=$perl5_root/perlbrew

install_perlbrew_and_perl

# some versions of the pre-installed (by Travis infra) perlbrew perls are
# broken (Config.pm missing)
if ! perl -V; then
	_run rm -rf "$perl5_root"

	install_perlbrew_and_perl
fi
