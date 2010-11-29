package Catalyst::Plugin::MemoryUsage;
#ABSTRACT: Profile memory usage of requests

use strict;
use warnings;

use namespace::autoclean;
use Moose::Role;
use MRO::Compat;

use Memory::Usage;

our $VERSION = '0.0.1';

=head1 SYNOPSIS

In YourApp.pm:

    package YourApp;

    use Catalyst qw/
        MemoryUsage
    /;

In a Controller class:

    sub foo :Path( '/foo' ) {
         # ...
         
         something_big_and_scary();
         
         $c->memory_usage->record( 'finished running iffy code' );
         
         # ...
    }
    
=head1 DESCRIPTION

C<Catalyst::Plugin::MemoryUsage> adds a memory usage profile to your debugging
log, which looks like this:   

    [debug] memory usage of request
    time    vsz (  diff)    rss (  diff) shared (  diff)   code (  diff)   data (  diff)
        0  45304 ( 45304)  38640 ( 38640)   3448 (  3448)   1112 (  1112)  35168 ( 35168) preparing for the request
        0  45304 (     0)  38640 (     0)   3448 (     0)   1112 (     0)  35168 (     0) after Galuga::Controller::Root : _BEGIN
        0  45304 (     0)  38640 (     0)   3448 (     0)   1112 (     0)  35168 (     0) after Galuga::Controller::Root : _AUTO
        0  46004 (   700)  39268 (   628)   3456 (     8)   1112 (     0)  35868 (   700) finished running iffy code
        0  46004 (     0)  39268 (     0)   3456 (     0)   1112 (     0)  35868 (     0) after Galuga::Controller::Entry : entry/index
        0  46004 (     0)  39268 (     0)   3456 (     0)   1112 (     0)  35868 (     0) after Galuga::Controller::Root : _ACTION
        1  47592 (  1588)  40860 (  1592)   3468 (    12)   1112 (     0)  37456 (  1588) after Galuga::View::Mason : Galuga::View::Mason->process
        1  47592 (     0)  40860 (     0)   3468 (     0)   1112 (     0)  37456 (     0) after Galuga::Controller::Root : end
        1  47592 (     0)  40860 (     0)   3468 (     0)   1112 (     0)  37456 (     0) after Galuga::Controller::Root : _END
        1  47592 (     0)  40860 (     0)   3468 (     0)   1112 (     0)  37456 (     0) after Galuga::Controller::Root : _DISPATCH

=cut

has memory_usage => (
    is => 'rw',
    default => sub { Memory::Usage->new },
);

sub reset_memory_usage {
    my $self = shift;

    $self->memory_usage( Memory::Usage->new );
}

after execute => sub {
    my $c = shift;

    $c->memory_usage->record( "after ". join " : ", @_ );
};

around prepare => sub {
    my $orig = shift;
    my $self = shift;

    my $c = $self->$orig( @_ );

    $c->reset_memory_usage;
    $c->memory_usage->record( 'preparing for the request' );

    return $c;
};

before finalize => sub {
    my $c = shift;

    $c->log->debug( 'memory usage of request', $c->memory_usage->report );
};

1;
