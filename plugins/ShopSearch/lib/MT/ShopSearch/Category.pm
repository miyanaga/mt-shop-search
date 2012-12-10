package MT::ShopSearch::Category;

use strict;
use base qw(MT::ShopSearch::Master);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    datasource => 'shopsearch_category',
});

sub class_label { plugin->translate('Category') }
sub class_label_plural { plugin->translate('Categories') }

1;