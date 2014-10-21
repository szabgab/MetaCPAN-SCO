use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
	NAME         => 'MetaCPAN::SCO',
	AUTHOR       => 'Gabor Szabo <szabgab@cpan.org>',
	VERSION_FROM => 'lib/MetaCPAN/SCO.pm',
	PREREQ_PM    => {
		'Cwd'              => '0',
		'File::Basename'   => '0',
		'Plack::Request'   => '0',
		'Template'         => '0',
        'LWP::Simple'      => '0',
        'JSON'             => '0',
        'Path::Tiny'       => '0',
	},
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$conf{LICENSE} = 'perl';
}


if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type       => 'git',
				url        => 'http://github.com/szabgab/MetaCPAN-SCO.git',
				web        => 'http://github.com/szabgab/MetaCPAN-SCO',
				license    => 'http://dev.perl.org/licenses/',
			},
			bugtracker => {
				web        => 'http://github.com/szabgab/MetaCPAN-SCO/issues',
			},
			homepage   => 'http://perlmaven.com/',
		},
	};
}

my %configure_requires = (
	'ExtUtils::MakeMaker' => '6.64',
);
my %build_requires = ();
my %test_requires = (
	'Test::More'           => '1.00',
	'Test::WWW::Mechanize' => '0',
);

###   merging data "standard code"
if (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
	$conf{CONFIGURE_REQUIRES} = \%configure_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %configure_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
	$conf{BUILD_REQUIRES} = \%build_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %build_requires);
}
if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}


WriteMakefile(%conf);

