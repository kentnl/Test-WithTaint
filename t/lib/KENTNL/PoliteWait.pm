use strict;
use warnings;

package KENTNL::PoliteWait;

# ABSTRACT: Delay to show a message only when there's somebody home

use Test::More ();

BEGIN {
    *diag = \&Test::More::diag;
}

sub maybe_sleep {
    my ($size) = @_;

    # in order to do the pause thing:
    # - users must be able to give input in their terminal
    return unless -t STDIN;

    # - users must have a terminal for stdout
    # and -p must be supported for "prove"
    return unless ( -t STDOUT || -p STDOUT );

    # Note: Other implementations sleep in other conditions... for some reason.
    # we still print regardless, but we don't sleep, so who cares.
    diag "[ Sleeping for $size Seconds ]";
    return sleep $size;
}

sub import {
    no strict;
    *{ caller() . '::maybe_sleep' } = \&maybe_sleep;
}

1;
