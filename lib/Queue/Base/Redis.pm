package Queue::Base::Redis;

use strict;
use warnings;
use base 'Queue::Base';
use Redis;
use Try::Tiny;
use Carp;

=head1 NAME

Queue::Base::Redis - Using Redis as driver!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module do not guarantees order.

    use Queue::Base::Redis

    # construction
    my $queue = Queue::Base::Redis->new(server => 'foo');

    # add a new element to the queue
    $queue->add($element);

    # remove the next element from the queue
    if (! $queue->empty) {
        my $element = $queue->remove;
    }

    # or
    $element = $queue->remove;
    if (defined $element) {
        # do some processing here
    }

    # add/remove more than just one element
    $queue->add($elem1, $elem2 ...)
    # and
    @elements = $queue->remove(5);
	

=cut

=head2 new 

Work exatly like Queue::Name but you can specific redis server.
    
	my $queue = Queue::Base::Redis->new(server => 'foo');

=cut

sub new {
    my ( $class, $elems ) = @_;
    my $self = bless(
        {
            list        => [],
            _redis      => sub { },
            server      => '',
            queue_sufix => 'my_queue',
        },
        $class
    );
    $self->{_redis} = $self->_redis_connect;

    if ( defined $elems && ref($elems) eq 'ARRAY' ) {
        $self->add( @{$elems} );
    }

    return $self;
}

=head2 _redis 

Internal

=head2 redis

Internal

=head2 _redis_connect

Internal

=head2 q_name

Internal

=cut

sub _redis { shift->{_redis} }

sub redis {
    my $self = shift;
    try {
        $self->_redis->ping;
        return $self->_redis;
    }
    catch {
        return $self->_redis_connect;
    };
}

sub _redis_connect {
    my $self = shift;
    $self->{server}
      ? return Redis->new( server => $self->{server} )
      : return Redis->new();
}

sub q_name {
    my ( $self, $element ) = @_;
    return $self->{queue_sufix} . '.' . $element;
}

sub add {
    my ( $self, @args ) = @_;
    push @{ $self->{list} }, @args;
    foreach my $ele (@args) {
        $self->redis->rpush( $self->q_name($ele), 1 );
    }
    return;
}

sub remove_all {
    my $self = shift;
    my @keys = @{ $self->allkeys };
    $self->clear;
    return @keys;
}

sub allkeys {
    my $self  = shift;
    my $sufix = $self->{queue_sufix};
    my @keys  = $self->redis->keys("$sufix.*");
    return \@keys;
}

sub remove {
    my $self = shift;
    my $num = shift || 1;

    croak 'Paramater must be a positive number' unless 0 < $num;

    my @removed = ();

    my $count = $num;
    while ($count) {
        $count--;
        my $key = $self->redis->randomkey;
        last unless defined $key;
        $self->redis->del($key);
        push @removed, $key;
    }

    return @removed;
}

sub size {
    return scalar( @{ shift->allkeys } );
}

sub clear {
    my $self = shift;
    foreach my $key ( @{ $self->allkeys } ) {
        $self->redis->del($key);
    }
    return;
}

=head2 Methods

=over

=item add [LIST_OF_ELEMENTS]

Adds the LIST OF ELEMENTS to the end of the queue.

=item remove [NUMBER_OF_ELEMENTS]

In scalar context it returns the first element from the queue.

In array context it attempts to return NUMBER_OF_ELEMENTS requested;
when NUMBER_OF_ELEMENTS is not given, it defaults to 1.

=item remove_all

Returns an array with all the elements in the queue, and clears the queue.

=item size

Returns the size of the queue.

=item empty

Returns whether the queue is empty, which means its size is 0.

=item clear

Removes all elements from the queue.

=back


=head1 AUTHOR

Daniel de Oliveira Mantovani, C<< <daniel.oliveira.mantovani at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-queue-base-redis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Queue-Base-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Queue::Base::Redis


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Queue-Base-Redis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Queue-Base-Redis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Queue-Base-Redis>

=item * Search CPAN

L<http://search.cpan.org/dist/Queue-Base-Redis/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Daniel de Oliveira Mantovani.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Queue::Base::Redis
