use strict;
use warnings;
package Plack::Middleware::Cleanup;
{
  $Plack::Middleware::Cleanup::VERSION = '0.002';
}
# ABSTRACT: Run cleanup code after request completion

use parent 'Plack::Middleware';


sub _guard (&) {
    bless $_[0], 'Plack::Middleware::Cleanup::Guard';
}

sub call {
    my ($self, $env) = @_;
    my @queue;
    $env->{'cleanup.register'} = sub { push @queue, @_ };
    $env->{'cleanup.guard'} = _guard {
        for my $item (@queue) { $item->() }
    };
    return $self->app->($env);
}

package Plack::Middleware::Cleanup::Guard;
{
  $Plack::Middleware::Cleanup::Guard::VERSION = '0.002';
}

sub DESTROY { $_[0]->() }

1;

__END__
=pod

=head1 NAME

Plack::Middleware::Cleanup - Run cleanup code after request completion

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $app = sub {
        my $env = shift;
        $env->{'cleanup.register'}->(sub {
            # do some long running task
            # careful not to reference $env!
            ...
        });
        ...
    };

    builder {
        enable 'Cleanup';
        $app;
    };

=head1 DESCRIPTION

This middleware makes it possible to run code after the request cycle is
complete and the client has received the response.

Your application will see a callback in C<< $env->{'cleanup.register'} >>.
Call this callback with any number of coderefs that you want to be invoked
after the request is complete.

Make sure your coderefs do not accidentally refer to C<< $env >>, or you will
have a circular reference and leak memory (also, your coderefs will never run).

=head1 AUTHOR

Hans Dieter Pearcey <hdp@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

