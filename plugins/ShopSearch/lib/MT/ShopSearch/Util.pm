package MT::ShopSearch::Util;

use strict;
use base qw(Exporter);
use Carp;
use File::Spec;
use Encode;

our @EXPORT = qw(plugin excel_column_index intersect_arrays upload_tsv);

sub plugin {
    MT->component('shopsearch');
}

sub excel_column_index {
    my $col = shift || return;
    
    my $base = 26;
    my $notation = 1;
    my @digits = reverse split('', $col);
    my $number = 0;
    my $starts = ord 'A';
    my $offset = 1;

    for my $d ( @digits ) {
        my $n = ord($d) - $starts;
        Carp::confess("Invalid excel column: $col")
            if $n < 0 || $n >= $base;
        $number += $notation * ( $n + $offset );
        $notation *= $base;
    }

    $number - $offset;
}

sub intersect_arrays {
    my @arrays = @_;
    my $first = shift @arrays || return [];
    return [] unless ref $first eq 'ARRAY';

    my %hash = map { $_ => 1 } @$first;
    while ( my $a = shift @arrays ) {
        next unless ref $a eq 'ARRAY';
        my %h = map { $_ => 1 } @$a;

        for my $key ( keys %hash ) {
            delete $hash{$key} unless $h{$key};
        }
    }

    [ keys %hash ];
}

sub upload_tsv {
    my $tsv = shift;
    my $path = File::Spec->catdir( MT->instance->config->TempDir, 'shopsearch.tsv' );

    if ( $tsv ) {
        $tsv =~ s/(^\s+)|(\s+$)//g;
        $tsv =~ s/\r\n/\n/g;
        $tsv .= "\n";
        $tsv = Encode::encode_utf8($tsv) if Encode::is_utf8($tsv);
        open(my $fh, '>', $path);
        binmode($fh);
        print $fh $tsv;
        close $fh;
        return;
    }

    open(my $fh, $path);
    binmode($fh);
    $tsv = join('', <$fh>);
    close $fh;
    $tsv = Encode::decode_utf8($tsv) unless Encode::is_utf8($tsv);

    $tsv;
}

1;