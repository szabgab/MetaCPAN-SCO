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

subtest authors => sub {
	plan tests => 6;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/author/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		contains( $html, q{<br><div class="t4">Author</div><br>}, 'Author' );
		contains( $html, q{<a href="?A"> A </a>}, 'link to A' );
		contains( $html, q{<a href="?M"> M </a>}, 'link to M' );
		contains( $html, q{<a href="?Q"> Q </a>}, 'link to Q' );
	};
};

subtest authors_q => sub {
	plan tests => 5;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/author/?Q' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		like( $html, qr{<td>\s*Q\s*</td>}, 'Q without link' );
		unlike( $html, qr{<td>Q</td>}, 'no link to Q' );
		contains(
			$html,
			q{<a href="/~qantins/"><b>QANTINS</b></a><br/><small>Marc Qantins</small>},
			'QANTINS'
		);
	};
};

