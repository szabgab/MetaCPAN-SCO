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

subtest recent => sub {
	plan tests => 4;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/recent' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{<div class="t4"> Uploads <a title="RSS 1.0" href="/uploads.rdf">}
		);
	};
};

# TODO: /uploads.rdf

