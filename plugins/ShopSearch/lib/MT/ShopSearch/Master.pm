package MT::ShopSearch::Master;

use strict;
use base qw(MT::Object);
use MT::ShopSearch::Util;

__PACKAGE__->install_properties({
    column_defs => {
        id              => 'integer not null auto_increment',
        enabled         => 'smallint',
        name            => 'string(255)',
        priority        => 'integer',
    },
    indexes => {
        priority        => 1,
        enabled         => 1,
        name            => 1,
    },
    primary_key => 'id',
    datasource => 'shopsearch_master',
    child_of => [ 'MT::ShopSearch::Shop' ],
});

sub class_label { plugin->translate('Master') }
sub class_label_plural { plugin->translate('Masters') }

sub cleanup_as_single_master {
    my $pkg = shift;

    # Used master id
    my $col = $pkg->datasource . '_id';
    my %ids = map {
        $_->$col => 1
    } MT->model('shopsearch_shop')->load;

    # Disable master not used
    my $iter = $pkg->load_iter;
    while ( my $master = $iter->() ) {
        next if $ids{$master->id};
        $master->enabled(0);
        $master->save;
    }
}

sub load {
    my $pkg = shift;
    my $terms = shift;
    my $args = shift;

    $args ||= {};
    unless ( defined $args->{sort} ) {
        $args->{sort} = 'priority';
        $args->{direction} = 'descend';
    }

    $pkg->SUPER::load($terms, $args, @_);
}

sub load_iter {
    my $pkg = shift;
    my $terms = shift;
    my $args = shift;

    $args ||= {};
    unless ( defined $args->{sort} ) {
        $args->{sort} = 'priority';
        $args->{direction} = 'descend';
    }

    $pkg->SUPER::load_iter($terms, $args, @_);
}

sub request_cache {
    my $pkg = shift;
    my $cache = MT::Request->instance->cache("$pkg.cache");
    unless ( $cache ) {
        MT::Request->instance->cache("$pkg.cache", $cache = {});
    }

    $cache;
}

sub cache_preload {
    my $pkg = shift;
    my $cache = $pkg->request_cache;

    $cache->{$_->name} = $_ foreach $pkg->load;
}

sub ensure {
    my $pkg = shift;
    my ( $name ) = @_;
    $name or return;

    my $cache = $pkg->request_cache;

    my $obj;
    if ( $cache->{$name} ) {
        $obj = $cache->{$name};
    } else {
        $obj = $pkg->load({name => $name});
        unless ( $obj ) {
            $obj = $pkg->new;
            $obj->name($name);
            $obj->priority(0);
            $obj->enabled(1);
            $obj->save;
        }
    }

    unless ( $obj->enabled ) {
        $obj->enabled(1);
        $obj->save;
    }

    $cache->{$name} = $obj;

    $obj;
}

sub load_hash {
    my $pkg = shift;
    my @masters = $pkg->load({enabled => 1});
    my %masters = map {
        $_->id => $_->name,
    } @masters;
    \%masters;
}

sub load_array {
    my $pkg = shift;
    my @masters = $pkg->load({
        enabled => 1,
    });
    my @results = map {
        { id => $_->id, name => $_->name },
    } @masters;
    wantarray ? @results : \@results;
}

sub id_of {
    my $pkg = shift;
    my ( $name ) = @_;
    my $obj = $pkg->load({name => $name, enabled => 1}) || return;

    $obj->id;
}

1;