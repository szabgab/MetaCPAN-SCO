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

# URL pairs. Given the first URL, sco should redirect to the second.
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

# TODO these files were scheduled for deletition on 31 October. They should disappear in 3 days and then the redirections should start to work
#[
#	'/~szabgab/CPAN-Test-Dummy-SCO-Pirated-1.03/' =>
#		'http://localhost/dist/CPAN-Test-Dummy-SCO-Pirated/'
#],
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Pirated-1.02/' =>
			'http://localhost/dist/CPAN-Test-Dummy-SCO-Pirated/'
	],

#[
#	'/~szabgab/CPAN-Test-Dummy-SCO-Pirated-1.03/lib/CPAN/Test/Dummy/SCO/Pirated.pm'
#		=> 'http://localhost/dist/CPAN-Test-Dummy-SCO-Pirated/lib/CPAN/Test/Dummy/SCO/Pirated.pm'
#],
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Pirated-1.02/lib/CPAN/Test/Dummy/SCO/Pirated.pm'
			=> 'http://localhost/dist/CPAN-Test-Dummy-SCO-Pirated/lib/CPAN/Test/Dummy/SCO/Pirated.pm'
	],
	[
		'/~szabgab/CPAN-Test-Dummy-SCO-Special-0.0/' =>
			'http://localhost/dist/CPAN-Test-Dummy-SCO-Special/'
	],
	[
		'/author/?Q' => '/author/Q'
	],
	[
		'/author/?q' => '/author/Q'
	],
	[
		'/author/?QQRQ' => '/author/Q'
	],
	[
		'/author/?1' => '/author/1'
	],

);

plan tests => 3 * @cases;

foreach my $c (@cases) {
	test_psgi $app, sub {
		my $cb  = shift;
		my $res = $cb->( GET $c->[0] );
		is $res->code, 301, "code 301 for $c->[0]";
		ok $res->is_redirect, "redirect $c->[0]";
		is $res->header('Location'), $c->[1], "Location for $c->[0]";
	};
}

