package KENTNL::Catcher;
use strict;
use warnings;

sub ok     { $_[0]->{'ok'} }
sub return { $_[0]->{'return'} }
sub error  { $_[0]->{'error'} }

my @POS = qw( ok error return );

sub new {
    my ( $self, @args ) = @_;
    bless { map { ( $POS[$_] => $args[$_] ) x !!$args[$_] } 0 .. $#args },
      $self;
}

sub catch(&) {
    my ( $code, ) = @_;
    my ( $ok, $return );
    local $@;
    eval { $return = $code->(); $ok = 1 };
    return __PACKAGE__->new( $ok, $@, $return );
}

sub import {
    no strict;
    *{ caller() . '::catch' } = \&catch;
}
1;

