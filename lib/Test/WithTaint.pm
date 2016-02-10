use 5.006;
use strict;
use warnings;

package Test::WithTaint;

our $VERSION = '0.001000';
our $AUTHORITY = 'cpan:KENTNL';

1;

__END__

=head1 NAME

Test::WithTaint - Ensure a Test is run reliably with taint

=head1 SYNOPSIS

  # re-execute self with tainting t/foo-tainting.t
  use Test::WithTaint;

  # execute a different script with tainting
  use Test::WithTaint -exec => 't/foo.t'

  # manual mode
  use Test::WithTaint qw( taint_supported taint_enabled exec_tainted )
  use Test::More;
  if ( not taint_supported ) {
    plan skip_all => "Taint not supported";
    exit 0;
  }
  if ( not taint_enabled ) {
    exec_tainted($0);
  }
  # code to exec under taint here

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
that is too hard to acheive with a hashbang trick.

  # inside foo.t
  use Test::WithTaint;

Here, the default behaviour is to:

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

=head2 Manual Mode

In the event either combination of the above are unsuitable, you can C<import> the tools
and use them yourself.

Invoking C<< Test::WithTaint->import() >> with arguments other than:

  ()
  ('-exec', $filename)

Will disable the default mechanics and regress to a pure importer.

=head1 EXPORTS

=head2 C<taint_supported>

This function determines if your Perl supports C<taint>.

Presently, all Perl versions support C<taint>, and so the future-proof mechanism
to see if Perl supports taint entails invoking a small test script under taint mode and seeing if it fails.

In the event that some 3rd party patch is applied that inhibits C<taint>, or the C<%ENV> scrubbing
technique is not sufficient to make C<taint> work, this test will fail and return C<undef>,
indicating that the other exports in this module cannot be expected to work.

=head2 C<taint_enabled>

This function determines if your Perl is currently running in C<taint> mode.

On Perls newer than Perl v5.8.0, this checks C<${^TAINT}> and returns C<1>
if C<${^TAINT}> is C<1>, and returns C<undef> otherwise.

On Perls older than Perl v5.8.0, a simple bit of code that should cause an exception
is executed, and returns C<1> if the exception occurred, and returns C<undef> otherwise.

=head2 C<exec_tainted>

This function allows passing control (via C<exec>) to an arbitrary Perl Script described by a relative path.

The function will clean up C<%ENV> in some small ways to encourage it to give the desired result before
invoking C<$^X -T $relpath> ( Or some logical equivalent with platform specific protections as necessary.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut