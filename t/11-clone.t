use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);

plan tests => 2;

use MetaCPAN::SCO;

my $app = MetaCPAN::SCO->run;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{<title>The CPAN Search Site - search.cpan.org</title>},
		'root route'
	);
};

