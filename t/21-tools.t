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

subtest home => sub {
	plan tests => 2;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->(
			GET 'http://search.cpan.org/tools/CPAN-Test-Dummy-SCO-Special' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
	};
};

subtest home => sub {
	plan tests => 2;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET
				'http://search.cpan.org/tools/CPAN-Test-Dummy-SCO-Special-0.04'
			)->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
	};
};

