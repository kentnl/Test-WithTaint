#!/usr/bin/env perl
# ABSTRACT: Generates README.pod

use strict;
use warnings;

my $target = './README.pod';
my $source = './lib/Test/WithTaint.pm';

require Pod::Perldoc::ToPod;
my $parser = Pod::Perldoc::ToPod->new();
open my $fh, '>', $target or die "Can't write to $target, $! $?";
$parser->parse_from_file( $source, $fh );
