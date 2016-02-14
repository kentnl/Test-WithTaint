#!/usr/bin/env perl
# FILENAME: gen_deps.pl
# CREATED: 12/24/15 18:16:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Generate a cpanfile by skimming your source tree

use strict;
use warnings;

use PIR;

use lib 'maint/lib';

use KENTNL::Prereqr;

my $ignore = PIR->new->name('perlcritic.rc.gen.pl');

my %rules = (
    'Makefile.PL' => PIR->new->max_depth(1)->perl_file->name('Makefile.PL'),
    'perl_file'   => PIR->new->perl_file->not($ignore),
    'perl_module' => PIR->new->perl_module->not($ignore),
);

my %paths = (
    '' => {
        'Makefile.PL' => { deps_to => [ 'configure', 'requires' ] }
    },
    'inc' => {
        'perl_file'   => { deps_to     => [ 'configure', 'requires' ] },
        'perl_module' => { provides_to => ['configure'] },
    },
    'lib' => {
        perl_file   => { deps_to => [ 'runtime', 'requires' ] },
        perl_module => {
            provides_to =>
              [ 'runtime', 'test', 'authortest', 'releasetest', 'smoketest' ]
        },
    },
    'maint' => {
        perl_file   => { deps_to     => [ 'develop', 'requires' ] },
        perl_module => { provides_to => ['develop'] },
    },
    'Distar' => {
        perl_file   => { deps_to     => [ 'develop', 'requires' ] },
        perl_module => { provides_to => ['develop'] },
    },
    'xt/author' => {
        perl_file => {
            deps_to     => [ 'authortest', 'requires' ],
            provides_to => ['authortest']
        },
    },
    'xt/release' => {
        perl_file => {
            deps_to     => [ 'releasetest', 'requires' ],
            provides_to => ['releasetest']
        },
    },
    'xt/smoke' => {
        perl_file => {
            deps_to     => [ 'smoketest', 'requires' ],
            provides_to => ['smoketest']
        },
    },
    't' => {
        perl_file   => { deps_to => [ 'test', 'requires' ] },
        perl_module => {
            provides_to => [ 'test', 'authortest', 'releasetest', 'smoketest' ]
        },
    },
);

my $crules = [];
for my $path ( keys %paths ) {
    for my $rule ( keys %{ $paths{$path} } ) {
        push @{$crules},
          {
            rule     => $rules{$rule},
            start_in => [$path],
            %{ $paths{$path}{$rule} },
          };
    }
}
my $prereqr = KENTNL::Prereqr->new( rules => $crules );

my ( $prereqs, $provided ) = $prereqr->collect;

use Module::CPANfile;
use Data::Dumper qw();
use CPAN::Meta::Converter;
use Path::Tiny qw( path );

my $cpanfile =
  Module::CPANfile->from_prereqs( $prereqr->prereqs->as_string_hash );
$cpanfile->save('cpanfile');

my $dumper = Data::Dumper->new( [] );
$dumper->Terse(1)->Sortkeys(1)->Indent(1)->Useqq(1)->Quotekeys(0);
path('maint/provided.pl')->spew_raw(
    $dumper->Values(
       [ CPAN::Meta::Converter::_dclone( $provided->{runtime} || {} ) ]
    )->Dump
);
path('t/00-prereqs.dd')->spew_raw(
    $dumper->Values(
      [ CPAN::Meta::Converter::_dclone( $prereqr->prereqs_report ) ]
    )->Dump
)
