use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Test::HTML::Tidy;

use t::lib::Test;

plan tests => 8;

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

# Date was showing 04 Jun 2008 in the clone
# "Other Releases" was showing with an empty selector, even though there are no other releases
subtest dist_szabgab_array_unique => sub {
	plan tests => 6;

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
		like( $html, qr{NA \(\d+\)}, 'NA' );
	};
};

# TODO: Other releases should not list the current release
# 'Other Files' were listed on SCO
# this was removed from CPAN
#subtest dist_tlinden_apid => sub {
#	plan tests => 7;
#
#	test_psgi $app, sub {
#		my $cb   = shift;
#		my $html = $cb->( GET '/~tlinden/apid-0.04/' )->content;
#		html_check($html);
#		html_tidy_ok( $tidy, $html );
#		unlike $html, qr/ARRAY/;
#		contains( $html, q{apid-0.04},   'dist-ver name' );
#		contains( $html, q{24 Oct 2014}, 'date' );
#		contains( $html,
#			q{<title>T. Linden / apid-0.04 - search.cpan.org</title>},
#			'title' );
#		unlike( $html, qr{<h2 class="t2">Modules</h2>}, 'No Modules' );
#		}
#};

subtest dist_cpan_test_dummy_sco_lacks => sub {
	my @specials = qw(
		Makefile.PL META.yml
	);

	plan tests => 10 + @specials;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~szabgab/CPAN-Test-Dummy-SCO-Lacks-0.01/' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<small>28 Oct 2014</small>}, 'date' );

		contains(
			$html,
			' git://github.com/szabgab/CPAN-Test-Dummy-SCO.git ',
			'github url but not a link'
		);
		contains( $html, q{<a href="MANIFEST">MANIFEST</a>}, 'MANIFEST' );
		foreach my $f (@specials) {
			contains( $html,
				qq{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Lacks-0.01/$f">$f</a><br>}
			);
		}
		unlike $html, qr{META.json}, 'No META.json in this distro';
		contains( $html, 'Unknown', 'no license' );

		unlike( $html, qr{Website}, 'No Website' );
		unlike( $html, qr{<a href="">Website</a>}, 'No empty website link' );

	};
};

subtest dist_cpan_test_dummy_sco_pirated => sub {
	plan tests => 8;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '/~szabgab/CPAN-Test-Dummy-SCO-Pirated-1.03/' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<small>27 Oct 2014</small>}, 'date' );

		unlike( $html, qr{Other Releases}, 'no Other Releases' );
		unlike(
			$html,
			qr{<select name="url">\s*</select>},
			'no empty selector'
		);

		contains( $html,
			q{<font color="red"><b>** UNAUTHORIZED RELEASE **</b></font>},
			'UNAUTHORIZED' );
		contains( $html,
			q{<td><font color="red"><b>UNAUTHORIZED</b></font></td>},
			'UNAUTHORIZED' )

	};
};

subtest dist_cpan_test_dummy_sco_special => sub {
	my @specials = qw(
		ARTISTIC
		Changelog
		Changes
		COPYING
		INSTALL
		LICENSE
		Makefile.PL
		Build.PL
		META.json
		README
		SIGNATURE
	);
	plan tests => 35 + @specials;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<small>28 Oct 2014</small>}, 'date' );
		contains( $html, q{<a href="http://perlmaven.com/">Website</a>},
			'website 1' );
		contains(
			$html,
			q{<a href="http://github.com/szabgab/CPAN-Test-Dummy-SCO">Website</a>},
			'Git website'
		);

#TODO: contains($html, q{<a href="http://github.com/szabgab/CPAN-Test-Dummy-SCO.git">http://github.com/szabgab/CPAN-Test-Dummy-SCO.git</a>}, 'Github link');
		like( $html, qr{UNKNOWN \(\d+\)}, 'UNKNOWN' );

		unlike( $html, qr{Latest Release}, 'no Latest Release' );
		unlike(
			$html,
			qr{<a href="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/">CPAN-Test-Dummy-SCO-Special-0.04</a>},
			'no latest release link'
		);

		foreach my $f (@specials) {
			contains( $html,
				qq{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/$f">$f</a><br>}
			);
		}
		contains( $html, q{<a href="MANIFEST">MANIFEST</a>}, 'MANIFEST' );
		unlike( $html, qr{SomeOther}, 'SomeOther.txt is not listed' );
		contains(
			$html,
			q{<a href="http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt">The GNU Lesser General Public License, Version 2.1, February 1999</a>},
			'license'
		);

		contains(
			$html,
			q{<div id="permalink" class="noprint"><a href="/dist/CPAN-Test-Dummy-SCO-Special/">permalink</a></div>},
			'permalink'
		);

		contains( $html, q{<h2 class="t2">Modules</h2>}, 'Modules' );
		contains(
			$html,
			q{<a href="lib/CPAN/Test/Dummy/SCO/Special.pm">CPAN::Test::Dummy::SCO::Special</a>},
			'link to module'
		);
		contains(
			$html,
			q{CPAN::Test::Dummy::SCO::Nodoc},
			'name of pm file without pod'
		);
		unlike(
			$html,
			qr{<a href="lib/CPAN/Test/Dummy/SCO/Nodoc.pm">CPAN::Test::Dummy::SCO::Nodoc</a>},
			'no link to module without pod'
		);
		contains( $html,
			'<small>package to test the SCO clone &nbsp;</small>',
			'abstract' );

		contains( $html, q{Other Releases}, 'Other Releases' );
		contains(
			$html,
			q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.01/">CPAN-Test-Dummy-SCO-Special-0.01&nbsp;&nbsp;--&nbsp;&nbsp;27 Oct 2014</option>},
			'link to other'
		);
		contains(
			$html,
			q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/">CPAN-Test-Dummy-SCO-Special-0.02&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
			'link to other'
		);
		contains(
			$html,
			q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.03/">CPAN-Test-Dummy-SCO-Special-0.03&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
			'link to other'
		);
		unlike(
			$html,
			qr{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/">CPAN-Test-Dummy-SCO-Special-0.04&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
			'exclude current release from other releases'
		);

		contains( $html, q{<h2 class="t2">Other Files</h2>}, 'Other Files' );
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/README.md">README.md</a>},
			'README.md'
		);
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/sample/README">sample/README</a>},
			'sample/README'
		);
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.04/sample/index.html">sample/index.html</a>},
			'sample/index.html'
		);
		unlike $html, qr{META.yml},
			'if there is META.json then META.yml is hidden';

		contains(
			$html,
			q{<a href="lib/CPAN/Test/Dummy/SCO/Onlydoc.pod">CPAN::Test::Dummy::SCO::Onlydoc</a>},
			'.pod file'
		);
		contains( $html, q{only documentation, no module},
			'abstract of pod' );
		contains(
			$html,
			q{<a href="cpan-test-dummy-sco-special">cpan-test-dummy-sco-special</a>},
			'documentation in script'
		);
		contains( $html, q{command line tool}, 'abstract from script' );
		contains( $html, q{<h2 class="t2">Documentation</h2>},
			'documentation' );

		unlike( $html, qr{ps\.conf} );
		unlike( $html, qr{ps\.map} );
	};

};

subtest dist_cpan_test_dummy_sco_special_0_03 => sub {
	plan tests => 11;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '~szabgab/CPAN-Test-Dummy-SCO-Special-0.03/' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<small>28 Oct 2014</small>}, 'date' );

		contains(
			$html,
			q{<a href="http://dev.perl.org/licenses/">The Perl 5 License (Artistic 1 &amp; GPL 1)</a>},
		);

		contains(
			$html,
			q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.01/">CPAN-Test-Dummy-SCO-Special-0.01&nbsp;&nbsp;--&nbsp;&nbsp;27 Oct 2014</option>},
			'link to other'
		);
		contains(
			$html,
			q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/">CPAN-Test-Dummy-SCO-Special-0.02&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
			'link to other'
		);
		unlike(
			$html,
			qr{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.03/">CPAN-Test-Dummy-SCO-Special-0.03&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
			'link to other'
		);

		unlike( $html, qr{Documentation} );

		contains( $html, q{Latest Release}, 'Latest Release' );
		contains(
			$html,
			q{<a href="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/">CPAN-Test-Dummy-SCO-Special-0.04</a>},
			'no latest release link'
		);

# TODO search.cpan.org only shows the older releases so the next test should not pass
# but I think it should show both the older and newer releases
#contains(
#	$html,
#	q{<option value="/~szabgab/CPAN-Test-Dummy-SCO-Special-0.04/">CPAN-Test-Dummy-SCO-Special-0.04&nbsp;&nbsp;--&nbsp;&nbsp;28 Oct 2014</option>},
#	'exclude current release from other releases'
#);
	};
};

# TODO: http://localhost:5000/~babkin/triceps-2.0.0/  (missing Other releases, CPAN Testers, missing bug count, date is incorrect, missing other files)
# TODO: http://search.cpan.org/~szabgab/Array-Unique-0.08/lib/Array/Unique.pm
# TODO: http://search.cpan.org/dist/Array-Unique/
# TODO: http://search.cpan.org/dist/Array-Unique/lib/Array/Unique.pm
# TODO: search!

subtest dist_cpan_test_dummy_sco_special_0_02 => sub {
	plan tests => 6;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET '~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/' )
			->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains( $html, q{<small>28 Oct 2014</small>}, 'date' );
		like( $html, qr{PASS \(\d+\)}, 'PASS' );
		like( $html, qr{FAIL \(\d+\)}, 'FAIL' );
	};
};

