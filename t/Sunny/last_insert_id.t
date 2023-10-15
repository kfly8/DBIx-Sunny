=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny last_insert_id method work as expected.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31 };
use Test::Exception;

use DBIx::Sunny;

subtest 'last_insert_id' => sub {
    my $dbh = setup_db();
    ok $dbh->query('INSERT INTO foo (name) VALUES (?)', 'foo');
    is $dbh->last_insert_id, 1, 'first last_insert_id';

    ok $dbh->query('INSERT INTO foo (name) VALUES (?)', 'bar');
    is $dbh->last_insert_id, 2;

    ok $dbh->query('INSERT INTO foo (id, name) VALUES (?, ?)', 123, 'baz');
    is $dbh->last_insert_id, 123, 'specfied last_insert_id';

    ok $dbh->query('DELETE FROM foo WHERE id = ?', 123);
    is $dbh->last_insert_id, 123, 'specfied last_insert_id';

    ok $dbh->query('INSERT INTO foo (name) VALUES (?)', 'bao');
    is $dbh->last_insert_id, 3;
};

sub setup_db {
    my $dbh = DBIx::Sunny->connect('dbi:SQLite::memory:', '', '');
    $dbh->do(q{
        CREATE TABLE foo (
            id INTEGER NOT NULL PRIMARY KEY,
            name VARCHAR(10)
        )
    });
    return $dbh;
}

done_testing;
