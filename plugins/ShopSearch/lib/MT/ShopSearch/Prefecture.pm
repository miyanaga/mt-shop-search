package MT::ShopSearch::Prefecture;

use strict;
use base qw(MT::ShopSearch::Master);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    datasource => 'shopsearch_prefecture',
});

sub class_label { plugin->translate('Prefecture') }
sub class_label_plural { plugin->translate('Prefectures') }

1;