=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny fill_arrayref method works correctly.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use DBIx::Sunny;

subtest 'expand arrayref' => sub {
    my $dbh = connect_db();

    my ($query, @bind) = $dbh->fill_arrayref(
        'SELECT * FROM foo WHERE id IN (?) AND name IN (?)',
        [1,2,3],
        ['bar','baz'],
    );

    is $query, 'SELECT * FROM foo WHERE id IN (?,?,?) AND name IN (?,?)';
    is_deeply \@bind, [ 1, 2, 3, 'bar', 'baz' ];
};

subtest 'expand hashref' => sub {
    my $dbh = connect_db();

    my ($query, @bind) = $dbh->fill_arrayref(
        'SELECT * FROM foo WHERE id = :id AND name = :name',
        { id => 1, name => 'foo' }
    );

    is $query, 'SELECT * FROM foo WHERE id = ? AND name = ?';
    is_deeply \@bind, [ 1, 'foo' ];
};


subtest 'Internally, fill_arrayref method delegates processing to Util#expand_placeholder' => sub {
    my $dbh = connect_db();

    no warnings qw(once);
    local *DBIx::Sunny::db::expand_placeholder = sub { @_ };

    my ($query, @bind) = $dbh->fill_arrayref('some query', 'foo', 'bar');
    is $query, 'some query';
    is_deeply \@bind, [ 'foo', 'bar' ];
};

sub connect_db {
    return DBIx::Sunny->connect('dbi:SQLite::memory:','', '');
}

done_testing;
