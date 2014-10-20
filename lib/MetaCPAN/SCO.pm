package MetaCPAN::SCO;
use strict;
use warnings;

use Plack::Request;

our $VERSION = '0.01';

=head1 NAME

SCO - search.cpan.org clone

=cut

sub run {
	my $app = sub {
		my $env = shift;

		my $request = Plack::Request->new($env);
		if ($request->path_info eq '/') {
			return [ '200', [ 'Content-Type' => 'text/plain' ], ['Hello'], ];
		}

		return [ '404', [ 'Content-Type' => 'text/html' ], ['404 Not Found'], ];
	};
}


1;

