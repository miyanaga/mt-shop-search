package MT::ShopSearch::ShopCategory;

use strict;
use base qw(MT::ShopSearch::Relation);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    column_defs => {
        shopsearch_category_id => 'integer not null',
    },
    indexes => {
        shopsearch_category_id => 1,
    },
    datasource => 'shopsearch_shop_category',
});

sub master_model { 'shopsearch_category' }

1;