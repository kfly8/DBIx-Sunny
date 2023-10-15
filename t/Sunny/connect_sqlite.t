=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny connect to SQLite.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31 };
use Test::Exception;

use DBD::SQLite::Constants qw(SQLITE_OPEN_READONLY DBD_SQLITE_STRING_MODE_UNICODE_NAIVE);
use DBIx::Sunny;

subtest 'DB connection info' => sub {
    my $dbh = DBIx::Sunny->connect('dbi:SQLite::memory:', 'user', 'pass', {
        # user setting options
        sqlite_open_flags => SQLITE_OPEN_READONLY,
    });

    my ($dsn, $user, $pass, $attr) = @{ $dbh->connect_info };
    is $dsn, 'dbi:SQLite::memory:', 'dsn is dbi:SQLite::memory:';

    is $user, 'user', 'user is passed';
    is $pass, 'pass', 'pass is passed';

    is_deeply $attr, {
        # DBIx::Sunny default options
        RaiseError => 1,
        PrintError => 0,
        ShowErrorStatement => 1,
        AutoInactiveDestroy => 1,
        sqlite_use_immediate_transaction => 1,
        sqlite_unicode => 1,

        # user setting options
        sqlite_open_flags => SQLITE_OPEN_READONLY
    }, 'attr is correct';


    is $dbh->{Username}, 'user', 'Username is correct';
    ok $dbh->{RaiseError}, 'RaiseError is true';
    ok !$dbh->{PrintError}, 'PrintError is false';
    ok $dbh->{ShowErrorStatement}, 'ShowErrorStatement is true';
    ok $dbh->{AutoInactiveDestroy}, 'AutoInactiveDestroy is true';

    is $dbh->{sqlite_use_immediate_transaction}, 1, 'sqlite_use_immediate_transaction is true';

    # sqlite_unicode is deprecated since DBD::SQLite 1.67_04
    if (DBD::SQLite->VERSION >= 1.67_04) {
        is $dbh->{sqlite_string_mode}, DBD_SQLITE_STRING_MODE_UNICODE_NAIVE;
    }
    else {
        is $dbh->{sqlite_unicode}, 1;
    }

    # user setting options
    throws_ok {
        $dbh->query(q{CREATE TABLE foo (id INTEGER PRIMARY KEY, name TEXT)});
    } qr{readonly database};
};

done_testing;
