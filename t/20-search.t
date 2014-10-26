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

subtest all => sub {
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

subtest author => sub {
	plan tests => 4 + 7;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/search?query=xyzqwery&mode=author' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{No matches}, 'no match' );
	};

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/search?query=sz&mode=author&n=100' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<a href="/~dlugosz/"><b>John M. Dlugosz</b></a>} );
		contains( $html, q{<small>DLUGOSZ</small>}, 'match' );
		contains( $html, q{<a href="/~irq/"><b>Ireneusz Pluta</b></a>} );
		contains( $html, q{<small>IRQ</small>}, 'match' );
	};

};

