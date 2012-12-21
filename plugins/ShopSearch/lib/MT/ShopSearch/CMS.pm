package MT::ShopSearch::CMS;

use strict;
use Encode;
use MT::ShopSearch::Util;

sub _check_context {
    my $app = shift;
    my $user = $app->user || return $app->errtrans('Invalid request');
    return $app->permission_denied if !$user->is_superuser && !$user->can_manage_shopsearch;
    return $app->return_to_dashboard( redirect => 1 ) if $app->blog;

    1;
}

sub start_update {
    my $app = shift;
    _check_context($app) or return;

    plugin->load_tmpl('start_update.tmpl');
}

sub upload_update {
    my $app = shift;
    my $user = $app->user || return $app->errtrans('Invalid request');
    return $app->permission_denied if !$user->is_superuser && !$user->can_manage_shopsearch;
    return $app->return_to_dashboard( redirect => 1 ) if $app->blog;

    my $q = $app->param;
    my $tsv = $q->param('tsv');

    upload_tsv($tsv);

    plugin->load_tmpl('updating.tmpl', {
        next_uri => $app->uri(
            mode => 'shopsearch_do_update',
        ),
    });
}

sub do_update {
    my $app = shift;
    my $q = $app->param;
    my $user = $app->user || return $app->errtrans('Invalid request');
    return $app->permission_denied if !$user->is_superuser && !$user->can_manage_shopsearch;
    return $app->return_to_dashboard( redirect => 1 ) if $app->blog;

    my $tsv = upload_tsv;

    my $before = MT->model('shopsearch_shop')->count || 0;
    MT->model('shopsearch_shop')->sync_from_tsv($tsv);
    my $after = MT->model('shopsearch_shop')->count || 0;

    plugin->load_tmpl('finish_update.tmpl', {
        before => $before,
        after => $after,
    });
}

sub edit_masters {
    my $app = shift;
    _check_context($app) or return;
    my $q = $app->param;

    my @masters = (
        {
            key => 'shopsearch_prefecture',
            label => plugin->translate('Prefecture'),
            master => [],
        },
        # {
        #     key => 'shopsearch_tenant',
        #     label => plugin->translate('Tenant'),
        #     master => [],
        # },
        {
            key => 'shopsearch_brand',
            label => plugin->translate('Brand'),
            master => [],
        },
        {
            key => 'shopsearch_category',
            label => plugin->translate('Category'),
            master => [],
        },
    );

    for my $m ( @masters ) {
        my @master;
        my $iter = MT->model($m->{model} || $m->{key})->load_iter({enabled => 1})
            or next;
        while ( my $r = $iter->() ) {
            push @master, {
                id => $r->id,
                label => $r->name,
            };
        }
        $m->{master} = \@master;
    }

    plugin->load_tmpl('edit_masters.tmpl', {
        saved => $q->param('saved') || 0,
        masters => \@masters,
    });
}

sub save_masters {
    my $app = shift;
    _check_context($app) or return;
    my $q = $app->param;

    my @masters = (
        'shopsearch_prefecture',
#        'shopsearch_tenant',
        'shopsearch_brand',
        'shopsearch_category',
    );

    my %priorities;
    for my $m ( @masters ) {
        my %map = map {
            $_->id => $_
        } MT->model($m)->load({enabled => 1});

        $priorities{$m} = {};
        my @ids = split(/\s*,\s*/, $q->param($m));
        my $i = scalar @ids;
        for my $id ( @ids ) {
            $i--;
            my $obj = $map{$id} || next;
            $obj->priority($i);
            $obj->save;

            $priorities{$m}->{$id} = $i;
        }
    }

    $app->redirect(
        $app->uri( mode => 'shopsearch_edit_masters', args => { saved => 1 } )
    );
}

sub list_actions {
    my %actions;
    for my $p ( 1..5 ) {
        $actions{"priority_$p"} = {
            label => plugin->translate('Set Prority To [_1]', $p),
            order => $p * 100,
            mode => 'shopsearch_shop_priority',
            js_message => 'change priority',
            system_permission => 'manage_shopsearch',
        };     
    };

    \%actions;
}

sub shop_priority {
    my $app = shift;
    _check_context($app) or return;
    my $q = $app->param;
    my $action = $q->param('action_name') or return $app->errtrans('Invalid request');
    my $priority;
    if ( $action =~ /^priority_([0-9]+)$/ ) {
        $priority = $1;
    } else {
        return $app->errtrans('Invalid request');
    }

    my @ids = $app->param('id');
    my @shops = MT->model('shopsearch_shop')->load({id => \@ids});
    for my $shop ( @shops ) {
        $shop->priority($priority);
        $shop->save;
    }

    $app->redirect(
        $app->uri( mode => 'list', args => { _type => 'shopsearch_shop', saved => 1 })
    );
}

1;