use strict;
use warnings;

use Test::WithTaint;

# ABSTRACT: Demonstrate taint-respawn

use Test::More 0.87_01 tests => 1;

ok( Test::WithTaint::taint_enabled, "Respawn with taint enabled ok" );

done_testing;
