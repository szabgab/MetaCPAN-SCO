use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);

plan tests => 4;

use MetaCPAN::SCO;

my $app = MetaCPAN::SCO->run;
is( ref $app, 'CODE', 'Got app' );

subtest home => sub {
	plan tests => 3;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/' )->content;
		like( $html,
			qr{<title>The CPAN Search Site - search.cpan.org</title>},
			'root route' );
		contains( $html, q{<a href="/author/">Authors</a>}, 'authors link' );
		contains( $html, q{<a href="http://log.perl.org/">News</a>},
			'news link' );    # link differs in sco
	};
};

subtest author => sub {
	plan tests => 4 + 3;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/author/' )->content;
		contains( $html, q{<br><div class="t4">Author</div><br>}, 'Author' );
		contains( $html, q{<a href="?A"> A </a>}, 'link to A' );
		contains( $html, q{<a href="?M"> M </a>}, 'link to M' );
		contains( $html, q{<a href="?Q"> Q </a>}, 'link to Q' );
	};

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/author/?Q' )->content;
		like( $html, qr{<td>\s*Q\s*</td>}, 'Q without link' );
		unlike( $html, qr{<td>Q</td>}, 'no link to Q' );
		contains(
			$html,
			q{<a href="/~qantins/"><b>QANTINS</b></a><br/><small>Marc Qantins</small>},
			'QANTINS'
		);
	};

};

subtest dist_local_tie => sub {
	plan tests => 13;

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
		contains( $html, ' git://github.com/perlancar/perl-Locale-Tie.git ',
			'github url' );
		contains( $html,
			'<a href="https://metacpan.org/release/Locale-Tie">Website</a>',
			'Website' );
		contains(
			$html,
			'<a href="lib/Locale/Tie.pm">Locale::Tie</a>',
			'link to module'
		);
		contains(
			$html,
			'<small>Get/set locale via (localizeable) variables &nbsp;</small>',
			'abstract'
		);
		contains( $html, 'META.json', 'META.json' );
		unlike $html, qr{META.yml}, 'no META.yml';
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
		diag "'$expected'";
	}
	return $res;
}

