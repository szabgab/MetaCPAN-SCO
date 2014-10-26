package t::lib::Test;
use strict;
use warnings;

use Exporter qw(import);
use Test::Builder;
our @EXPORT = qw(contains html_check);


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

