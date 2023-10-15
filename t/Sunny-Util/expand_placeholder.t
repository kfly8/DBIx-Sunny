=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny::Util::expand_placeholder works correctly.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use DBIx::Sunny::Util qw( expand_placeholder );

subtest 'query is undef' => sub {
    my $query = undef;
    is expand_placeholder($query), undef, 'return undef';
};

subtest 'simple case' => sub {
    my ($query, @bind) = expand_placeholder(
        'SELECT * FROM foo WHERE id = ? AND name = ?',
        1, 'foo'
    );

    is $query, 'SELECT * FROM foo WHERE id = ? AND name = ?';
    is_deeply \@bind, [ 1, 'foo' ];
};

subtest 'When @bind includes arrayref, then expand placeholders' => sub {

    subtest 'expand single arrayref' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id IN (?)',
            [1,2,3],
        );

        is $query, 'SELECT * FROM foo WHERE id IN (?,?,?)';
        is_deeply \@bind, [ 1, 2, 3 ];
    };

    subtest 'expand two arrayref' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id IN (?) AND name IN (?)',
            [1,2,3],
            ['bar','baz'],
        );

        is $query, 'SELECT * FROM foo WHERE id IN (?,?,?) AND name IN (?,?)';
        is_deeply \@bind, [ 1, 2, 3, 'bar', 'baz' ];
    };

    subtest 'expand arrayref and some value' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id IN (?) AND name = ?',
            [1,2,3],
            'bar',
        );

        is $query, 'SELECT * FROM foo WHERE id IN (?,?,?) AND name = ?';
        is_deeply \@bind, [ 1, 2, 3, 'bar' ];
    };

    subtest 'expand arrayref and some values' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE name = ? AND id IN (?) AND flag = ?',
            'bar',
            [1,2,3],
            \1,
        );

        is $query, 'SELECT * FROM foo WHERE name = ? AND id IN (?,?,?) AND flag = ?';
        is_deeply \@bind, [ 'bar', 1, 2, 3,  \1 ];
    };

    subtest '@bind has extra values' => sub {
        throws_ok {
            expand_placeholder(
                'SELECT * FROM foo WHERE id IN (?)',
                [1,2,3],
                123, # extra bind
            );
        } qr!Num of binds doesn't match!;
    };
};

subtest 'When @bind is hashref, then replace named placeholders' => sub {

    subtest 'replace :id, :name' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id = :id AND name = :name',
            { id => 1, name => 'foo' }
        );

        is $query, 'SELECT * FROM foo WHERE id = ? AND name = ?';
        is_deeply \@bind, [ 1, 'foo' ];
    };

    subtest 'replace :id, :name, :id' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id = :id AND name = :name AND id = :id',
            { id => 1, name => 'foo' }
        );

        is $query, 'SELECT * FROM foo WHERE id = ? AND name = ? AND id = ?';
        is_deeply \@bind, [ 1, 'foo', 1 ];
    };

    subtest '@bind hashref has extra field' => sub {
        my ($query, @bind) = expand_placeholder(
            'SELECT * FROM foo WHERE id = :id AND name = :name',
            { id => 1, name => 'foo', extra => 'bar' }
        );

        is $query, 'SELECT * FROM foo WHERE id = ? AND name = ?';
        is_deeply \@bind, [ 1, 'foo' ], 'extra field is ignored';
    };

    subtest 'cannot find :id' => sub {
        throws_ok {
            expand_placeholder(
                'SELECT * FROM foo WHERE id = :id AND name = :name',
                { name => 'foo' }
            );
        } qr!'id' does not exist in bind hash!;
    };

    subtest '$bind[0] is hashref, but has extra @bind' => sub {
        throws_ok {
            expand_placeholder(
                'SELECT * FROM foo WHERE id = :id AND name = :name',
                { id => 1, name => 'foo' },
                123 # extra bind
            );
        } qr!Num of binds doesn't match!,
        'Named placeholder cannot accept extra bind';
    };
};

done_testing;
