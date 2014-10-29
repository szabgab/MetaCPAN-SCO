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

subtest author => sub {
	plan tests => 10;

	test_psgi $app, sub {
		my $cb   = shift;
		my $html = $cb->( GET '/~szabgab/' )->content;
		html_check($html);
		html_tidy_ok( $tidy, $html ) or diag $html;
		contains(
			$html,
			q{<a href="CPAN-Test-Dummy-SCO-Pirated-1.03/">CPAN-Test-Dummy-SCO-Pirated-1.03</a>},
			'link to release'
		);
		contains(
			$html,
			q{package to test the SCO clone},
			'abstract of a distribution'
		);

# Original in search.cpan.org was:
#q{<a href="/CPAN/authors/id/S/SZ/SZABGAB/CPAN-Test-Dummy-SCO-Pirated-1.03.tar.gz">Download</a>},
# The https here is the new ways of serving downloads. see https://github.com/CPAN-API/cpan-api/issues/355
# but old download links will have http://
		contains(
			$html,
			q{<a href="https://cpan.metacpan.org/authors/id/S/SZ/SZABGAB/CPAN-Test-Dummy-SCO-Pirated-1.03.tar.gz">Download</a>},
			'download link'
		);
		contains( $html, q{27 Oct 2014},
			'release date of CPAN-Test-Dummy-SCO-Pirated-1.03' );
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Pirated-1.03/">Browse</a>},
			'link to source'
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
};

subtest author => sub {
	plan tests => 5;

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

