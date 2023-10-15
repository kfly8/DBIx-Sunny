=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny select methods work as expected.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31, 'DBIx::Tracer' => 0.03 };
use Test::Exception;

use DBIx::Sunny;

subtest 'select_one' => sub {
    my $dbh = connect_db();

    is $dbh->select_one('SELECT 123'), 123;
    is $dbh->select_one('SELECT 1 + 1'), 2;
    is $dbh->select_one('SELECT 1 + 1 AS foo'), 2;
    is $dbh->select_one('SELECT 123, 456'), 123, 'select_one returns the first column';
    is $dbh->select_one('SELECT 456, 123'), 456, 'select_one returns the first column';
    is $dbh->select_one('SELECT 123 WHERE 1 = 0'), undef;

    subtest 'works with placeholders' => sub {
        is $dbh->select_one('SELECT 123 WHERE "hello" = ?', 'hello'), 123;
        is $dbh->select_one('SELECT 123 WHERE "hello" IN (?)', ['hello', 'world']), 123;
        is $dbh->select_one('SELECT 123 WHERE "hello" = :hello', { hello => 'hello' }), 123;
    };

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr!SELECT /\* t/Sunny/select.t line \d+ \*/ 123!;
        });

        is $dbh->select_one('SELECT 123'), 123;
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->select_one('SELLLECT 123') } qr!syntax error!;
    };
};

subtest 'select_row' => sub {
    my $dbh = connect_db();

    is_deeply $dbh->select_row('SELECT 123'), { '123' => 123 };
    is_deeply $dbh->select_row('SELECT 1 + 1'), { '1 + 1' => 2 };
    is_deeply $dbh->select_row('SELECT 1 + 1 AS foo'), { foo => 2 };
    is_deeply $dbh->select_row('SELECT 123, 456'), { '123' => 123, '456' => 456 };
    is_deeply $dbh->select_row('SELECT 123 AS foo, 456 AS bar'), { 'foo' => 123, 'bar' => 456 };
    is $dbh->select_row('SELECT 123 WHERE 1 = 0'), undef;

    subtest 'works with placeholders' => sub {
        is_deeply $dbh->select_row('SELECT 123 AS foo WHERE "hello" = ?', 'hello'), { 'foo' => 123 };
        is_deeply $dbh->select_row('SELECT 123 AS foo WHERE "hello" IN (?)', ['hello', 'world']), { 'foo' => 123 };
        is_deeply $dbh->select_row('SELECT 123 AS foo WHERE "hello" = :hello', { hello => 'hello' }), { 'foo' => 123 };
    };

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr!SELECT /\* t/Sunny/select.t line \d+ \*/ 123 AS foo!;
        });

        is_deeply $dbh->select_row('SELECT 123 AS foo'), { foo => 123 };
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->select_row('SELLLECT 123') } qr!syntax error!;
    };
};

subtest 'select_all' => sub {
    my $dbh = connect_db();

    is_deeply $dbh->select_all('SELECT 123 AS foo UNION SELECT 456 AS foo'), [{ foo => 123 }, { foo => 456 }];
    is_deeply $dbh->select_all('SELECT 123 AS foo WHERE 1 = 0'), [];

    subtest 'works with placeholders' => sub {
        is_deeply $dbh->select_all('SELECT 123 AS foo WHERE "hello" = ?', 'hello'), [{ foo => 123 }];
        is_deeply $dbh->select_all('SELECT 123 AS foo WHERE "hello" IN (?)', ['hello', 'world']), [{ foo => 123 }];
        is_deeply $dbh->select_all('SELECT 123 AS foo WHERE "hello" = :hello', { hello => 'hello' }), [{ foo => 123 }];
    };

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr!SELECT /\* t/Sunny/select.t line \d+ \*/ 123 AS foo!;
        });

        is_deeply $dbh->select_all('SELECT 123 AS foo'), [{ foo => 123 }];
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->select_all('SELLLECT 123') } qr!syntax error!;
    };
};

{
    package Foo;
    sub new {
        my ($class, %args) = @_;
        bless \%args, $class;
    }
}

subtest 'select_row_as' => sub {
    my $dbh = connect_db();

    my $row =  $dbh->select_row_as('Foo', 'SELECT 123 AS foo, 456 AS bar');
    isa_ok $row, 'Foo';
    is $row->{foo}, 123;
    is $row->{bar}, 456;

    is $dbh->select_row_as('Foo', 'SELECT 123 AS foo WHERE 1 = 0'), undef;

    subtest 'works with placeholders' => sub {
        my $row =  $dbh->select_row_as('Foo', 'SELECT 123 AS foo WHERE "hello" = ?', 'hello');
        isa_ok $row, 'Foo';
        is $row->{foo}, 123;
    };

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr!SELECT /\* t/Sunny/select.t line \d+ \*/ 123 AS foo!;
        });

        my $row =  $dbh->select_row_as('Foo', 'SELECT 123 AS foo');
        isa_ok $row, 'Foo';
        is $row->{foo}, 123;
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->select_row_as('User', 'SELLLECT 123') } qr!syntax error!;
    };
};

subtest 'select_all_as' => sub {
    my $dbh = connect_db();

    my $rows = $dbh->select_all_as('Foo', 'SELECT 123 AS foo UNION SELECT 456 AS foo');
    is @$rows, 2;
    isa_ok $rows->[0], 'Foo';
    is $rows->[0]->{foo}, 123;
    is $rows->[1]->{foo}, 456;

    is_deeply $dbh->select_all_as('Foo', 'SELECT 123 AS foo WHERE 1 = 0'), [];

    subtest 'works with placeholders' => sub {
        my $rows = $dbh->select_all_as('Foo', 'SELECT 123 AS foo WHERE "hello" = ?', 'hello');
        is @$rows, 1;
        isa_ok $rows->[0], 'Foo';
        is $rows->[0]->{foo}, 123;
    };

    subtest 'caller infomation is commented in SQL' => sub {
        my $guard = trace_sql(sub {
            my $sql = shift;
            like $sql, qr!SELECT /\* t/Sunny/select.t line \d+ \*/ 123 AS foo!;
        });

        my $rows = $dbh->select_all_as('Foo', 'SELECT 123 AS foo');
        is @$rows, 1;
        isa_ok $rows->[0], 'Foo';
        is $rows->[0]->{foo}, 123;
    };

    subtest 'invalid sql' => sub {
        throws_ok { $dbh->select_all_as('User', 'SELLLECT 123') } qr!syntax error!;
    };
};


sub connect_db {
    DBIx::Sunny->connect('dbi:SQLite::memory:', '', '');
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
