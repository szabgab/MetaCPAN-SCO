use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Test::HTML::Tidy;

use t::lib::Test;

plan tests => 13;

use MetaCPAN::SCO;

my $tidy = html_tidy();

my $app = MetaCPAN::SCO->run;
is( ref $app, 'CODE', 'Got app' );

subtest home => sub {
	plan tests => 5;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		like( $html,
			qr{<title>The CPAN Search Site - search.cpan.org</title>},
			'root route' );
		contains( $html, q{<a href="/author/">Authors</a>}, 'authors link' );
		contains( $html, q{<a href="http://log.perl.org/">News</a>},
			'news link' );    # link differs in sco
	};
};

subtest authors => sub {
	plan tests => 6 + 5;

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

subtest author => sub {
	plan tests => 11;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~szabgab/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html ) or diag $html;
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
		html_check($html);
		html_tidy_ok( $tidy, $html );
		contains( $html, q{<title>Quinn Murphy  - search.cpan.org</title>},
			'title' );

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

# Date was showing 04 Jun 2008 in the clone
# "Other Releases" was showing with an empty selector, even though there are no other releases
subtest dist_szabgab_array_unique => sub {
	plan tests => 11;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~szabgab/Array-Unique-0.08/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{Array-Unique-0.08}, 'dist-ver name' );
	TODO: {
			local $TODO = 'Some slight inacccuracy in the date';
			contains( $html, q{03 Jun 2008}, 'date' );
		}
		unlike( $html, qr{Other Releases}, 'no Other Releases' );
		unlike(
			$html,
			qr{<select name="url">\s*</select>},
			'no empty selector'
		);
		like( $html, qr{PASS \(\d+\)},    'PASS' );
		like( $html, qr{FAIL \(\d+\)},    'FAIL' );
		like( $html, qr{NA \(\d+\)},      'NA' );
		like( $html, qr{UNKNOWN \(\d+\)}, 'UNKNOWN' );
	};
};

# TODO: Other releases should not list the current release (and the swithching has not been tested yet either)
# 'Other Files' were listed on SCO
subtest dist_tlinden_apid => sub {
	plan tests => 18;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~tlinden/apid-0.04/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{apid-0.04},   'dist-ver name' );
		contains( $html, q{24 Oct 2014}, 'date' );
		contains( $html,
			q{<title>T. Linden / apid-0.04 - search.cpan.org</title>},
			'title' );
		unlike( $html, qr{Website}, 'No Website' );
		unlike( $html, qr{<a href="">Website</a>}, 'No empty website link' );
		unlike( $html, qr{<h2 class="t2">Modules</h2>}, 'No Modules' );
		unlike(
			$html,
			qr{<option value="/~tlinden/apid-0.04/">},
			'exclude current distro from other releases'
		);
		contains(
			$html,
			q{<option value="/~tlinden/apid-0.03/">},
			'other releases'
		);
		contains(
			$html,
			q{<option value="/~tlinden/apid-0.02/">},
			'other releases'
		);
		contains( $html,
			q{<a href="/src/TLINDEN/apid-0.04/Changelog">Changelog</a>},
			'Changelog' );
		contains( $html,
			q{<a href="/src/TLINDEN/apid-0.04/INSTALL">INSTALL</a>},
			'INSTALL' );
		contains( $html, q{<h2 class="t2">Other Files</h2>}, 'Other Files' );
		contains( $html,
			q{<a href="/src/TLINDEN/apid-0.04/README.md">README.md</a>},
			'README.md' );
		contains(
			$html,
			q{<a href="/src/TLINDEN/apid-0.04/sample/README">sample/README</a>},
			'sample/README'
		);
		contains(
			$html,
			q{<a href="/src/TLINDEN/apid-0.04/sample/index.html">sample/index.html</a>},
			'sample/index.html'
		);
	};
};

subtest dist_perlancar_local_tie => sub {
	plan tests => 15;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~perlancar/Locale-Tie-0.03/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
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
			q{<a href="http://dev.perl.org/licenses/">The Perl 5 License (Artistic 1 &amp; GPL 1)</a>},
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

subtest dist_szabgab_text_mediawiki => sub {
	plan tests => 13;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~szabgab/Text-MediawikiFormat-1.01/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;

	TODO: {
			local $TODO = 'UNAUTHORIZED release not makred yet';
			contains( $html,
				q{<font color=red><b>** UNAUTHORIZED RELEASE **</b></font>},
				'UNAUTHORIZED' );
		}
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

subtest dist_ddumont_text_mediawiki => sub {
	plan tests => 13;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~ddumont/Config-Model-Itself-1.241/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
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
		contains( $html,
			q{<a href="config-model-edit">config-model-edit</a>} );
		contains( $html,
			q{<a href="http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt">The GNU Lesser General Public License, Version 2.1, February 1999</a>}
		);
	};
};

subtest dist_wonko_html_template => sub {
	plan tests => 10;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~wonko/HTML-Template-2.95/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{<a href="lib/HTML/Template.pm">HTML::Template</a>} );
		contains( $html,
			q{<a href="lib/HTML/Template/FAQ.pm">HTML::Template::FAQ</a>} );
		unlike( $html, qr{Documentation} );
		unlike( $html,
			qr{<a href="t/testlib/IO/Capture.pm">IO::Capture</a>} );
		unlike( $html, qr{<a href="t/testlib/_Auxiliary.pm">_Auxiliary</a>} );
		unlike( $html, qr{Other Files} );
		unlike( $html, qr{bench/new\.pl} );
	};
};

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
# TODO: http://localhost:5000/~babkin/triceps-2.0.0/  (missing Other releases, CPAN Testers, missing bug count, date is incorrect, missing other files)

subtest manifest => sub {
	plan tests => 7;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~szabgab/Array-Unique-0.08/MANIFEST' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{<a href="/src/SZABGAB/Array-Unique-0.08/MANIFEST">Source</a>},
			'source' );
		contains(
			$html,
			q{<a href="/src/SZABGAB/Array-Unique-0.08/MANIFEST">MANIFEST</a>},
			'MANIFEST'
		);
		contains(
			$html,
			q{<a href="/src/SZABGAB/Array-Unique-0.08/lib/Array/Unique.pm">lib/Array/Unique.pm</a>},
			'src lib/Array/Unique.pm'
		);
		contains( $html, q{[<a href="lib/Array/Unique.pm">pod</a>]}, 'pod' );
	};

};

# TODO: http://search.cpan.org/~szabgab/Array-Unique-0.08/lib/Array/Unique.pm
# TODO: http://search.cpan.org/dist/Array-Unique/
# TODO: http://search.cpan.org/dist/Array-Unique/lib/Array/Unique.pm
# TODO: search!

#subtest dist_array_unique => sub {
#	plan tests => 11;
#
#	test_psgi $app, sub {
#		my $cb   = shift;
#		my $html = $cb->( GET '/dist/Array-Unique/' )->content;
#		html_check($html);
#		html_tidy_ok( $tidy, $html );
#		unlike $html, qr/ARRAY/;
#		contains( $html, q{Array-Unique-0.08}, 'dist-ver name' );
#	TODO: {
#			local $TODO = 'Some slight inacccuracy in the date';
#			contains( $html, q{03 Jun 2008}, 'date' );
#		}
#		unlike( $html, qr{Other Releases}, 'no Other Releases' );
#		unlike(
#			$html,
#			qr{<select name="url">\s*</select>},
#			'no empty selector'
#		);
#		like( $html, qr{PASS \(\d+\)},    'PASS' );
#		like( $html, qr{FAIL \(\d+\)},    'FAIL' );
#		like( $html, qr{NA \(\d+\)},      'NA' );
#		like( $html, qr{UNKNOWN \(\d+\)}, 'UNKNOWN' );
#	};
#};

subtest dist_html_template => sub {
	plan tests => 10;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/dist/HTML-Template/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html,
			q{<a href="lib/HTML/Template.pm">HTML::Template</a>} );
		contains( $html,
			q{<a href="lib/HTML/Template/FAQ.pm">HTML::Template::FAQ</a>} );
		unlike( $html, qr{Documentation} );
		unlike( $html,
			qr{<a href="t/testlib/IO/Capture.pm">IO::Capture</a>} );
		unlike( $html, qr{<a href="t/testlib/_Auxiliary.pm">_Auxiliary</a>} );
		unlike( $html, qr{Other Files} );
		unlike( $html, qr{bench/new\.pl} );
	};
};

