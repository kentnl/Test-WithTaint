use strict;
use warnings;

use Test::More;

# ABSTRACT: check the API mechanics

require Test::WithTaint;
my $file;
my $reason;

no warnings 'redefine', 'once';

local *Test::WithTaint::_exec_tainted =
  sub { $file = $_[0]; die "Flow Control"; };
local *Test::WithTaint::_exit_skipall =
  sub { $reason = $_[0]; die "Would Skip"; };

eval { Test::WithTaint->import() };
is(
    $file,
    sub { [caller]->[1] }
      ->(), "exec_file() invokes the test script"
);
undef $file;

eval { Test::WithTaint->import( -exec => 't/Idonotexist.t' ) };
is( $file, 't/Idonotexist.t',
    "exec_file(-exec => named_script) invokes the named script" );
undef $file;

local $@ = undef;
eval { Test::WithTaint->import( -exec => 't/Idonotexist.t', 'bogus' ) };
like( $@, qr/E<Test::WithTaint>0x01]/, 'Garbage args cause tears' );

undef $@;
eval { Test::WithTaint->import('-exec') };
like( $@, qr/E<Test::WithTaint>0x01]/, 'Garbage args cause tears x 2' );

undef $@;
eval { Test::WithTaint->import('garbage') };
like( $@, qr/E<Test::WithTaint>0x01]/, 'Garbage args cause tears x 3' );

undef $@;
eval { Test::WithTaint->import( 'garbage', 'garbage' ) };
like( $@, qr/E<Test::WithTaint>0x01]/, 'Garbage args cause tears x 4' );

undef $@;
undef $file;
local $Test::WithTaint::_INTERNAL_::TAINT_ENABLED = 1;
eval { Test::WithTaint->import() };
ok( !$@,    "No exception, pass through" );
ok( !$file, "No file becuse exec not called" );

undef $@;
undef $file;
local $Test::WithTaint::_INTERNAL_::TAINT_ENABLED = 1;
eval { Test::WithTaint->import( -exec => 'file.t' ) };
ok( $@, "Different files should reexec even in taint" );
is( $file, 'file.t', 'file should be the passed name' );

undef $@;
undef $file;
local $Test::WithTaint::_INTERNAL_::TAINT_ENABLED   = "";
local $Test::WithTaint::_INTERNAL_::TAINT_SUPPORTED = "";
eval { Test::WithTaint->import() };
like( $@, qr/Would Skip/, "Taint unsupported should skip" );
ok( !$file, "skipchk: No file because exec not called" );

undef $@;
undef $file;
local $Test::WithTaint::_INTERNAL_::TAINT_ENABLED   = "";
local $Test::WithTaint::_INTERNAL_::TAINT_SUPPORTED = "";
eval { Test::WithTaint->import( -exec => 'file.t' ) };
like( $@, qr/Would Skip/, "Taint unsupported should skip w/ -exec" );
ok( !$file, "skipchk: No file because exec not called w/ -exec" );

done_testing;

