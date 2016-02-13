use strict;
use warnings;

package KENTNL::GuardTest;

# ABSTRACT: Protected and Verbose subtesting

use Test::Builder 0.95_01;    # subtest + done_testing implied
use Test::More ();

BEGIN {
    *explain = \&Test::More::explain;
}

# This does a whole bunch of handy shit:
#
# guarded name => sub { return $guardval => $checking_sub };
# Then "checking_sub" is executed in a subtest.
# And if it fails or bails, guardval is reported in the failure along with the error
# and all the tests that happened in the subtest which are defacto hidden in CPAN smokers.
#
sub guarded {
    my ( $name, $generator ) = @_;
    my $errored = 1;
    my $guardval;
    my $error;
    my (@details);
    my $outer_tb = Test::Builder->new();
    $outer_tb->subtest(
        $name => sub {
            local $@;
            my $tb = Test::Builder->new();
            my $ret;
            my ($code);
            eval {
                ( $guardval, $code ) = $generator->();
                local $_ = $guardval;
                $ret     = $code->();
                $errored = 0;
            };
            $error   = $@;
            $errored = 1 if not $tb->is_passing;
            @details = $tb->details;
            return $ret;
        }
    );
    if ($errored) {
        if ($error) {
            $outer_tb->diag("===[Error]==");
            $outer_tb->diag( explain $error);
        }
        $outer_tb->diag("==[GuardVal]==");
        $outer_tb->diag( explain $guardval);
        $outer_tb->diag("==[Subtest History]==");
        my $i = 0;
        for my $detail (@details) {
            my $brand = $detail->{actual_ok} ? "ok" : "no";
            $brand .= ':.' . $detail->{type} if $detail->{type};
            my $label = $detail->{name};
            $label .= " => " . $detail->{reason} if $detail->{reason};
            $outer_tb->diag( sprintf "%s=%s : %s", $i++, $brand, $label );
        }
    }
}

sub import {
    no strict;
    *{ caller() . '::guarded' } = \&guarded;
}

1;
