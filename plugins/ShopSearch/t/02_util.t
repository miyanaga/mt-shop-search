use strict;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use MTPath;

use MT::ShopSearch::Util;

subtest 'Excel Column Index' => sub {
    is excel_column_index('A'), 0;
    is excel_column_index('B'), 1;
    is excel_column_index('Z'), 25;
    is excel_column_index('AA'), 26;
    is excel_column_index('AB'), 27;
    is excel_column_index('AZ'), 51;
    is excel_column_index('BA'), 52;
    is excel_column_index('BB'), 53;
    is excel_column_index('BZ'), 77;
    is excel_column_index('ZZ'), 701;
    is excel_column_index('AAA'), 702;
};

subtest 'Arrays Intersection' => sub {
    is_deeply intersect_arrays(
        [qw/a b c d/],
        [qw/a b c e/],
        [qw/a b f/]
    ), [qw/a b/];
};

done_testing;