use strict;
use utf8;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use MTPath;

use JSON;
use File::Spec;
use Encode;

use MT::Plugins::Test::Request::Search;

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

    is( MT->model('shopsearch_shop')->count, 0, 'Reset' );
};

subtest 'Initial Shops' => sub {
    my $tsv = load_data_file('shops_initial.tsv');

    MT->model('shopsearch_shop')->sync_from_tsv($tsv);

    my $searcher = 'MT::Plugins::Test::Request::Search';

    subtest 'Masters API' => sub {
        $searcher->test_mech(
            via => 'bootstrap',
            test => sub {
                my $mech = shift;
                my $res = $mech->post( $searcher->uri, { __mode => 'shopsearch_ajax_masters' } );

                my $json = $res->content;
                $json = Encode::decode_utf8($json) unless Encode::is_utf8($json);
                $json = from_json($json);

                my %masters = map {
                    my $tupples = $json->{result}->{$_};
                    my @labels = map {
                        $_->{label}
                    } @$tupples;

                    ( $_ => \@labels );
                } keys %{$json->{result}};

                is_deeply \%masters, {
                    shopsearch_prefecture => [qw/東京都 宮城県 広島県 愛知県 大阪府 神奈川県 熊本県 鹿児島県 沖縄県 福岡県 北海道 千葉県/],
                    shopsearch_tenant => [qw/池袋東武 新宿伊勢丹 仙台藤崎 広島そごう 名古屋高島屋 心斎橋大丸 マルイシティ横浜 東京大丸 渋谷西武 熊本鶴屋 鹿児島アミュプラザ 渋谷マルイシティ 青山 新宿高島屋 名古屋三越 沖縄リウボウ 福岡岩田屋 銀座路面 札幌丸井今井 船橋東武 錦糸町丸井 自由が丘マスト 新宿マルイメン 具志川サンエー 新宿マルイアネックス 福山ロッツ/],
                    shopsearch_brand => [qw/コムサデモード KT ギャバジンK.T ヴィーナスクローゼット バジーレ28 コムサステージ(MEN) コムサメン アルチザン(MEN) PPFM コムサコミューン パープル&イエロー(MEN) ペイトンプレイス コムサフォセット アルチザン(BABY) コムサフィユ アルチザン(CHILDREN) コムサブロンドオフ アルチザン・ウフ コムサブロンドオフベビー(WOMEN) コムサブロンドオフベビー(CHILDREN) ベータ プレシャスミックス ボナジョルナータ(WOMEN) コムサマチュア MONO モノコムサ コムサイズム(FAMILY) コムサイズム(WOMEN) コムサイズム(MEN) コムサイズム(CHILDREN) BG コムサスタイル(FAMILY) コムサスタイル(WOMEN) コムサスタイル(MEN) コムサストア(FAMILY) コムサストア(WOMEN) コムサストア(MEN) コムサストア(CHILDREN) ボナジョルナータ/],
                    shopsearch_category => [qw/レディス コムサデモード ギャバジンK.T K.T レディス(大きいサイズ) メンズ コムサメン アルチザン(MEN) PPFM コムサコミューン パープル＆イエロー(M) レディス(大きいサイズと小さいサイズもあわせて展開しております。) ベビー キッズ マタニティ バジーレ28 ギャバジンＫ.Ｔ ベータ モノコムサ ボナジョルナータ/],
                }, 'Masters';
            },
        );
    };

};

done_testing;