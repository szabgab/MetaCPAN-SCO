use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Test::HTML::Tidy;

use t::lib::Test;

use MetaCPAN::SCO;

my $tidy = html_tidy();

my $app = MetaCPAN::SCO->run;

my @urls = qw(
	~szabgab/CPAN-Test-Dummy-SCO-Special-0.0/
	~szabgab/CPAN-Test-Dummy-SCO-Special-0/
);

plan tests => 2 * @urls;

foreach my $url (@urls) {
	test_psgi $app, sub {
		my $cb   = shift;
		my $res  = $cb->( GET $url );
		my $html = $res->content;
		contains( $html, 'Not found' );
		is $res->code, 404, 'code 404';
	};
}

