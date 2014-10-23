use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);

plan tests => 3;

use MetaCPAN::SCO;

my $app = MetaCPAN::SCO->run;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{<title>The CPAN Search Site - search.cpan.org</title>},
		'root route'
	);
};

subtest dist_local_tie => sub {
	plan tests => 7;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~perlancar/Locale-Tie-0.03/' )->content;
		unlike $html, qr/ARRAY/;
		contains( $html, q{Locale-Tie-0.03}, 'dist-ver name' );
		contains( $html, q{23 Oct 2014},     'date' );
		contains(
			$html,
			q{<div id="permalink" class="noprint"><a href="/dist/Locale-Tie/">permalink</a></div>},
			'permalink'
		);
		contains( $html,
			q{<a href="/src/PERLANCAR/Locale-Tie-0.03/Changes">Changes</a>},
			'Changes' );
		contains( $html, q{<a href="MANIFEST">MANIFEST</a>}, 'MANIFEST' );
		contains(
			$html,
			q{<a href="http://dev.perl.org/licenses/">The Perl 5 License (Artistic 1 & GPL 1)</a>},
			'license'
		);
	};
};

sub contains {
	my ( $str, $expected, $name ) = @_;
	$name //= '';
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $res = ok 0 < index( $str, $expected ), $name;
	if ( not $res ) {
		diag $str;
		diag "\nDoes not contain:\n\n";
		diag $expected;
	}
	return $res;
}

