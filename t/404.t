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
	/~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/abc
	/~szabgab/CPAN-Test-Dummy-SCO-Special-0/
	/~tlinden/apid-0.04/
	/tools/CPAN-Test-Dummy-Perl5-Specia
	/author/1
);

plan tests => 2 * @urls;

foreach my $url (@urls) {
	test_psgi $app, sub {
		my $cb   = shift;
		my $res  = $cb->( GET $url );
		my $html = $res->content;
		contains( $html, 'Not found', $url );
		is $res->code, 404, "code 404 for $url";
	};
}

