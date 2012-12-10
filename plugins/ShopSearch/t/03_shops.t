use strict;
use utf8;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use MTPath;

use File::Spec;
use Encode;

sub load_data_file {
    my $path = shift;
    open(my $fh, File::Spec->catdir($FindBin::Bin, 'data', $path));
    binmode $fh;
    my $contents = join('', <$fh>);
    close $fh;

    $contents = Encode::decode_utf8($contents)
        unless Encode::is_utf8($contents);

    $contents;
};

sub count_search_shop {
    my $param = shift;
    for my $master ( qw/tenant prefecture brand category/ ) {
        my $name = delete $param->{$master} || next;
        my $obj = MT->model("shopsearch_${master}")->load({name => $name}) || next;
        $param->{"shopsearch_${master}_id"} = $obj->id;
    }
    my @shops = MT->model('shopsearch_shop')->search_by_param($param);
    scalar @shops;
}

subtest 'Reset' => sub {
    MT->model('shopsearch_shop')->reset;

    is( MT->model('shopsearch_shop')->count, 0 );
    is( MT->model('shopsearch_tenant')->count, 0 );
    is( MT->model('shopsearch_prefecture')->count, 0);
    is( MT->model('shopsearch_brand')->count, 0 );
    is( MT->model('shopsearch_category')->count, 0 );
    is( MT->model('shopsearch_shop_brand')->count, 0 );
    is( MT->model('shopsearch_shop_category')->count, 0 );
};

subtest 'Initial Shops' => sub {
    my $tsv = load_data_file('shops_initial.tsv');

    MT->model('shopsearch_shop')->sync_from_tsv($tsv);

    is( MT->model('shopsearch_shop')->count, 29 );
    is( MT->model('shopsearch_tenant')->count({enabled => 1}), 26 );
    is( MT->model('shopsearch_prefecture')->count({enabled => 1}), 12 );
    is( MT->model('shopsearch_brand')->count({enabled => 1}), 39 );
    is( MT->model('shopsearch_category')->count({enabled => 1}), 20 );
    is( MT->model('shopsearch_shop_brand')->count, 83 );
    is( MT->model('shopsearch_shop_category')->count, 58 );
};

subtest 'Added Shops' => sub {
    my $tsv = load_data_file('shops_added.tsv');

    MT->model('shopsearch_shop')->sync_from_tsv($tsv);

    is( MT->model('shopsearch_shop')->count, 30 );
    is( MT->model('shopsearch_tenant')->count({enabled => 1}), 27 );
    is( MT->model('shopsearch_prefecture')->count({enabled => 1}), 13 );
    is( MT->model('shopsearch_brand')->count({enabled => 1}), 39 );
    is( MT->model('shopsearch_category')->count({enabled => 1}), 21 );
    is( MT->model('shopsearch_shop_brand')->count, 83 );
    is( MT->model('shopsearch_shop_category')->count, 63 );

    subtest 'Search Single' => sub {
        is count_search_shop({}), 30, 'All';
        is count_search_shop({ tenant => '新宿伊勢丹'}), 2, '新宿伊勢丹';
        is count_search_shop({ prefecture => '東京都'}), 13, '東京都';
        is count_search_shop({ category => 'レディース'}), 1, 'レディース';
    };

    subtest 'Search Keyword' => sub {
        is count_search_shop({ q => '広島市' }), 2, '広島市';
        is count_search_shop({ q => 'せんだい' }), 1, 'せんだい';
    };

    subtest 'Search Multi' => sub {
        is count_search_shop({ prefecture => '神奈川県', brand => 'アルチザン(MEN)'}), 1, '神奈川県 and アルチザン(MEN)';
        is count_search_shop({ brand => 'コムサデモード', category => 'レディス'}), 2, 'コムサデモード and レディス';
        is count_search_shop({ brand => 'コムサデモード', category => 'レディス', q => '婦人服'}), 2, 'コムサデモード and レディス and 婦人服';
    };
};

 subtest 'Only One Shop' => sub {
    my $tsv = load_data_file('shops_only_one.tsv');

    MT->model('shopsearch_shop')->sync_from_tsv($tsv);

    is( MT->model('shopsearch_shop')->count, 1 );
    is( MT->model('shopsearch_tenant')->count({enabled => 1}), 1 );
    is( MT->model('shopsearch_prefecture')->count({enabled => 1}), 1 );
    is( MT->model('shopsearch_brand')->count({enabled => 1}), 2 );
    is( MT->model('shopsearch_category')->count({enabled => 1}), 1 );
    is( MT->model('shopsearch_shop_brand')->count, 2 );
    is( MT->model('shopsearch_shop_category')->count, 1 );

    subtest 'Masters Not Deleted' => sub {
        is( MT->model('shopsearch_tenant')->count, 28 );
        is( MT->model('shopsearch_prefecture')->count, 13 );
        is( MT->model('shopsearch_brand')->count, 39 );
        is( MT->model('shopsearch_category')->count, 21 );
    };
};

done_testing;