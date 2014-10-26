package t::lib::Test;
use strict;
use warnings;

use Exporter qw(import);
use Test::Builder;
use HTML::Tidy;

our @EXPORT = qw(contains html_check html_tidy);

sub html_tidy {
	my $tidy = HTML::Tidy->new;

	# HTML 4: <script src="/jquery.js" type="text/javascript"></script>
	# HTML 5: <script src="/jquery.js"></script>
	$tidy->ignore( text => qr{<script> inserting "type" attribute} );

	# HTML 4: <link rel="stylesheet" href="/style.css" type="text/css" />
	# HTML 5: <link rel="stylesheet" href="/style.css" />
	$tidy->ignore( text => qr{<link> inserting "type" attribute} );

	# HTML 4.01    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	# HTML 5       <meta charset="utf-8" />
	$tidy->ignore( text => qr{<meta> proprietary attribute "charset"} );
	$tidy->ignore( text => qr{<meta> lacks "content" attribute} );

	# AFAIK HTML 5 does not support the "summary" attribute
	$tidy->ignore( text => qr{<table> lacks "summary" attribute} );

	# We should probably replace & in gravatar URLS by &amp; instead of hiding the warning:
	#$tidy->ignore( text => qr{unescaped & or unknown entity "&d"} );

	#$tidy->ignore( text => qr{inserting} ); #: <script> inserting "type" attribute} );

	return $tidy;
}



sub contains {
	my ( $str, $expected, $name ) = @_;
	$name //= '';

	my $T = Test::Builder->new;
	my $res = $T->ok(0 < index( $str, $expected ), $name);
	if ( not $res ) {
		$T->diag($str);
		$T->diag("\nDoes not contain:\n\n");
		$T->diag("'$expected'");
	}
	return $res;
}

sub html_check {
	my ( $html, $name ) = @_;
	$name //= 'html_check';

	my $T = Test::Builder->new;
	my @rows = split /\r?\n/, $html;
	my @fails;
	foreach my $i ( 0 .. @rows - 1 ) {

		#if ( $rows[$i] =~ /class=(?!")/ ) {
		if ( $rows[$i] =~ m{<\w+(\s+\w+="[^"]*")*\s+\w+=\w} ) {
			push @fails, "row $i   $rows[$i]";
		}
	}
	$T->ok( @fails == 0, $name );
	foreach my $f (@fails) {
		$T->diag($f);
	}
}

1;

