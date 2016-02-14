use strict;
use warnings;

use Test::More;

# ABSTRACT: Makes sure the beep mechanism works

# This tests checks the maybe_sleep mechanism for pausing at the end of a failed
# test to help inform the author about the problem and request
# feedback.

BEGIN {
  local @INC = ('t/lib',@INC);
  require KENTNL::PoliteWait;
  KENTNL::PoliteWait->import();
}

my $sleep = 5;
diag "\n---[ Manual Check ]---";
diag "1. This test should beep";
diag "2. This test should visibly induce a pause";
diag "   of $sleep seconds under normal testing conditions";
diag "   imporatantly: under make test, prove, and perl -Ilib t/...";
diag "3. Lack of a pause in interactively running this test is thus";
diag "   considered a bug";
diag "4. Existence of a pause when testing non-interactively is deemed";
diag "   undesirable, but unavoidable if it conflicts with #3";
diag "   (e.g: Being under Test::Harness implies pipe-redirection)";
my $now = time;
diag sprintf '%4$02d:%3$02d:%2$02d - %1$s',
  "Sleeping For \e[31m$sleep\e[0m seconds\x07", @{ [ localtime $now ] };
maybe_sleep($sleep);
my $second  = time;
my $elapsed = $second - $now;
diag sprintf '%4$02d:%3$02d:%2$02d - %1$s',
  "Done in \e[32m$elapsed\e[0m seconds \x07", @{ [ localtime $second ] };

pass("Manual Confirmation required");

done_testing;
