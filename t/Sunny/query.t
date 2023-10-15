=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny query method work as expected.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31, 'DBIx::Tracer' => 0.03 };
use Test::Exception;

use DBIx::Sunny;

subtest 'query' => sub {
    my $dbh = setup_db();

    ok $dbh->query('INSERT INTO foo (id, name) VALUES (?, ?)', 1, 'foo'), 'positional placeholder';
    ok $dbh->query('INSERT INTO foo (id, name) VALUES (:id, :name)', { id => 2, name => 'bar' }), 'named placeholder';

    is_deeply $dbh->select_all('SELECT * FROM foo'), [
        { id => 1, name => 'foo' },
        { id => 2, name => 'bar' },
    ];

    ok $dbh->query('UPDATE foo SET name = ? WHERE id = ?', 'baz', 1), 'update';
    ok $dbh->query('DELETE FROM foo WHERE id = ?', 2), 'delete';

    is_deeply $dbh->select_all('SELECT * FROM foo'), [
        { id => 1, name => 'baz' },
    ];

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr{INSERT /\* t/Sunny/query.t line \d+ \*/ INTO foo};
        });

        ok $dbh->query('INSERT INTO foo (id, name) VALUES (?, ?)', 3, 'boo');
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->query('INSSSERT INTO foo (id, name) VALUES (?, ?)', 1, 'foo') } qr{syntax error};
        throws_ok { $dbh->query('INSERT INTO foo (id, name, aaaaa) VALUES (?, ?, ?)', 1, 'foo', 1) } qr{table foo has no column};
        throws_ok { $dbh->query('UPDATE foo SET aaaaa = ?', 'baz') } qr{no such column};
        throws_ok { $dbh->query('DELETE FROM foo WHERE aaaaa = ?', 'baz') } qr{no such column};
    };
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

sub trace_sql {
    my $callback = shift;
    return DBIx::Tracer->new(
        sub {
            my %args = @_;
            $callback->($args{sql});
        }
    );
}

done_testing;
