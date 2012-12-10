package MT::ShopSearch::Tenant;

use strict;
use base qw(MT::ShopSearch::Master);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    datasource => 'shopsearch_tenant',
});

sub class_label { plugin->translate('Tenant') }
sub class_label_plural { plugin->translate('Tenants') }

1;