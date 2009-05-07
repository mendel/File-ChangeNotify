package
    File::ChangeNotify::TestHelper;

use strict;
use warnings;

use File::ChangeNotify;
use File::Temp qw( tempdir );
use File::Path qw( mkpath rmtree );
use Test::More;

use base 'Exporter';

our @EXPORT = qw( run_tests );

our $_DESC;

sub run_tests
{
    my @classes = File::ChangeNotify->usable_classes();

    plan tests => 27 * @classes;

    for my $class (@classes)
    {
        ( my $short = $class ) =~ s/^File::ChangeNotify::Watcher:://;

        local $_DESC = "[with $short - blocking]";
        _shared_tests( $class, \&_blocking );

        local $_DESC = "[with $short - nonblocking]";
        _shared_tests( $class, \&_nonblocking );
        _symlink_tests($class);
    }
}

sub _blocking
{
    my $watcher = shift;

    my $receiver = ReceiveEvents->new();

    $watcher->watch($receiver);

    return $receiver->events();
}

sub _nonblocking
{
    my $watcher = shift;

    return $watcher->new_events();
}

sub _shared_tests
{
    _basic_tests(@_);
    _multi_event_tests(@_);
    _regex_tests(@_);
    _dir_add_remove_tests(@_);
}

sub _basic_tests
{
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( UNLINK => 1 );

    my $watcher = $class->new( directories     => $dir,
                               follow_symlinks => 0,
                               sleep_interval  => 0,
                             );

    my $path = "$dir/whatever";
    create_file($path);

    _check_events
        ( 1,
          [ $events_sub->($watcher) ],
          [ { path => $path,
              type => 'create',
            },
          ],
          "added one file ($path)",
        );

    modify_file($path);

    _check_events
        ( 1,
          [ $events_sub->($watcher) ],
          [ { path => $path,
              type => 'modify',
            },
          ],
          "modified one file ($path)",
        );

    delete_file($path);

    _check_events
        ( 1,
          [ $events_sub->($watcher) ],
          [ { path => $path,
              type => 'delete',
            },
          ],
          "deleted one file ($path)",
        );
}

sub _multi_event_tests
{
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( UNLINK => 1 );

    my $watcher = $class->new( directories     => $dir,
                               follow_symlinks => 0,
                               sleep_interval  => 0,
                             );

    my $path1 = "$dir/whatever";
    create_file($path1);
    modify_file($path1);
    delete_file($path1);

    my $path2 = "$dir/another";
    create_file($path2);
    modify_file($path2);

    if ( $watcher->sees_all_events() )
    {
        _check_events
            ( 5,
              [ $events_sub->($watcher) ],
              [ { path => $path1,
                  type => 'create',
                },
                { path => $path1,
                  type => 'modify',
                },
                { path => $path1,
                  type => 'delete',
                },
                { path => $path2,
                  type => 'create',
                },
                { path => $path2,
                  type => 'modify',
                },
              ],
              "added/modified/deleted $path1 and added/modified $path2",
            );
    }
    else
    {
        _check_events
            ( 1,
              [ $events_sub->($watcher) ],
              [ { path => $path2,
                  type => 'create',
                },
              ],
              "added/modified/deleted $path1 and added/modified $path2",
            );
    }
}

sub _regex_tests
{
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( UNLINK => 1 );

    my $watcher = $class->new( directories     => $dir,
                               follow_symlinks => 0,
                               regex           => qr/^foo/,
                               sleep_interval  => 0,
                             );

    my $path1 = "$dir/not-included";
    create_file($path1);
    modify_file($path1);
    delete_file($path1);

    my $path2 = "$dir/foo.txt";
    create_file($path2);

    _check_events
        ( 1,
          [ $events_sub->($watcher) ],
          [ { path => $path2,
              type => 'create',
            },
          ],
          'file not matching regex is ignored but foo.txt is noted',
        );
}

sub _dir_add_remove_tests
{
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( UNLINK => 1 );

    my $watcher = $class->new( directories     => $dir,
                               follow_symlinks => 0,
                               sleep_interval  => 0,
                             );

    my $subdir1 = "$dir/subdir1";
    my $subdir2 = "$dir/subdir2";

    mkpath( $subdir1, 0, 0755 );
    rmtree( $subdir1 );

    mkpath( $subdir2, 0, 0755 );

    my $path = "$subdir2/whatever";
    create_file($path);

    if ( $watcher->sees_all_events() )
    {
        _check_events
            ( 4,
              [ $events_sub->($watcher) ],
              [ { path => $subdir1,
                  type => 'create',
                },
                { path => $subdir1,
                  type => 'delete',
                },
                { path => $subdir2,
                  type => 'create',
                },
                { path => $path,
                  type => 'create',
                },
              ],
              "created/delete $subdir1 and created one file ($path) in a new subdir ($subdir2)",
            );
    }
    else
    {
        _check_events
            ( 2,
              [ $events_sub->($watcher) ],
              [ { path => $subdir2,
                  type => 'create',
                },
                { path => $path,
                  type => 'create',
                },
              ],
              "created/delete $subdir1 and created one file ($path) in a new subdir ($subdir2)",
            );
    }
}

sub _symlink_tests
{
    my $class      = shift;

    my $dir1 = tempdir( UNLINK => 1 );
    my $dir2 = tempdir( UNLINK => 1 );

    my $symlink = "$dir1/other";
 SKIP:
    {
        skip 'This platform does not support symlinks.', 3
            unless eval { symlink $dir2 => $symlink };

        my $watcher = $class->new( directories     => $dir1,
                                   follow_symlinks => 0,
                                   sleep_interval  => 0,
                                 );

        my $path = "$dir2/file";
        create_file($path);
        delete_file($path);

        _check_events( 0,
                       [ $watcher->new_events() ],
                       [],
                       'no events for symlinked dir when not following symlinks',
                     );

        $watcher = $class->new( directories     => $dir1,
                                follow_symlinks => 1,
                                sleep_interval  => 0,
                              );

        create_file($path);

        my $expected_path = "$symlink/file";

        _check_events( 1,
                       [ $watcher->new_events() ],
                       [ { path => $expected_path,
                           type => 'create',
                         },
                       ],
                       'one event for symlinked dir when following symlinks',
                     );
    }
}

sub _check_events
{
    my $count         = shift;
    my $got_events    = shift;
    my $expect_events = shift;
    my $desc          = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $noun = $count == 1 ? 'event' : 'events';

    is( scalar @{ $got_events }, $count,
        "got $count $noun $_DESC" )
        or do { use Data::Dumper; diag Dumper $got_events };

    return unless $count;

    _is_events( $got_events,
                $expect_events,
                $desc,
              );
}

sub _is_events
{
    my $got      = shift;
    my $expected = shift;
    my $desc     = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    is_deeply( [ map { { path => $_->path(), type => $_->event_type() } } @{ $got } ],
               $expected,
               "$desc $_DESC"
             );
}

sub create_file
{
    my $path  = shift;

    open my $fh, '>', $path
        or die "Cannot write to $path: $!";
    close $fh
        or die "Cannot write to $path: $!";
}

sub modify_file
{
    my $path = shift;

    die "No such file $path!\n" unless -f $path;

    open my $fh, '>>', $path
        or die "Cannot write to $path: $!";
    print {$fh} "1\n"
        or die "Cannot write to $path: $!";
    close $fh
        or die "Cannot write to $path: $!";
}

sub delete_file
{
    my $path = shift;

    die "No such file $path!\n" unless -f $path;

    unlink $path
        or die "Cannot unlink $path: $!";
}

package
    ReceiveEvents;

sub new { bless [] }

sub handle_events
{
    my $self = shift;

    push @{ $self }, @_;
}

sub events { @{ $_[0] } }

1;
