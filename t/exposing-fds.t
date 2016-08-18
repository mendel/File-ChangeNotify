use strict;
use warnings;

#FIXME using $_DESC in the test descriptions

use lib 't/lib';

use File::ChangeNotify;
use File::Temp qw( tempdir );
use File::Path qw( mkpath rmtree );

use Test::More;

use File::ChangeNotify::TestHelper qw( create_file  modify_file delete_file );

my %fds;

sub test_dir {
    my ($dir, $watcher, $where) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $path = "$dir/whatever";

    create_file($path);

    select_and_check_events(
        $watcher,
        [
            {
                path => $path,
                type => 'create',
            },
        ],
        "added one file in $where ($path)",
    );

    modify_file($path);

    select_and_check_events(
        $watcher,
        [
            {
                path => $path,
                type => 'modify',
            },
        ],
        "modified one file in $where ($path)",
    );

    delete_file($path);

    select_and_check_events(
        $watcher,
        [
            {
                path => $path,
                type => 'delete',
            },
        ],
        "deleted one file in $where ($path)",
    );
}

sub select_and_check_events {
    my ($watcher, $expected, $desc) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    isnt(num_fds_ready_for_io(), 0,
        "select() found some fds that are ready for I/O");

    my @ret = File::ChangeNotify::TestHelper::_check_events(
        scalar @$expected, [ $watcher->new_events() ], $expected, $desc);

    test_no_invalid_fds_in_the_set();

    return @ret;
}

sub num_fds_ready_for_io {
    my $fds = '';

    foreach my $fd ( keys %fds ) {
        vec($fds, $fd,  1) = 1;
    }

    my ($n_found) = select $fds, undef, $fds, 0;

    return $n_found;
}

sub test_no_invalid_fds_in_the_set {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $found_invalid_fd;
    foreach my $fd ( keys %fds ) {
        open my $dummy, '<&', $fd
            or $found_invalid_fd = 1, last;
    }

    ok(!$found_invalid_fd, "no invalid fds in the current set");
}

my @classes = grep { $_->supports_exposing_fds }
    File::ChangeNotify->usable_classes();

for my $class (@classes) {
    ( my $short = $class ) =~ s/^File::ChangeNotify::Watcher:://;
    local $File::ChangeNotify::TestHelper::_DESC = "[with $short]";

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        watch_fds       => sub {
            @fds{@_} = ();
        },
        unwatch_fds     => sub {
            delete @fds{@_};
        },
    );

    isnt(scalar keys %fds, 0,
        "there are some fds registered right after construction");

    is(num_fds_ready_for_io(), 0,
        "select() found no fds that are ready for I/O right after construction");

    test_no_invalid_fds_in_the_set();


    test_dir($dir, $watcher, 'top-level dir');


    my $subdir = "$dir/subdir";

    mkpath( $subdir, 0, 0755 );

    select_and_check_events(
        $watcher,
        [
            {
                path => $subdir,
                type => 'create',
            },
        ],
        "created a subdir ($subdir)",
    );

    test_dir($subdir, $watcher, 'subdir');

    rmtree($subdir);

    select_and_check_events(
        $watcher,
        [
            {
                path => $subdir,
                type => 'delete',
            },
        ],
        "deleted the subdir ($subdir)",
    );
}

done_testing();
