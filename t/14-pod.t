use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Test::HTML::Tidy;

use t::lib::Test;

plan tests => 2;

use MetaCPAN::SCO;

my $tidy = html_tidy();

my $app = MetaCPAN::SCO->run;
subtest pod_separate_pm => sub {
	plan tests => 4;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET
				'/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/lib/CPAN/Test/Dummy/SCO/Special.pm'
			)->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{http://localhost/dist/CPAN-Test-Dummy-SCO-Special/lib/CPAN/Test/Dummy/SCO/Special.pm}
		);
	};
};

subtest pod_dist_separate_pm => sub {
	plan tests => 4;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET
				'/dist/CPAN-Test-Dummy-SCO-Special/lib/CPAN/Test/Dummy/SCO/Special.pm'
			)->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		unlike( $html, qr{canonical}, 'no canonical link' );
	};
};

