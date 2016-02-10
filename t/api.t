use strict;
use warnings;

use Test::More 0.95_01;    # subtest imply done_testing

# ABSTRACT: Test the API for import is consistent
#
# This test is simply to check the mapping of the ->import() method to various conditions
# in order to assure the consistency of the syntax defined in import.

# Tools
BEGIN {
    no strict 'refs';

    package Ex;
    use overload q[""] => sub { $_[0]->[0] };
    *{'Ex::payload'} = sub { $_[0]->[1] };

    package Ex::R;
    *{'Ex::R::ok'}     = sub { $_[0]->[0] };
    *{'Ex::R::return'} = sub { $_[0]->[2] };
    *{'Ex::R::error'}  = sub { $_[0]->[1] };
}
sub ex  { bless [@_], "Ex" }
sub exr { bless [@_], "Ex::R" }

sub get_ex(&) {
    my ( $code, ) = @_;
    my ( $ok, $return );
    local $@;
    eval { $return = $code->(); $ok = 1 };
    return exr( $ok, $@, $return );
}

# This does a whole bunch of handy shit:
#
# gsubtest name => sub { return $guardval => $checking_sub };
# Then "checking_sub" is executed in a subtest.
# And if it fails or bails, guardval is reported in the failure along with the error
# and all the tests that happened in the subtest which are defacto hidden in CPAN smokers.
#
# g = guarded/generative
sub gsubtest {
    my ( $name, $generator ) = @_;
    my $errored = 1;
    my $guardval;
    my $error;
    my (@details);
    subtest $name => sub {
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
    };
    if ($errored) {
        if ($error) {
            diag "===[Error]==";
            diag explain $error;
        }
        diag "==[GuardVal]==";
        diag explain $guardval;
        diag "==[Subtest History]==";
        my $tb = Test::Builder->new();
        my $i  = 0;
        for my $detail (@details) {
            my $brand = $detail->{actual_ok} ? "ok" : "no";
            $brand .= ':.' . $detail->{type} if $detail->{type};
            my $label = $detail->{name};
            $label .= " => " . $detail->{reason} if $detail->{reason};
            diag sprintf "%s=%s : %s", $i++, $brand, $label;
        }
    }
}

# Mock glue
BEGIN {
    require Test::WithTaint;
    no warnings 'redefine';
    *Test::WithTaint::_withtaint_self = sub {
        die ex( "_withtaint_self called E<$0>0x01", { args => \@_ } );
    };
    *Test::WithTaint::_withtaint_other = sub {
        die ex( "_withtaint_other called E<$0>0x02", { args => \@_ } );
    };
}

# Test
gsubtest "self-dispatch" => sub {
    get_ex { Test::WithTaint->import() } => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/api\.t>0x01/,
            "Empty list dispatched to self-dispatch" );
        like( $_->error->payload->{args}->[1],
            qr/api\.t$/, "Name of self passed correctly" );
    };
};

gsubtest "external-dispatch" => sub {
    get_ex { Test::WithTaint->import( -exec => 't/idontexist.t' ) } => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/api\.t>0x02/,
            "-exec list dispatched to runscript method" );
        like( $_->error->payload->{args}->[1],
            qr{\Qt/idontexist.t\E$}, "Name of self passed correctly" );
    };
};

gsubtest "external-dispatch+excess arguments" => sub {
    get_ex { Test::WithTaint->import( -exec => 't/idontexist.t', 'extra' ) } =>
      sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
      };
};

gsubtest "external-dispatch+missing_file" => sub {
    get_ex { Test::WithTaint->import('-exec') } => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

gsubtest "bad arguments" => sub {
    get_ex { Test::WithTaint->import('bad argument') } => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

gsubtest "two bad arguments" => sub {
    get_ex { Test::WithTaint->import( 'bad argument', 'bad argument' ) } =>
      sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
      };
};

done_testing;

