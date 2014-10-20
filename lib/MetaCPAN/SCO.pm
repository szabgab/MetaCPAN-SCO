package MetaCPAN::SCO;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Plack::Request;
use Template;

our $VERSION = '0.01';

=head1 NAME

SCO - search.cpan.org clone

=cut

sub run {
	my $app = sub {
		my $env = shift;

		my $request = Plack::Request->new($env);
		if ($request->path_info eq '/') {
			return template('index');
		}

		return [ '404', [ 'Content-Type' => 'text/html' ], ['404 Not Found'], ];
	};
}

sub template {
	my ( $file ) = @_;

	my $root = dirname(dirname(dirname( abs_path(__FILE__) )));

	my $tt = Template->new(
		INCLUDE_PATH => "$root/tt",
		INTERPOLATE  => 0,
		POST_CHOMP   => 1,
		EVAL_PERL    => 1,
		START_TAG    => '<%',
		END_TAG      => '%>',
		PRE_PROCESS  => 'incl/header.tt',
		POST_PROCESS => 'incl/footer.tt',
	);
	my $out;
	$tt->process( "$file.tt", {}, \$out )
		|| die $tt->error();
	return [ '200', [ 'Content-Type' => 'text/html' ], [$out], ];
}


1;

