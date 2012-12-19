package MT::ShopSearch::Shop;

use strict;
use base qw(MT::Object);
use MT::ShopSearch::Util;
use Time::HiRes qw(time);

__PACKAGE__->install_properties({
    column_defs => {
        id              => 'integer not null auto_increment',
        key             => 'string(128)',
        name            => 'string(255)',
        base_priority   => 'integer',
        priority        => 'integer',
        postal          => 'string(32)',
        shopsearch_prefecture_id
                        => 'integer',
        shopsearch_tenant_id
                        => 'integer',
        tel             => 'string(32)',
        map_address     => 'string(255)',
        full_address    => 'string(255)',
        keywords        => 'text',
        comment         => 'text',
        timestamp       => 'float',
    },
    indexes => {
        priority        => { columns => [qw/base_priority priority/] },
        key             => 1,
        shopsearch_prefecture_id
                        => 1,
        shopsearch_tenant_id
                        => 1,
        timestamp       => 1,
    },
    audit => 1,
    datasource => 'shopsearch_shop',
    primary_key => 'id',
});

sub class_label { plugin->translate('Shop') }
sub class_label_plural { plugin->translate('Shops') }

sub save {
    my $self = shift;
    $self->timestamp(time);
    $self->SUPER::save(@_);
}

sub single_masters {
    MT->registry('shopsearch', 'single_masters');
}

sub multi_masters {
    MT->registry('shopsearch', 'multi_masters');
}

sub _single_master {
    my $self = shift;
    my ( $model, $value ) = @_;
    my $col = $model . '_id';
    if ( defined $value ) {
        unless ( ref $value ) {
            $value = MT->model($model)->ensure($value);
        }
        $self->$col($value->id);
        return;
    }

    MT->model($model)->load({
        id => $self->$col,
        enabled => 1,
    });
}

sub _multi_master {
    my $self = shift;
    my ( $model, $relation, $values ) = @_;
    my $id_col = $model . '_id';
    if ( defined $values ) {
        # Remove relations once
        MT->model($relation)->remove({
            shopsearch_shop_id => $self->id,
        });

        my $i = 0;
        for my $value ( @$values ) {
            $value = MT->model($model)->ensure($value) unless ref $value;
            next unless $value;

            my $rel = MT->model($relation)->new;
            $rel->shopsearch_shop_id($self->id);
            $rel->$id_col($value->id);
            $rel->order($i++);
            $rel->save;
        }

        return;
    }

    # Load related masters by priority
    my %rel_ids = map {
        $_->$id_col => 1
    } MT->model($relation)->load({
        shopsearch_shop_id => $self->id,
    });
    my @masters = MT->model($model)->load({
        id => [keys %rel_ids],
    });

    wantarray ? @masters : \@masters;
}

sub prefecture {
    shift->_single_master('shopsearch_prefecture', @_);
}

sub tenant {
    shift->_single_master('shopsearch_tenant', @_);
}

sub categories {
    shift->_multi_master('shopsearch_category', 'shopsearch_shop_category', @_);
}

sub brands {
    shift->_multi_master('shopsearch_brand', 'shopsearch_shop_brand', @_);
}

sub cleanup {
    my $pkg = shift;
    my ( $before ) = @_;

    # Remove expried shops
    $pkg->remove({ timestamp => { '<' => $before }});

    # Single masters
    MT->model('shopsearch_prefecture')->cleanup_as_single_master;
    MT->model('shopsearch_tenant')->cleanup_as_single_master;

    # Multi masters
    MT->model('shopsearch_shop_brand')->cleanup_as_multi_master;
    MT->model('shopsearch_shop_category')->cleanup_as_multi_master;
}

sub reset {
    my $pkg = shift;
    $pkg->remove;

    # Single masters
    MT->model('shopsearch_prefecture')->remove;
    MT->model('shopsearch_tenant')->remove;

    # Multi masters
    MT->model('shopsearch_brand')->remove;
    MT->model('shopsearch_category')->remove;
    MT->model('shopsearch_shop_brand')->remove;
    MT->model('shopsearch_shop_category')->remove;
}

sub ensure {
    my $pkg = shift;
    my ( $key ) = @_;

    my $shop = $pkg->load({key => $key});
    unless ( $shop ) {
        $shop = $pkg->new;
    }

    $shop;
}

sub sync_from_tsv {
    my $pkg = shift;
    my ( $tsv, $no_cleanup ) = @_;
    my $ts = time;

    my %cols = (
        priority        => excel_column_index('A'),
        shop            => excel_column_index('B'),
        tenant          => excel_column_index('C'),
        tenant_kana     => excel_column_index('D'),
        prefecture      => excel_column_index('M'),
        postal          => excel_column_index('L'),
        tel             => excel_column_index('P'),
        address1        => excel_column_index('N'),
        address2        => excel_column_index('O'),
        brands          => excel_column_index('F'),
        categories      => excel_column_index('I'),
        comment         => excel_column_index('J'),
        keywords        => excel_column_index('G'),
    );

    my @lines = split(/\r?\n/, $tsv);
    shift @lines;

    my $alert = sub {
        my ($ln, $msg) = @_;
        print STDERR $msg, " at $ln\n";
    };

    my $line_num = 1;
    for my $line ( @lines ) {
        $line_num++;
        $line or $alert->($line_num, "Empty line"), next;
        my @row = map { s!^\s+|\s+$!!g; $_ } split(/\t/, $line);

        my %values;
        my %cols = map {
            $_ => $row[$cols{$_}],
        } keys %cols;

        # Tel
        my $tel = $values{tel} = $cols{tel} or $alert->($line_num, "No tel"), next;
        $tel =~ s/\s+//g;
        unless ( $tel =~ /^[0-9\-]+$/ ) {
            $alert->($line_num, "Invalid tel: $tel");
            next;
        }

        # Shop
        my $shop_name = $cols{shop} or $alert->($line_num, "No shop name"), next;

        # Unique Key
        my $key = $values{key} = $shop_name . $tel;

        # Prefecture
        my $prefecture = $cols{prefecture} or $alert->($line_num, "No prefecture"), next;

        # Tenant
        my $tenant = $cols{tenant} or $alert->($line_num, "No tenant"), next;

        # Brands
        my @brands = split(/\s*,\s*/, $cols{brands});

        # Categories
        my @categories =  split(/\s*,\s*/, $cols{categories});

        # Name
        $values{name} = $shop_name;

        # Addresses
        $values{postal} = $cols{postal} or $alert->($line_num, "No postal"), next;
        $values{map_address} = $prefecture . $cols{address1};
        $values{full_address} = $prefecture . $cols{address1};
        $values{full_address} .= ' ' . $cols{address2} if $cols{address2};

        # Keywords
        $values{keywords} = join("\n",
            grep { $_ } map { $cols{$_} } grep { $_ ne 'priority' } keys %cols
        );

        # Priority
        $values{priority} = $cols{priority} || 0;

        # Shop Object
        my $shop = MT->model('shopsearch_shop')->ensure($key);
        $shop->set_values(\%values);

        # Masters
        $shop->tenant($tenant);
        $shop->prefecture($prefecture);
        $shop->save;

        $shop->brands(\@brands);
        $shop->categories(\@categories);
    }

    $pkg->cleanup($ts) unless $no_cleanup;
}

sub search_by_param {
    my $pkg = shift;
    my ( $cond ) = @_;

    my %terms;
    my %args = (
        sort => [
            { column => 'base_priority', desc => 'DESC' },
            { column => 'priority', desc => 'DESC' },
        ],
    );

    # Name
    $terms{name} = $cond->{shopsearch_name}
        if $cond->{shopsearch_name};

    # Single master
    for my $master ( qw/shopsearch_tenant shopsearch_prefecture/ ) {
        my $col = $master . '_id';
        if ( my $text = delete $cond->{$master} ) {
            my $id = MT->model($master)->id_of($text);
            $cond->{$col} = $id || 0;
        }
        $terms{$col} = $cond->{$col} if $cond->{$col};
    }

    # Multi master
    for my $master ( qw/shopsearch_brand shopsearch_category/ ) {
        my $col = $master . '_id';
        if ( my $text = delete $cond->{$master} ) {
            my $id = MT->model($master)->id_of($text);
            $cond->{$col} = $id || 0;
        }
    }

    my @ids;
    for my $model ( qw/shopsearch_shop_category shopsearch_shop_brand/ ) {
        my $class = MT->model($model);
        my $col = $class->master_column;
        my $master_id = $cond->{$col} || next;

        push @ids, $class->shop_ids_for($master_id);
    }

    if ( @ids ) {
        my $intersect = intersect_arrays(@ids);
        $terms{id} = $intersect if scalar @$intersect;
    }

    # Keywords
    if ( my $q = $cond->{q} ) {
        $terms{keywords} = { like => join('', '%', $q, '%') };
    }

    # Paging
    if ( $cond->{paging} ) {
        my $count = $pkg->count(\%terms);

        my $page = $cond->{page} || 0;
        my $per_page = $cond->{per_page} || 20;
        my $page_number = $page + 1;

        $cond->{count} = $count;
        $cond->{pages} = int( $count / $per_page );
        $cond->{pages}++ if $count % $per_page;

        # Overflow
        my $pages = $cond->{pages};

        # Feedback actual page
        $cond->{page} = $page;
        $cond->{page_number} = $page_number;

        # Prev/Next
        if ( $page_number < $pages ) {
            $cond->{next_page} = $page + 1;
            $cond->{next_page_number} = $page + 2;
        }
        if ( $page_number > 0 ) {
            $cond->{prev_page} = $page - 1;
            $cond->{prev_page_number} = $page;
        }

        # Query windowed
        $args{offset} = $per_page * $page;
        $args{limit} = $per_page;
    }

    $pkg->load(\%terms, \%args);
}

sub list_props {
    return {
        priority => {
            auto        => 1,
            base        => '__virtual.integer',
            display     => 'force',
        },
        name => {
            auto        => 1,
            label       => 'Shop Name',
            display     => 'force',
            order       => 200,
        },
        shopsearch_prefecture_id => {
            auto        => 1,
            label       => 'Prefecture',
            base        => '__virtual.single_select',
            display     => 'default',
            order       => 300,
            single_select_options => [
                map {
                    { label => $_->name, value => $_->id }
                } MT->model('shopsearch_prefecture')->load({enabled => 1})
            ],
        },
        full_address => {
            auto        => 1,
            label       => 'Full Address',
            display     => 'default',
            order       => 400,
            col_class   => 'primary',
        },
    };
}

1;