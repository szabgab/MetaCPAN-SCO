use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize;

plan tests => 2;

my $w = Test::WWW::Mechanize->new;

my $url = 'http://search.cpan.org/';

subtest home => sub {
	$w->get_ok($url);
	$w->title_is('The CPAN Search Site - search.cpan.org');
};

subtest authors => sub {
	$w->follow_link_ok( {text => 'Authors'}, 'Authors link' );
};



