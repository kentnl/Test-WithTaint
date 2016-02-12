use strict;
use warnings;

use Test::More;

# ABSTRACT: Check the taint_supported function

use Test::WithTaint ();

# Here lies a different mechanism to compute taint support that pokes into different
# perl guts and relies much on understanding what the world of perl looks like.
#
# The idea being to have the module itself rely on intrinsic behaviour of perls by
# default, which should cover a wider variety of techiques
#
# and then this test makes sure that technique picks up known perl behaviour
# sets.

my $support_expected = 1;

# Taint is expected to be supported prior to 5.17.10, as the NO_TAINT
# flag was added in 5.17.10. There could be other people out there in the wild with
# local patches that make this wrong somehow tho.

if ( $] >= 5.017010 ) {
    our %Config;
    require Config;
    Config->import('%Config');
    if (
        $Config{ccflags} =~ /(?:\A|\s)(-D(SILENT_)?NO_TAINT_SUPPORT)(?:\s|\z)/ )
    {
        $support_expected = 0;
        diag "Testing on perl $] with $1";
    }
}

my $full_diag;
{
    local $@;
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        $full_diag = 1;
        diag explain $@;
    };
    cmp_ok( $supported, '==', $support_expected,
        "Taint support is the expected value" )
      or $full_diag = 1;
}

# Re-test to ensure the post-verification branch returns the same result.
{
    local $@;
    my $supported;
    eval { $supported = Test::WithTaint::taint_supported(); };
    ok( !$@, "No exceptions were thrown from checking taint support" ) or do {
        diag explain $@;
    };
    cmp_ok( $supported, '==', $support_expected,
        'Cached check returns the right result' );

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
    if ($support_expected) {
        diag "**** Your Perl Does not Support Taint ---------*****\x07";
        diag "**                                                **";
        diag "** Our analysis of your Perl install indicated    **";
        diag "** that Taint Support *should* work, but our      **";
        diag "** execution tests indicated that Taint doesn't   **";
        diag "** work as expected                               **";
        diag "**                                                **";
        diag "** Please inform the author of Test::WithTaint    **";
        diag "** so this test can produce the right results     **";
        diag "**                                                **";
        sleep 1;
        diag "****************************************************\x07";
        sleep 2;
    }
    else {
        diag "**** Your Perl Unexpectedly Supports Taint ----*****\x07";
        diag "**                                                **";
        diag "** Our analysis of your Perl install indicated    **";
        diag "** that Taint Support *shouldn't* work, but our   **";
        diag "** execution tests indicated that Taint *does*    **";
        diag "** work, contrary to expectations                 **";
        diag "**                                                **";
        diag "** Please inform the author of Test::WithTaint    **";
        diag "** so this test can produce the right results     **";
        diag "**                                                **";
        sleep 1;
        diag "****************************************************\x07";
        sleep 2;
    }
}

done_testing;

