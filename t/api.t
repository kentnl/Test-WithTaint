use strict;
use warnings;

use Test::More 0.95_01;    # subtest imply done_testing

# ABSTRACT: Test the API for import is consistent
#
# This test is simply to check the mapping of the ->import() method to various conditions
# in order to assure the consistency of the syntax defined in import.

#Tools
BEGIN {
    local @INC = ( 't/lib', @INC );
    require KENTNL::Catcher;
    require KENTNL::GuardTest;
    KENTNL::Catcher->import();
    KENTNL::GuardTest->import();
}

our @EX_ARGS;

# Mock glue
BEGIN {
    require Test::WithTaint;
    no warnings 'redefine';
    *Test::WithTaint::_withtaint_self = sub {
        @EX_ARGS = @_;
        die "_withtaint_self called E<$0>0x01";
    };
    *Test::WithTaint::_withtaint_other = sub {
        @EX_ARGS = @_;
        die "_withtaint_other called E<$0>0x02";
    };
}

# Test
guarded "self-dispatch" => sub {
    local @EX_ARGS;
    my $e = catch { Test::WithTaint->import() };
    my @args = @EX_ARGS;
    return { exception => $e, context_args => \@args } => sub {
        ok( !$e->ok, "Exception triggered" );
        like( $e->error, qr/api\.t>0x01/,
            "Empty list dispatched to self-dispatch" );
        like( $args[1], qr/api\.t$/, "Name of self passed correctly" );
    };
};

guarded "external-dispatch" => sub {
    local @EX_ARGS;
    my $e = catch { Test::WithTaint->import( -exec => 't/idontexist.t' ) };
    my @args = @EX_ARGS;
    return { exception => $e, context_args => \@args } => sub {
        ok( !$e->ok, "Exception triggered" );
        like( $e->error, qr/api\.t>0x02/,
            "-exec list dispatched to runscript method" );
        like( $args[1],
            qr{\Qt/idontexist.t\E$}, "Name of self passed correctly" );
    };
};

guarded "external-dispatch+excess arguments" => sub {
    my $e = catch {
        Test::WithTaint->import( -exec => 't/idontexist.t', 'extra' )
    };
    return $e => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

guarded "external-dispatch+missing_file" => sub {
    my $e = catch { Test::WithTaint->import('-exec') };
    return $e => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

guarded "bad arguments" => sub {
    my $e = catch { Test::WithTaint->import('bad argument') };
    return $e => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

guarded "two bad arguments" => sub {
    my $e = catch {
        Test::WithTaint->import( 'bad argument', 'bad argument' )
    };
    return $e => sub {
        ok( !$_->ok, "Exception triggered" );
        like( $_->error, qr/E<Test::WithTaint>0x01/, "bad arguments detected" );
    };
};

done_testing;

