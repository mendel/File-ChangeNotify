use strict;
use warnings;

use Test::More;

use File::ChangeNotify;

sub loads_ok {
    my ( $module, $osname_re ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $expected_to_succeed = $^O =~ $osname_re;

    my $msg = ( $expected_to_succeed ? 'can' : 'cannot' ) . " load $module";

    ## no critic (Subroutines::ProtectPrivateSubs)
    ok(
        !( $expected_to_succeed xor File::ChangeNotify::_try_load($module) ),
        $msg
    );
}

loads_ok( 'File::ChangeNotify::Watcher::Default', qr/./ );

loads_ok( 'File::ChangeNotify::Watcher::Inotify', qr/^linux$/ );

loads_ok( 'File::ChangeNotify::Watcher::KQueue', qr/bsd|^darwin$/ );

done_testing();
