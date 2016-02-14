#!/usr/bin/env perl
# ABSTRACT: Get run by a taint_respawner

use strict;
use warnings;

use Test::More 0.87_01;    # done_testing
use Test::WithTaint ();
ok( Test::WithTaint::taint_enabled, "Taint enabled in script" );
done_testing;
