package MT::ShopSearch::Core;

use strict;

sub init { 1 }

package MT::Author;

sub can_manage_shopsearch {
    my $author = shift;
    if (@_) {
        $author->permissions(0)->can_manage_shopsearch(@_);
    }
    else {
        $author->is_superuser()
            || $author->permissions(0)->can_manage_shopsearch(@_);
    }
}

1;