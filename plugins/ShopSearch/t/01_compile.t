use strict;
use Test::More;
use FindBin;
use lib $FindBin::Bin;
use MTPath;

use_ok 'MT::ShopSearch::Util';
use_ok 'MT::ShopSearch::Shop';
use_ok 'MT::ShopSearch::Master';
use_ok 'MT::ShopSearch::Brand';
use_ok 'MT::ShopSearch::Prefecture';
use_ok 'MT::ShopSearch::Tenant';
use_ok 'MT::ShopSearch::Category';
use_ok 'MT::ShopSearch::Relation';
use_ok 'MT::ShopSearch::ShopCategory';
use_ok 'MT::ShopSearch::ShopBrand';
use_ok 'MT::ShopSearch::CMS';
use_ok 'MT::ShopSearch::Search';

done_testing;