use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);

plan tests => 7;

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

subtest authors => sub {
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

subtest author => sub {
	plan tests => 6;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~szabgab/' )->content;
		contains(
			$html,
			q{<a href="Dwimmer-0.32/">Dwimmer-0.32</a>},
			'link to a release'
		);
		contains(
			$html,
			q{<a href="http://backpan.perl.org/authors/id/S/SZ/SZABGAB/">Archive</a>},
			'backpan'
		);

# the differences between the data found in 00whois.xml and what MetaCPAN provides
#contains( $html, q{<a href="mailto:gabor%40pti.co.il">gabor@pti.co.il</a>}, 'e-mail' );
#contains( $html, q{<a href="http://szabgab.com/" rel="me">http://szabgab.com/</a>}, 'Homepage');
		contains( $html,
			q{<a href="mailto:szabgab@gmail.com">szabgab@gmail.com</a>} );
		contains( $html,
			q{<a href="http://perlmaven.com/" rel="me">http://perlmaven.com/</a>}
		);
	};

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~quinnm/' )->content;

# difference between sco and the clone
#contains( $html, q{<a href="mailto:CENSORED">CENSORED</a>}, 'censored e-mail' );
#contains( $html, q{<a href="http://quinnmurphy.net" rel="me">http://quinnmurphy.net</a>}, 'Homepage');
		contains( $html,
			q{<a href="mailto:quinnm@cpan.org">quinnm@cpan.org</a>}, '' );
		contains(
			$html,
			q{<a href="http://quinnmurphy.net/" rel="me">http://quinnmurphy.net/</a>},
			'Homepage'
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

subtest dist_text_mediawiki => sub {
	plan tests => 10;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~szabgab/Text-MediawikiFormat-1.01/' )->content;
		unlike $html, qr/ARRAY/;

# TODO
#contains( $html, q{<font color=red><b>** UNAUTHORIZED RELEASE **</b></font>}, 'UNAUTHORIZED' );
		contains( $html, q{<small>14 Sep 2014</small>}, 'date' );
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/ARTISTIC">ARTISTIC</a><br>}
		);
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/Build.PL">Build.PL</a><br>}
		);
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/Changes">Changes</a><br>}
		);
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/Makefile.PL">Makefile.PL</a><br>}
		);
		contains( $html, q{<a href="MANIFEST">MANIFEST</a><br>} );
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/META.json">META.json</a><br>}
		);
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/README">README</a><br>}
		);
		contains( $html,
			q{<a href="/src/SZABGAB/Text-MediawikiFormat-1.01/SIGNATURE">SIGNATURE</a><br>}
		);
	};

};

subtest dist_text_mediawiki => sub {
	plan tests => 9;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~ddumont/Config-Model-Itself-1.241/' )->content;
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{<a href="/src/DDUMONT/Config-Model-Itself-1.241/LICENSE">LICENSE</a><br>}
		);
		contains( $html,
			q{<a href="lib/Config/Model/Itself.pm">Config::Model::Itself</a>}
		);
		contains( $html,
			q{<a href="lib/Config/Model/Itself/BackendDetector.pm">Config::Model::Itself::BackendDetector</a>}
		);
		contains( $html, q{Config::Model::Itself::TkEditUI} );
		unlike( $html, qr{\QConfig/Model/Itself/TkEditUI}, 'no link' );

		contains( $html, q{<h2 class="t2">Modules</h2>}, 'Modules' );
		contains( $html, q{<h2 class="t2">Documentation</h2>},
			'documentation' );
		contains(
			$html,
			q{<a href="lib/Config/Model/models/Itself/Class.pod">Config::Model::models::Itself::Class</a>},
			'link to pod'
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
		diag "'$expected'";
	}
	return $res;
}

