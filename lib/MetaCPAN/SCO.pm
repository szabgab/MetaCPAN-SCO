package MetaCPAN::SCO;
use strict;
use warnings;

use Carp ();
use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use HTTP::Tiny;
use JSON qw(from_json to_json);
use LWP::Simple qw(get);
use Path::Tiny qw(path);
use Plack::Builder;
use Plack::Response;
use Plack::Request;
use Pod::Simple::HTML;
use POSIX qw(strftime);
use Template;
use Time::Local qw(timegm);

our $VERSION = '0.01';

=head1 NAME

SCO - search.cpan.org clone

=cut

my $env;

sub run {
	my $root = root();

	my $app = sub {
		$env = shift;

		my $request   = Plack::Request->new($env);
		my $path_info = $request->path_info;
		if ( $path_info eq '/' ) {
			return template(
				'index',
				{
					front => 1,
					title => 'The CPAN Search Site - search.cpan.org',
				}
			);
		}
		if ( $path_info eq '/feedback' ) {
			return template( 'feedback',
				{ title => 'Site Feedback - search.cpan.org', } );
		}
		if ( $path_info eq '/faq.html' ) {
			return template( 'faq', { title => 'FAQ - search.cpan.org', } );
		}
		if ( $path_info eq '/recent' ) {
			my $recent = recent( $request->param('d') );
			return template( 'recent', { recent => $recent } );
		}
		if ( $path_info =~ m{^/author/?$} ) {
			my $query_string = $request->query_string;
			return template(
				'authors',
				{
					letters => [ 'A' .. 'Z' ],
					authors => [],
					title   => 'The CPAN Search Site - search.cpan.org',
				}
			) if not $query_string;
			my $lead = substr $query_string, 0, 1;
			my $authors = authors_starting_by( uc $lead );
			if (@$authors) {
				return template(
					'authors',
					{
						letters         => [ 'A' .. 'Z' ],
						authors         => $authors,
						selected_letter => uc($lead),
						title => 'The CPAN Search Site - search.cpan.org',
					}
				);
			}
		}

		if ( $path_info =~ m{^/~([a-z]+)$} ) {
			my $res = Plack::Response->new();
			$res->redirect( "$path_info/", 301 );
			return $res->finalize;
		}
		if ( $path_info =~ m{^/~([a-z]+)/$} ) {
			my $pauseid = uc $1;
			my $author  = get_author_info($pauseid);
			$author->{cpantester} = substr( $pauseid, 0, 1 ) . '/' . $pauseid;
			my $distros = get_distros_by_pauseid($pauseid);
			return template(
				'author',
				{
					author        => $author,
					distributions => $distros,
					title         => "$author->{name}  - search.cpan.org",
				}
			);
		}

		# ~ealleniii/Config-Options-0.08/
		if ( $path_info =~ m{^/~([a-z]+)/([^/]+)/(.*)?$} ) {
			my ( $pauseid, $dist_name, $file ) = ( uc($1), $2, $3 );
			if ( not $file ) {
				my $data = get_dist_data( $pauseid, $dist_name );

				#die Dumper $data;

				return template( 'dist', $data );
			}

			if ( $file eq 'MANIFEST' ) {
				my $manifest = get
					"http://api.metacpan.org/source/$pauseid/$dist_name/$file";
				my @rows = split /\r?\n/, $manifest;
				my @entries;
				foreach my $row (@rows) {
					next if $row =~ /^\s*$/;
					$row =~ s/^\s+|\s+$//g;
					my ( $file, $text ) = split /\s+/, $row, 2;
					my %e = (
						file => $file,
						text => $text,
					);
					if ( $file =~ /\.(pod|pm)$/ ) {
						$e{pod} = $file;
					}
					push @entries, \%e;
				}
				my $author = get_author_info($pauseid);
				return template(
					'manifest',
					{
						manifest  => \@entries,
						pauseid   => $pauseid,
						dist_name => $dist_name,
						author    => $author,
						username  => lc($pauseid)
					}
				);
			}

			if ( $file =~ /\.(pod|pm)$/ ) {
				my $source = get
					"http://api.metacpan.org/source/$pauseid/$dist_name/$file";

				my $p = Pod::Simple::HTML->new;
				$p->output_string( \my $pod );
				$p->index(1);
				$p->html_header_before_title('');
				$p->html_header_after_title('');
				$p->html_footer('');
				$p->parse_string_document($source);

		   # fetch info about the distribution to show on the right-hand side.

				return template( 'pod', { pod => $pod } );
			}

		}

		if ( $path_info =~ m{^/dist/([^/]+)$} ) {
			my $res = Plack::Response->new();
			$res->redirect( "$path_info/", 301 );
			return $res->finalize;
		}

		if ( $path_info =~ m{^/dist/([^/]+)/$} ) {
			my $dist_name      = $1;
			my $latest_release = get_latest_release($dist_name);
			my $data           = get_dist_data( $latest_release->{author},
				$latest_release->{name} );
			return template( 'dist', $data );
		}

		#if ($path_info =~ m{^/src/([^/]+)/([^/]+)/(.*)}) {
		if ( $path_info =~ m{^/src/(.*)} ) {
			my $res = Plack::Response->new();

	#http://api.metacpan.org/source/DDUMONT/Config-Model-Itself-1.241/Build.PL

# meta information about a file:
# http://api.metacpan.org/v0/file/_search?q=path:Build.PL%20AND%20release:Config-Model-Itself-1.241&size=1
			$res->redirect( "http://api.metacpan.org/source/$1", 301 );
			return $res->finalize;
		}

		if ( $path_info eq '/search' ) {

# I found out that the pager on sco uses the paramters q,m,s,n
# and there is actually a strange issue. The pager links on the search result page show numbers 1,2,3,4 (the page numbers)
# but the links underneath use s=<the number of the first hit on that page>
# the user can supply other values to s=, not only the onese that are the starting points of "real" pages. for example s=13
# In that case the new page will show the correct number of results starting from result #13 but the links will stull say
# pages 1,2,3 ...
# It might be better to just use p= page number to send to the server
			my $query = $request->param('query') || $request->param('q');
			my $mode  = $request->param('mode')  || $request->param('m');

			#my $start = $request->param('s') || 1;
			my $page = $request->param('p') || 1;
			my $size = $request->param('n') || 10;
			return search( $query, $mode, $page, $size );
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

sub get_latest_release {
	my ($dist_name) = @_;
	return get_api("http://api.metacpan.org/v0/release/$dist_name");
}

sub get_releases {
	my ($dist_name) = @_;
	return reverse sort { $a->{date} cmp $b->{date} }
		grep            { $_->{status} eq 'cpan' }
		get_api_fields(
		"http://api.metacpan.org/v0/release/_search?q=distribution:$dist_name&size=30&fields=author,name,date,status,abstract"
		);
}

sub get_files {
	my ($dist_name_ver) = @_;
	return get_api_fields(
		"http://api.metacpan.org/v0/file/_search?q=release:$dist_name_ver&size=1000&fields=release,path,module.name,abstract,module.version,documentation,directory"
	);
}

sub get_ratings {
	my ($distribution) = @_;
	return get_api_fields(
		"http://api.metacpan.org/v0/rating/_search?q=distribution:$distribution&size=1000&fields=rating"
	);
}

sub get_api_fields {
	my ($url) = @_;
	my $data = get_api($url);
	return map { $_->{fields} } @{ $data->{hits}{hits} };
}

sub get_api {
	my ($url) = @_;

	my $data;
	eval {
		my $json = get $url;
		$data = from_json $json;
		1;
	} or do {
		my $err = $@ // 'Unknown error';
		warn $err if $err;
	};
	return $data;
}

sub get_dist_data {
	my ( $pauseid, $dist_name_ver ) = @_;

	# curl 'http://api.metacpan.org/v0/release/AADLER/Games-LogicPuzzle-0.20'
	# curl 'http://api.metacpan.org/v0/release/Games-LogicPuzzle'
	# from https://github.com/CPAN-API/cpan-api/wiki/API-docs
	my $dist = get_api(
		"http://api.metacpan.org/v0/release/$pauseid/$dist_name_ver");
	my @files    = get_files($dist_name_ver);
	my @ratings  = get_ratings( $dist->{distribution} );
	my @releases = grep { $_->{name} ne $dist_name_ver }
		get_releases( $dist->{metadata}{name} );

	my %SPECIAL = map { $_ => 1 } qw(
		Changes CHANGES Changelog ChangeLog
		LICENSE MANIFEST README COPYING
		INSTALL
		Makefile.PL Build.PL META.yml META.json
		ARTISTIC SIGNATURE
	);

	for my $f (@files) {
		$f->{name}    = delete $f->{'module.name'};
		$f->{version} = delete $f->{'module.version'};

# If a file has several packages in it, then the 'name' field will be an ARRAY
# http://search.cpan.org/~perlancar/Locale-Tie-0.03/
		if ( ref $f->{name} ) {
			$f->{name} = $f->{name}[0];
		}
	}

	my @modules
		= sort { $a->{name} cmp $b->{name} } grep { $_->{name} } @files;
	my @documentation = sort { $a->{documentation} cmp $b->{documentation} }
		grep {
		        $_->{documentation}
			and not $_->{name}
			and $_->{path} !~ m{^t/}
		} @files;

# It seem sco shows META.json if it is available or META.yml if that is available, but not both
# and prefers to show META.json
# http://search.cpan.org/~jdb/PPM-Repositories-0.20/
# http://search.cpan.org/~ironcamel/Business-BalancedPayments-1.0401/
# I wonder if showing both (when available) can be considered a slight improvement or if we should
# hide META.yml if there is a META.json already?

	my %special
		= map { $_->{path} => $_ } grep { $SPECIAL{ $_->{path} } } @files;
	if ( $special{'META.json'} ) {
		delete $special{'META.yml'};
	}

	my @other_files = sort { lc $a->{path} cmp lc $b->{path} }
		grep {
		        not $SPECIAL{ $_->{path} }
			and not $_->{documentation}
			and not $_->{name}
			and not $_->{directory} eq 'true'

# TODO: unclear why to filter these but they were not shown on http://search.cpan.org/~tlinden/apid-0.04/
# README.md, sample/index.html sample/README
#and not( $_->{path} =~ m{(\.map|\.conf|\.ini|cpanfile)$} )
#and not( $_->{path} =~ m{t/} )
# TODO: http://search.cpan.org/dist/HTML-Template/  has all kinds of other files to filter, so there probably need to be a white-list
			and ( $_->{path} =~ /README/ or $_->{path} =~ m{\.html$} )
		} @files;

# TODO: the MANIFEST file gets special treatment here and instead of linking to src/ it is linked without
# anything and then it is shown with links to the actual files.
	my @special_files
		= sort { lc $a->{path} cmp lc $b->{path} } values %special;
	$dist->{this_name} = $dist->{name};
	my $author = get_author_info($pauseid);

	my $rating = '0.0';
	if (@ratings) {
		my $total = 0;
		$total += $_->{rating} for @ratings;
		$rating = sprintf '%.1f', int( 2 * ( $total / scalar @ratings ) ) / 2;

# needs to be a number with one value after the decimal point which should be either 0 or 5:
# e.g.  4.0 or 3.5
	}
	return {
		dist          => $dist,
		author        => $author,
		special_files => \@special_files,
		modules       => \@modules,
		documentation => \@documentation,
		releases      => \@releases,
		other_files   => \@other_files,
		title         => "$author->{name} / $dist->{name} - search.cpan.org",
		reviews       => scalar @ratings,
		rating        => $rating,

	};
}

sub recent {
	my ($end_ymd) = @_;

# http://api.metacpan.org/v0/release/_search?q=status:latest&fields=name,status,date&sort=date:desc&size=100

# 10 most recent releases by OALDERS
# curl 'http://api.metacpan.org/v0/release/_search?q=status:latest%20AND%20author:OALDERS&fields=name,author,status,date,abstract&sort=date:desc&size=10'

	$end_ymd //= strftime( '%Y%m%d', gmtime );
	my @ymd = unpack( 'A4 A2 A2', $end_ymd );
	my $end_y_m_d = join '-', @ymd;
	my $end_time    = timegm( 0, 0, 0, $ymd[2], $ymd[1] - 1, $ymd[0] );
	my $start_time  = $end_time - 7 * 24 * 60 * 60;
	my $start_y_m_d = strftime( '%Y-%m-%d', gmtime($start_time) );
	my $start_ymd   = strftime( '%Y%m%d', gmtime($start_time) );
	my $next_ymd;

	if ( $end_time < time - 24 * 60 * 60 ) {
		my $next_time = $end_time + 7 * 24 * 60 * 60;
		$next_ymd = strftime( '%Y%m%d', gmtime($next_time) );
	}

	my $ua         = HTTP::Tiny->new();
	my $query_json = to_json {
		query => {
			match_all => {},
		},
		filter => {
			and => [
				{ term => { status => 'latest', } },
				{
					range => {
						date => {
							from => "${start_y_m_d}T23:59:59",
							to   => "${end_y_m_d}T23:59:59",
						},
					},
				},
			]
		},
		fields => [qw(name author status date abstract)],
		sort   => { date => 'desc' },
		size   => 2000,
	};

	my @days;
	eval {
		my $resp = $ua->request(
			'POST',
			'http://api.metacpan.org/v0/release/_search',
			{
				headers => { 'Content-Type' => 'application/json' },
				content => $query_json,
			}
		);
		die if not $resp->{success};
		my $json    = $resp->{content};
		my $data    = from_json $json;
		my @distros = map { $_->{fields} } @{ $data->{hits}{hits} };
		my %days;
		foreach my $d (@distros) {
			push @{ $days{ substr( $d->{date}, 0, 10 ) } }, $d;
		}
		@days = map { { date => "${_}T12:00:00", dists => $days{$_} } }
			reverse sort keys %days;
	} or do {
		my $err = $@ // 'Unknown error';
		warn $err if $err;
	};
	my %resp = ( days => \@days, prev => $start_ymd );
	$resp{next} = $next_ymd;
	return \%resp;
}

sub search {
	my ( $query, $mode, $page, $page_size ) = @_;

	if ( $mode eq 'author' ) {
		my @authors
			= sort { $a->{pauseid} cmp $b->{pauseid} }
			get_api_fields(
			"http://api.metacpan.org/v0/author/_search?q=author.name:*$query*&size=5000&fields=name,asciiname,pauseid"
			);
		return template('no_matches') if not @authors;

		return template(
			'search_author',
			{
				authors      => \@authors,
				page_size    => $page_size,
				current_page => $page,
				mode         => $mode,
				query        => $query,
			}
		);
	}

	if ( $mode eq 'dist' ) {
		my @releases
			= sort { $a->{name} cmp $b->{name} }
			get_api_fields(
			"http://api.metacpan.org/v0/release/_search?q=name:*$query*&size=500&fields=date,name,author,abstract,distribution"
			);

		return template('no_matches') if not @releases;
		return template(
			'search_dist',
			{
				dists        => \@releases,
				page_size    => $page_size,
				current_page => $page,
				mode         => $mode,
				query        => $query,
			}
		);
	}

	if ( $mode eq 'module' ) {

#die	get
#		"http://api.metacpan.org/v0/module/_search?q=name:*$query*";
#"http://api.metacpan.org/v0/module/_search?q=name:*$query*&size=500&fields=date,name,author,abstract,distribution,release";

		my @modules
			= sort { $a->{name} cmp $b->{name} }
			get_api_fields(
			"http://api.metacpan.org/v0/module/_search?q=name:*$query*&size=500&fields=date,name,author,abstract,distribution,release,path"
			);

		#die Dumper \@modules;
		return template('no_matches') if not @modules;
		return template(
			'search_dist',
			{
				dists        => \@modules,
				page_size    => $page_size,
				current_page => $page,
				mode         => $mode,
				query        => $query,
			}
		);
	}

	# 'all' is the default behaviour:

	return template('no_matches');
}

sub get_distros_by_pauseid {
	my ($pause_id) = @_;

 # curl 'http://api.metacpan.org/v0/release/_search?q=author:SZABGAB&size=500'
 # TODO the status:latest filter should be on the query not in the grep

	my @data;
	eval {
		my $json
			= get 'http://api.metacpan.org/v0/release/_search?q=author:'
			. $pause_id
			. '&size=500';
		my $raw = from_json $json;
		@data = sort { $a->{name} cmp $b->{name} }
			map {
			{
				name         => $_->{_source}{name},
				abstract     => $_->{_source}{abstract},
				date         => $_->{_source}{date},
				download_url => $_->{_source}{download_url},
			}
			}
			grep { $_->{_source}{status} eq 'latest' }
			@{ $raw->{hits}{hits} };
		1;
	} or do {
		my $err = $@ // 'Unknown error';
		warn $err if $err;
	};
	return \@data;
}

sub get_author_info {
	my ($pause_id) = @_;

 # The data is received from MetaCPAN it is not what the authors set on PAUSE.
 # See https://github.com/CPAN-API/cpan-api/issues/351
 # The source of the data on SCO is this xml file:
 # http://www.cpan.org/authors/00whois.xml

	my $data;
	eval {
		my $json
			= get 'http://api.metacpan.org/v0/author/_search?q=author._id:'
			. $pause_id
			. '&size=1';
		my $raw = from_json $json;
		$data = $raw->{hits}{hits}[0]{_source};
		1;
	} or do {
		my $err = $@ // 'Unknown error';
		warn $err if $err;
	};
	$data->{gravatar_url} =~ s{&}{&amp;}g;
	return $data;
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
	if ( $char =~ /[A-Z]/ ) {
		eval {
			my $json
				= get
				"http://api.metacpan.org/v0/author/_search?q=author._id:$char*&size=5000&fields=name";
			my $data = from_json $json;
			@authors = sort { $a->{id} cmp $b->{id} }
				map { { id => $_->{_id}, name => $_->{fields}{name} } }
				@{ $data->{hits}{hits} };
			1;
		} or do {
			my $err = $@ // 'Unknown error';
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
		$vars->{google_analytics} = path($ga_file)->slurp_utf8 // '';
	}

	eval {
		$vars->{totals} = from_json path("$root/totals.json")->slurp_utf8;
	};

	my $request = Plack::Request->new($env);
	$vars->{query} //= $request->param('query');
	$vars->{mode}  //= $request->param('mode');

	my $tt = Template->new(
		INCLUDE_PATH => "$root/tt",
		INTERPOLATE  => 0,
		POST_CHOMP   => 1,
		EVAL_PERL    => 0,
		START_TAG    => '<%',
		END_TAG      => '%>',
		PRE_PROCESS  => 'incl/header.tt',
		POST_PROCESS => 'incl/footer.tt',
	);
	my $out;
	$tt->process( "$file.tt", $vars, \$out )
		|| Carp::confess $tt->error();
	return [ '200', [ 'Content-Type' => 'text/html' ], [$out], ];
}

sub root {
	my $dir = dirname( dirname( dirname( abs_path(__FILE__) ) ) );
	$dir =~ s{blib/?$}{};
	return $dir;
}

1;

