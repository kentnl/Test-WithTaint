use strict;
use warnings;

use Test::More;
use File::Spec;
use ExtUtils::MakeMaker;

# ABSTRACT: Hacky prereqs reporter

my $deps = do './t/00-prereqs.dd' or die "$@ $!";

diag "# Quick Version Report";
for my $module ( sort keys %{$deps} ) {
    for my $version ( sort keys %{ $deps->{$module} } ) {
        report_dep( $module, $version, $deps->{$module}->{$version} );
    }
}

sub fmt_line {
    diag sprintf "%-30s = %10s -> %-10s ( %s )", @_;
}

sub report_dep {
    my ( $module, $version, $phases ) = @_;
    if ( $module eq 'perl' ) {
        fmt_line( 'perl', $version, $], $phases );
        return;
    }
    report_version( $module, mod_to_pm($module), $version,
        $deps->{$module}->{$version} );
}

sub mod_to_pm {
    my $file = $_[0];
    $file =~ s{::}{/}g;
    $file .= ".pm";
    for my $prefix ( grep { not ref } @INC ) {
        my $path = File::Spec->catfile( $prefix, $file );
        return $path if -e $path;
    }
    return undef;
}

sub report_version {
    my ( $module, $path, $want, $phases ) = @_;
    if ( not defined $path or ( not -e $path or -d $path ) ) {
        diag "[missing] $module $want ( $phases )";
        return;
    }
    local $@;
    eval {
        my $have = MM->parse_version($path);
        $want = 'any'   if !$want;
        $have = 'undef' if not defined $have;
        fmt_line( $module, $want, $have, $phases );
        1;
    } or warn "$@";
    return;
}

pass("Prereqs shown");

done_testing();
