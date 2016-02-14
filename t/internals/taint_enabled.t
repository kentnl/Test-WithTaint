use strict;
use warnings;

use Test::WithTaint ();
use Test::More;

# ABSTRACT: Test taint_enabled mechanics

# Maintainer note: skips when you expect it not to, or vice versa,
# make sure the right Perl is being run
#    perlbrew exec --with=<> make test
# is NOT sufficient to get the right Perl
if ( not Test::WithTaint::taint_supported ) {
    plan skip_all => "Taint Support required for this test";
    done_testing;
    exit;
}

{
    is( Test::WithTaint::taint_enabled,
        Test::WithTaint::taint_enabled,
        'Caching mechanism remembers value'
    );
}

# This test makes sure the code path that will only normally execute on 5.6
# doesn't have any bugs in it
#
{
    my $taint_enabled = Test::WithTaint::taint_enabled;
    local $Test::WithTaint::_INTERNAL_::USE_CTRL_TAINT = "";
    local $Test::WithTaint::_INTERNAL_::TAINT_ENABLED  = undef;
    is( Test::WithTaint::taint_enabled,
        $taint_enabled, "Forced computed value is the same normal" );
}
{
    my $exit = do {
        local $?;
        system( $^X, '-Ilib', '-mTest::WithTaint', '-e',
            'exit (( Test::WithTaint::taint_enabled ) ? 42 : 43 )' );
        $?;
    };
    cmp_ok( $exit >> 8, '==', 43,
        'Perl without taint on reports taint_enabled as false' );
}

{
    my $exit = do {
        local $?;
        system( $^X, '-Ilib', '-mTest::WithTaint', '-T', '-e',
            'exit (( Test::WithTaint::taint_enabled ) ? 42 : 43 )' );
        $?;
    };
    cmp_ok( $exit >> 8, '==', 42,
        'Perl with taint on reports taint_enabled as true' );
}

done_testing;

