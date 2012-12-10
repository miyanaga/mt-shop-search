package MT::ShopSearch::Relation;

use strict;
use base qw(MT::Object);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    column_defs => {
        id          => 'integer not null auto_increment',
        shopsearch_shop_id
                    => 'integer not null',
        order       => 'integer',
    },
    indexes => {
        shopsearch_shop_id => 1,
    },
    datasource => 'shopsearch_relation',
    primary_key => 'id',
});

sub master_model { }
sub master_column { shift->master_model . '_id' }

sub cleanup_as_multi_master {
    my $pkg = shift;

    # Used shop_id
    my %shop_ids = map {
        $_->id => 1
    } MT->model('shopsearch_shop')->load(undef, { fetchonly => [qw/id/] });

    # Remove shop_id not used
    {
        my $iter = $pkg->load_iter();
        while ( my $obj = $iter->() ) {
            $obj->remove unless $shop_ids{$obj->shopsearch_shop_id};
        }
    }

    # Used master id
    my $col = $pkg->master_column;
    my %ids = map {
        $_->$col => 1
    } $pkg->load(undef, { fetchonly => ['id', $col]});

    # Remove master_id not used
    {
        my $iter = MT->model($pkg->master_model)->load_iter();
        while ( my $master = $iter->() ) {
            next if $ids{$master->id};
            $master->enabled(0);
            $master->save;
        }
    }
}

sub shop_ids_for {
    my $pkg = shift;
    my ( $master_id ) = @_;

    # Used shop ids
    my $col = $pkg->master_column;
    my %shop_ids = map {
        $_->shopsearch_shop_id => 1
    } $pkg->load({ $col => $master_id }, { fetchonly => ['shopsearch_shop_id', $col]});

    [ keys %shop_ids ];
}

1;