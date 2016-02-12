use 5.006;
use strict;
use warnings;

package Test::WithTaint;

our $VERSION   = '0.001000';
our $AUTHORITY = 'cpan:KENTNL';

sub import {
    my ( $self, @args ) = @_;
    if ( not @args ) {
        return $self->_withtaint_self( [caller]->[1] );
    }
    if ( 2 == @args and '-exec' eq $args[0] ) {
        return $self->_withtaint_other( $args[1] );
    }
    die 'Unrecognized arguments to import() [E<Test::WithTaint>0x01]';
}

sub _withtaint_self {
    my ( undef, $file ) = @_;    ## no critic (Variables)
    die 'Simple Self-Rexec not implemented [E<Test::WithTaint>0x02]';
}

sub _withtaint_other {
    my ( undef, $file ) = @_;    ## no critic (Variables)
    die 'Chain to other script unimplemented [E<Test::WithTaint>0x03]';
}

# these are not documented externally on purpose

=begin Pod::Coverage

detaint perl_path taint_supported

=end Pod::Coverage

=cut

# This variable is only visible externally for testing purposes
# but otherwise exists to cache the call because throwing system()
# around hurts.
our $_TAINT_SUPPORTED;

# Note: This is for testing purposes only.
#       so that we can turn it off to emulate a
#       Perl where -T has no effect.
our $_TAINT_FLAG = '-T';

sub taint_supported {
    return $_TAINT_SUPPORTED if defined $_TAINT_SUPPORTED;

# Note: Taint applies at the expression level, so any statement invoking sensitive
# function calls which also has a tainted value in it will fail
#
# The test code generates a 0-length string that is tainted
# by stealing a taint bit from $0, which is always tainted.
#
# Then evals that substring in a comment for an eval that does nothing
# when it succeeds, and the eval itself should bail under taint.
#
# Important:
# - Under Taint, exit should be 42 because the outer eval will fail.
# - Under a perl where Taint is silently disabled, exit should be 1
#   as the outer eval should not fail
# - Under a perl where -T causes an error, exit should be a value other than 42
    system(
        detaint( perl_path() ) => $_TAINT_FLAG,
        '-e' => q[eval{eval q[#] . substr $0,0,0;exit 1};exit 42],
    );
    my $exit = $? >> 8;
    return ( $_TAINT_SUPPORTED = ( 42 == $exit ) );
}

sub perl_path { $^X }
sub detaint   { $_[0] =~ /\A(.*)\z/ }
1;

__END__

=head1 NAME

Test::WithTaint - Ensure a Test is run reliably with taint

=head1 SYNOPSIS

  # re-execute self with tainting t/foo-tainting.t
  use Test::WithTaint;

  # execute a different script with tainting
  use Test::WithTaint -exec => 't/foo.t'

=head1 DESCRIPTION

This module aims to facilitate taint testing in several ways.

=over 4

=item * Permit skipping taint-dependent tests in the event a future Perl release lacks taint support

=item * Permit forcing taint mode on a test that is not already running in taint mode

=item * Simplify running the an existing test both in and out of taint mode

=item * Clean up environment when invoking taint-dependent tests to avoid common traps in taint + %ENV

=back

=head1 USAGE

=head2 Simple Mode

This mode is the most recommended usage, and it adds a layer of safety
that is too hard to achieve with a hash-bang trick.

  # inside foo.t
  use Test::WithTaint;

Here, the default behavior is to:

=over 4

=item * Check your Perl supports tainting, and skip the test if it does not.

=item * Check your Perl is running in taint mode, and continue execution if it is.

=item * In the event Perl is B<NOT> running in taint mode, clean up the environment slightly
and re-execute the test under taint mode.

=back

=head2 Indirect Mode

This mode is a variation on C<SimpleMode> designed to reduce code duplication.

  # inside foo-tainted.t
  use Test::WithTaint -exec => 't/foo.t';

This:

=over 4

=item * Checks Perl supports tainting, and skips the test if it does not.

=item * Cleans up the environment, and Forcefully invokes the test passed to C<-exec> with C<exec>;

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
