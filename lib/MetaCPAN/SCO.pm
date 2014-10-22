package MetaCPAN::SCO;
use strict;
use warnings;

use Carp ();
use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use JSON qw(from_json);
use LWP::Simple qw(get);
use Path::Tiny qw(path);
use Plack::Builder;
use Plack::Response;
use Plack::Request;
use Template;

our $VERSION = '0.01';

=head1 NAME

SCO - search.cpan.org clone

=cut

my $env;

sub run {
	my $root = root();

	my $app = sub {
		$env = shift;

		my $request = Plack::Request->new($env);
		my $path_info = $request->path_info;
		if ($path_info eq '/') {
			return template('index', {front => 1});
		}
		if ($path_info eq '/feedback') {
			return template('feedback');
		}
		if ($path_info =~ m{^/author/?$}) {
			my $query_string = $request->query_string;
			return template('authors', { letters => ['A' .. 'Z'], authors => [] }) if not $query_string;
			my $lead = substr $query_string, 0, 1;
			my $authors = authors_starting_by(uc $lead);
			if (@$authors) {
				return template('authors', {letters => ['A' .. 'Z'], authors => $authors, selected_letter => uc $lead});
			}
		}

		if ($path_info =~ m{^/~([a-z]+)$}) {
			my $res = Plack::Response->new();
			$res->redirect("$path_info/", 301);
			return $res->finalize;
		}
		if ($path_info =~ m{^/~([a-z]+)/$}) {
			my $pauseid = uc $1;
			my $author = get_author_info($pauseid);
			$author->{cpantester} = substr($pauseid, 0, 1) . '/' . $pauseid;
			my $distros = get_distros_by_pauseid($pauseid);
			return template('author', { author => $author, distributions => $distros });
		}

		if ($path_info =~ m{^/dist/([^/]+)/$}) {
			my $dist_name = $1;
		}

		if ($path_info =~ m{^/~([a-z]+)/([^/]+)/$}) {
			my $pauseid = uc $1;
			my $dist_name_ver = $2;
			
			# curl 'http://api.metacpan.org/v0/release/AADLER/Games-LogicPuzzle-0.20'
			# curl 'http://api.metacpan.org/v0/release/Games-LogicPuzzle'
			# from https://github.com/CPAN-API/cpan-api/wiki/API-docs
			my $dist;
			my $release;
			eval {
				my $json = get 'http://api.metacpan.org/v0/release/' . $pauseid . '/' . $dist_name_ver;
				$dist = from_json $json;
				1;
			} or do {
				my $err = $@  // 'Unknown error';
				warn $err if $err;
			};
			$dist->{this_name} = $dist->{name};
			my $author = get_author_info($pauseid);

			return template('dist', { dist => $dist, author => $author });
		}

		if ($path_info eq '/search') {
			return search($request->param('query'), $request->param('mode'));
		}


		my $reply = template('404');
		return [ '404', [ 'Content-Type' => 'text/html' ], $reply->[2], ];
	};

	builder {
		enable 'Plack::Middleware::Static',
			path => qr{^/(favicon.ico|robots.txt)},
			root => "$root/static/";
		$app;
	};
}

sub search {
	my ($query, $mode) = @_;
	
	if ($mode eq 'author') {
		my @authors = [];
		eval {
			my $json = get "http://api.metacpan.org/v0/author/_search?q=author.name:*$query*&size=5000&fields=name";
			my $data = from_json $json;
			@authors =
				sort { $a->{id} cmp $b->{id} }
				map { { id => $_->{_id}, name => $_->{fields}{name} } } @{ $data->{hits}{hits} };
			1;
		} or do {
			my $err = $@  // 'Unknown error';
			warn $err if $err;
		};
		return template('authors', {letters => ['A' .. 'Z'], authors => \@authors, selected_letter => 'X'});
	}
}

sub get_distros_by_pauseid {
	my ($pause_id) = @_;
	# curl 'http://api.metacpan.org/v0/release/_search?q=author:SZABGAB&size=500'
	# TODO the status:latest filter should be on the query not in the grep

	my @data;
	eval {
		my $json = get 'http://api.metacpan.org/v0/release/_search?q=author:' . $pause_id . '&size=500';
		my $raw = from_json $json;
		@data =
			sort { $a->{name} cmp $b->{name} }
			map { {
			name         => $_->{_source}{name},
			abstract     => $_->{_source}{abstract},
			date         => $_->{_source}{date},
			download_url => $_->{_source}{download_url},
			} }
			grep { $_->{_source}{status} eq 'latest' }
			@{ $raw->{hits}{hits} };
		1;
	} or do {
		my $err = $@  // 'Unknown error';
		warn $err if $err;
	};
	return \@data;
}

sub get_author_info {
	my ($pause_id) = @_;
	my $data;
	eval {
		my $json = get 'http://api.metacpan.org/v0/author/_search?q=author._id:' . $pause_id . '&size=1';
		my $raw = from_json $json;
		$data = $raw->{hits}{hits}[0]{_source};
		1;
	} or do {
		my $err = $@  // 'Unknown error';
		warn $err if $err;
	};
	return $data
}

sub authors_starting_by {
	my ($char) = @_;
	# curl http://api.metacpan.org/v0/author/_search?size=10
	# curl 'http://api.metacpan.org/v0/author/_search?q=author._id:S*&size=10'
	# curl 'http://api.metacpan.org/v0/author/_search?size=10&fields=name'
	# curl 'http://api.metacpan.org/v0/author/_search?q=author._id:S*&size=10&fields=name'
	# or maybe use fetch to download and keep the full list locally:
	# http://api.metacpan.org/v0/author/_search?pretty=true&q=*&size=100000 (from https://github.com/CPAN-API/cpan-api/wiki/API-docs )

	my @authors = [];
	if ($char =~ /[A-Z]/) {
		eval {
			my $json = get "http://api.metacpan.org/v0/author/_search?q=author._id:$char*&size=5000&fields=name";
			my $data = from_json $json;
			@authors =
				sort { $a->{id} cmp $b->{id} }
				map { { id => $_->{_id}, name => $_->{fields}{name} } } @{ $data->{hits}{hits} };
			1;
		} or do {
			my $err = $@  // 'Unknown error';
			warn $err if $err;
		};
	}
	return \@authors;
}


sub template {
	my ( $file, $vars ) = @_;
	$vars //= {};
	Carp::confess 'Need to pass HASH-ref to template()'
		if ref $vars ne 'HASH';

	my $root = root();

	my $ga_file = "$root/config/google_analytics.txt";
	if ( -e $ga_file ) {
		$vars->{google_analytics} = path($ga_file)->slurp_utf8  // '';
	}

	eval {
		$vars->{totals} = from_json path("$root/totals.json")->slurp_utf8;
	};

	my $request = Plack::Request->new($env);
	$vars->{query} = $request->param('query');
	$vars->{mode}  = $request->param('mode');

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
	$tt->process( "$file.tt", $vars, \$out )
		|| die $tt->error();
	return [ '200', [ 'Content-Type' => 'text/html' ], [$out], ];
}

sub root {
	my $dir = dirname(dirname(dirname( abs_path(__FILE__) )));
	$dir =~ s{blib/?$}{};
	return $dir;
}

1;

