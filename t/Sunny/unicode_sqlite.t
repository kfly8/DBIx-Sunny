=pod

=encoding utf-8

=head1 PURPOSE

Test that DBD::SQLite treates unicode strings correctly.

=cut

use strict;
use warnings;
use Test::More 0.98;
use Test::Requires { 'DBD::SQLite' => 1.31 };

use Encode qw(is_utf8);
use DBIx::Sunny;

use utf8; # This ensures the entire script treats the strings as utf8

subtest 'DB connection has correct unicode attributes' => sub {
    my $dbh = connect_db();
    my $attr = $dbh->connect_info->[3];

    # XXX: sqlite_unicode attribute is deprecated since DBD::SQLite 1.67_04, so sqlite_string_mode attribute is better?
    is $attr->{sqlite_unicode}, 1, 'sqlite_unicode is true';
};

subtest 'Using utf8' => sub {
    my $dbh = connect_db();

    sub test_fire {
        my ($x) = @_;
        is $x, '🔥';
        is $x, "\x{1f525}";
        ok is_utf8($x);
    }

    subtest 'Fetch emoji using direct string binding' => sub {
        my $x = $dbh->select_one(q{SELECT ?}, '🔥');
        test_fire($x);
    };

    subtest 'Fetch emoji using Unicode code point binding' => sub {
        my $x = $dbh->select_one(q{SELECT ?}, '🔥');
        test_fire($x);
    };

    subtest 'Insert and select emoji from table directly' => sub {
        ok $dbh->query(q{CREATE TABLE bar (x varchar(10))});
        ok $dbh->query(q{INSERT INTO bar (x) VALUES (?)}, "🔥");

        my $x = $dbh->select_one(q{SELECT x FROM bar});
        test_fire($x);
    };
};


subtest 'Using no utf8' => sub {
    my $dbh = connect_db();
    ok $dbh->query(q{CREATE TABLE baz (x varchar(10))});

    subtest 'Insert emoji with utf8 flag off, and select with utf8 flag on.' => sub {
        ok $dbh->query(q{DELETE FROM baz});

        {
            no utf8;
            ok $dbh->query(q{INSERT INTO baz (x) VALUES (?)}, "🔥");
        }

        my $x = $dbh->select_one(q{SELECT x FROM baz});
        isnt $x, '🔥', 'not fire';
        isnt $x, "\x{1f525}", 'not unicode code point';
        ok is_utf8($x);
    };

    subtest 'Insert emoji with utf8 flag on, and select with utf8 flag off.' => sub {
        ok $dbh->query(q{DELETE FROM baz});

        ok $dbh->query(q{INSERT INTO baz (x) VALUES (?)}, "🔥");

        {
            no utf8;

            my $x = $dbh->select_one(q{SELECT x FROM baz});
            isnt $x, '🔥', 'not fire';
            is $x, "\x{1f525}";
            ok is_utf8($x);
        }
    };
};

sub connect_db {
    return DBIx::Sunny->connect('dbi:SQLite::memory:', '', '');
}

done_testing;
