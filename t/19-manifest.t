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

subtest manifest => sub {
	plan tests => 13;

	test_psgi $app, sub {
		my $cb = shift;
		my $html
			= $cb->( GET
				'http://localhost:5000/~szabgab/CPAN-Test-Dummy-SCO-Special-0.02/MANIFEST'
			)->content;
		html_check($html);
		html_tidy_ok( $tidy, $html );
		unlike $html, qr/ARRAY/;
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/MANIFEST">Source</a>},
			'source'
		);
		contains(
			$html,
			q{Latest&nbsp;Release:&nbsp;<a href="/~szabgab/CPAN-Test-Dummy-SCO-Special/MANIFEST">CPAN-Test-Dummy-SCO-Special-0.04</a>},
			'link to latest'
		);

# TODO minor issue: check and implement that when viewing the MANIFEST of the lates, there is no link to the latest.

		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/MANIFEST">MANIFEST</a>},
			'MANIFEST'
		);
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/lib/CPAN/Test/Dummy/SCO/Special.pm">lib/CPAN/Test/Dummy/SCO/Special.pm</a>},
			'src of lib/CPAN/Test/Dummy/SCO/Special.pm'
		);
		contains( $html,
			q{[<a href="lib/CPAN/Test/Dummy/SCO/Special.pm">pod</a>]},
			'pod' );
		contains(
			$html,
			q{<a href="/src/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/lib/CPAN/Test/Dummy/SCO/Nodoc.pm">lib/CPAN/Test/Dummy/SCO/Nodoc.pm</a>},
			'src of lib/CPAN/Test/Dummy/SCO/Nodoc.pm'
		);

		unlike( $html, qr{<a href="lib/CPAN/Test/Dummy/SCO/Nodoc.pm">pod</a>},
			'no pod link' );

		contains( $html, q{Download:}, 'Download:' );

		contains(
			$html,
			q{<a href="https://cpan.metacpan.org/authors/id/S/SZ/SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02.tar.gz">CPAN-Test-Dummy-SCO-Special-0.02.tar.gz</a>},
			'download link'
		);
		contains(
			$html,
			q{<a href="http://www.annocpan.org/~SZABGAB/CPAN-Test-Dummy-SCO-Special-0.02/MANIFEST">Annotate this POD</a>},
			'link to annocpan'
		);

	};

};

