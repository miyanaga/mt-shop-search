package MT::ShopSearch::Brand;

use strict;
use base qw(MT::ShopSearch::Master);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    datasource => 'shopsearch_brand',
});

sub class_label { plugin->translate('Brand') }
sub class_label_plural { plugin->translate('Brands') }

1;