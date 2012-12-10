package MT::ShopSearch::ShopBrand;

use strict;
use base qw(MT::ShopSearch::Relation);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    column_defs => {
        shopsearch_brand_id => 'integer not null',
    },
    indexes => {
        shopsearch_brand_id => 1,
    },
    datasource => 'shopsearch_shop_brand',
});

sub master_model { 'shopsearch_brand' }

1;