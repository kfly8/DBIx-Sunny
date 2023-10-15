=pod

=encoding utf-8

=head1 PURPOSE

Test that DBIx::Sunny::Util::bind_and_execute works correctly.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31 };
use B;
use DBI;

use DBIx::Sunny::Util qw( bind_and_execute );

sub sth {
    my ($sql) = @_;
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '');
    my $sth = $dbh->prepare($sql);
    return $sth;
}

subtest '@bind items are literal' => sub {
    my $sth = sth('SELECT ?, ?');

    my $result = bind_and_execute($sth, 100, 200);
    ok $result == 0E0, 'execution result is success';

    is_deeply $sth->fetchrow_arrayref, [100, 200], 'fetched values';
    is_deeply $sth->{ParamValues}, { 1 => 100, 2 => 200 }, 'binded values';
};

subtest '@bind items are object' => sub {

    subtest 'object has `value_ref` and `type` methods' => sub {
        {
            package MyType;
            sub new {
                my ($class, %args) = @_;
                bless \%args, $class;
            }

            sub value_ref { $_[0]->{value_ref} }
            sub type {  $_[0]->{type} }
        }

        my $sth = sth('SELECT ?, ?');

        my $v1 = MyType->new(value_ref => \100, type => DBI::SQL_INTEGER);
        my $v2 = MyType->new(value_ref => \200, type => DBI::SQL_VARCHAR);

        my $result = bind_and_execute($sth, $v1, $v2);
        ok $result == 0E0, 'execution result is success';

        my $row = $sth->fetchrow_arrayref;
        is_deeply $row, [100, '200'], 'fetched values';
        is_deeply $sth->{ParamValues}, { 1 => 100, 2 => '200' }, 'binded values';

        my $r1 = B::svref_2object(\$row->[0]);
        ok $r1->FLAGS & B::SVf_IOK && !($r1->FLAGS & B::SVp_POK), 'first value is integer';

        my $r2 = B::svref_2object(\$row->[1]);
        ok !($r2->FLAGS & B::SVf_IOK) && $r2->FLAGS & B::SVp_POK, 'second value is string';
    };

    subtest 'object has not `value_ref` and `type` methods' => sub {
        {
            package MyDummy;
            sub new {
                my ($class, $value) = @_;
                bless \$value, $class;
            }
        }

        my $sth = sth('SELECT ?, ?');

        my $v1 = MyDummy->new(100);
        my $v2 = MyDummy->new(200);

        my $result = bind_and_execute($sth, $v1, $v2);
        ok $result == 0E0, 'execution result is success';

        my $row = $sth->fetchrow_arrayref;
        is_deeply $row, ["$v1", "$v2"], 'fetched values';
        is_deeply $sth->{ParamValues}, { 1 => $v1, 2 => $v2 }, 'binded values';
    };
};

subtest 'Not enough @bind' => sub {
    my $sth = sth('SELECT ?, ?');

    my $result = bind_and_execute($sth, 100);
    ok $result == 0E0, 'execution result is success';

    is_deeply $sth->fetchrow_arrayref, [100, undef], 'undef is filled in fetch values';
    is_deeply $sth->{ParamValues}, { 1 => 100, 2 => undef }, 'undef is filled in binded values';
};

subtest 'Extra value passed to @bind' => sub {
    my $sth = sth('SELECT ?, ?');

    my $result = bind_and_execute($sth, 100, 200, 300);
    ok $result == 0E0, 'execution result is success';

    is_deeply $sth->fetchrow_arrayref, [100, 200], 'Extra value is ignored in fetch values';
    is_deeply $sth->{ParamValues}, { 1 => 100, 2 => 200 }, 'Extra value is ignored in binded values';
};

done_testing;
