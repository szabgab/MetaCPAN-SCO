use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Test::HTML::Tidy;

use t::lib::Test;

plan tests => 1;

use MetaCPAN::SCO;

my $tidy = html_tidy();

my $app = MetaCPAN::SCO->run;

subtest search => sub {
	plan tests => 4;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/search?query=abcdefghijklmnxyzqrt&mode=all' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{No matches}, 'no match' );
	};
};

