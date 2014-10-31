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

my @cases = (
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/README' =>
			'http://api.metacpan.org/source/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/README'
	],
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/sample/index.html' =>
			'http://api.metacpan.org/source/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/sample/index.html'
	],
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/lib/CPAN/Test/Dummy/SCO/Separate.pm'
			=> 'http://api.metacpan.org/source/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/lib/CPAN/Test/Dummy/SCO/Separate.pm'
	],
);

plan tests => 3 * @cases;

foreach my $c (@cases) {
	test_psgi $app, sub {
		my $cb  = shift;
		my $res = $cb->( GET $c->[0] );
		is $res->code, 301, 'code 301';
		ok $res->is_redirect, 'redirect';

		is $res->header('Location'), $c->[1];
	};
}

