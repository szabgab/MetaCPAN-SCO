package MetaCPAN::SCO::Fetch;
use strict;
use warnings;

use LWP::Simple qw(get);
use JSON qw(from_json to_json);
use Path::Tiny qw(path);

=pod

TODO: Once we are sure these are the correct queries, add them to https://github.com/CPAN-API/cpan-api/wiki/API-docs

curl -XPOST api.metacpan.org/v0/author/_search -d '{
  "query": { "match_all": {} },
  "size":0
}'
curl http://api.metacpan.org/v0/author/_search?size=0


curl -XPOST api.metacpan.org/v0/distribution/_search -d '{
  "query": { "match_all": {} },
  "size":0
}'
curl http://api.metacpan.org/v0/distribution/_search?size=0


curl -XPOST api.metacpan.org/v0/module/_search -d '{
  "query": { "match_all": {} },
  "size":0
}'
curl http://api.metacpan.org/v0/module/_search?size=0

=cut

sub run {
	my ( $self, $root ) = @_;

	my %totals;
	foreach my $name (qw(author distribution module)) {
		my $json = get "http://api.metacpan.org/v0/$name/_search?size=0";
		my $data = from_json $json;
		$totals{$name} = $data->{hits}{total};
	}
	path("$root/totals.json")->spew_utf8( to_json \%totals );
	return;
}

1;

