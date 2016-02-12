use strict;
use warnings;

use Test::More;

# ABSTRACT: Check the taint_supported function

# This is a hard thing to test because we can't create a system without taint support.
# also, the test itself would have to know if perl supports taint somehow in advance
# in order to know if taint_supported is returning the right value.
#
# Subsquently, we're just writing this test so that in the event somebody one day ships
# a perl where taint is *NOT* supported, This test will fail, and hopefully we'll
# be able to implement a test *after* that point .. somehow.

use Test::WithTaint ();

my $full_diag;
my $install_expected;    # TODO: Compute the real value it should be here.
{
    local $@;
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        $full_diag = 1;
        diag explain $@;
    };
    ok( $supported, "Taint is supported" ) or $full_diag = 1;

    # TODO: Check supported == install_expected
    # presently, we just compute this from the first invocation.
    # but ideally, we should be checking the return value of taint_supported
    # against some other data
    $install_expected = $supported;
}

# Re-test to ensure the post-verification branch returns the same result.
{
    local $@;
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        diag explain $@;
    };
    cmp_ok( $supported, '==', $install_expected,
        'Re-checking confirms previous result' );

}
{
    local $@;
    local $Test::WithTaint::_TAINT_SUPPORTED = undef;

  # This replaacement for '-T' intends to mimic a perl where '-T' ceases to have
  # any effect and silently runs perl without tainting
    local $Test::WithTaint::_TAINT_FLAG = '-Mstrict';
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        diag explain $@;
    };
    ok( !$supported, "(faked) Taint that noops says 'unsupported'" );
}
{
    local $@;
    local $Test::WithTaint::_TAINT_SUPPORTED = undef;

    # This replacement for '-T' intends to mimic a perl where '-T' is causes
    # perl to exit with an error condition
    local $Test::WithTaint::_TAINT_FLAG = '-Mstrict;exit(1)';
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        diag explain $@;
    };
    ok( !$supported, "(faked) Taint that dies says 'unsupported'" );
}

if ($full_diag) {
    diag "**** Your Perl Does not Support Taint ---------*****\x07";
    diag "**                                                **";
    diag "** Please inform the author of Test::WithTaint    **";
    diag "** so this test can produce the right results     **";
    diag "**                                                **";
    sleep 1;
    diag "****************************************************\x07";
    sleep 2;
}

done_testing;

