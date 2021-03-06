package MT::ShopSearch::Search;

use strict;

sub _load_masters {
    my $app = shift;
    my ( $param ) = @_;

    my @masters = (
        'shopsearch_prefecture',
        'shopsearch_tenant',
        'shopsearch_brand',
        'shopsearch_category',
    );

    my %result;
    for my $m ( @masters ) {
        my @master = map {
            {
                value => $_->id,
                label => $_->name,
                active => ( $param->{$m} && $param->{$m} eq $_->name )
                    || ( $param->{"${m}_id"} && $param->{"${m}_id"} eq $_->id )
                    ? 1 : 0,
            }
        } MT->model($m)->load({enabled => 1});

        $result{$m} = \@master;
    }

    \%result;
}

sub _search_shop {
    my $app = shift;
    my ( $params ) = @_;

    my @shops = MT->model('shopsearch_shop')->search_by_param($params);
    my @rows = map {
        {
            id      => $_->id,
            name    => $_->name,
            map_address => $_->map_address,
            full_address => $_->full_address,
        }
    } @shops;

    \@rows;
}

sub search_form {
    my $app = shift;
    my %params = $app->param_hash;
    $params{paging} = 1 unless defined $params{paging};

    $params{rows} = _search_shop($app, \%params);
    $params{masters} = _load_masters($app, \%params);

    my $tmpl = MT->model('template')->load({
        blog_id => 0,
        type => 'shopsearch',
    });

    $tmpl->param(\%params);
    $tmpl;
}

sub ajax_search {
    my $app = shift;
    my %params = $app->param_hash;
    $params{paging} = 1 unless defined $params{paging};

    $params{rows} = _search_shop($app, \%params);

    $app->json_result(\%params);
}

sub do_search {
    my $app = shift;
    my %params = $app->param_hash;
    $params{paging} = 1 unless defined $params{paging};

    $params{rows} = _search_shop($app, \%params);

    my $tmpl = MT->model('template')->load({
        blog_id => 0,
        type => 'custom',
        identifier => 'search_result',
    });

    $tmpl->param(\%params);
    $tmpl;
}

sub ajax_masters {
    my $app = shift;
    my %params = $app->param_hash;
    $params{paging} = 1 unless defined $params{paging};

    my $masters = _load_masters($app, \%params);

    $app->json_result($masters);
}

1;