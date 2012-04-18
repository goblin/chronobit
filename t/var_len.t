use strict;
use warnings;

use Test::More;

use ChronoBit::Util;
BEGIN { use_ok('ChronoBit::Bitcoin'); }

is(bin2hex(var_int->build(3)), '03');
is(bin2hex(var_int->build(0xfc)), 'fc');
is(bin2hex(var_int->build(0xfd)), 'fdfd00');
is(bin2hex(var_int->build(0xfe)), 'fdfe00');
is(bin2hex(var_int->build(0xffff)), 'fdffff');
is(bin2hex(var_int->build(0x10000)), 'fe00000100');
is(bin2hex(var_int->build(0xffffffff)), 'feffffffff');
is(bin2hex(var_int->build(0xffffffff + 1)), 'ff0000000001000000');

is(var_int->parse(hex2bin('03')), 3);
is(var_int->parse(hex2bin('fc')), 0xfc);
is(var_int->parse(hex2bin('fdfd00')), 0xfd);
is(var_int->parse(hex2bin('fdfe00')), 0xfe);
is(var_int->parse(hex2bin('fdffff')), 0xffff);
is(var_int->parse(hex2bin('fe00000100')), 0x10000);
is(var_int->parse(hex2bin('feffffffff')), 0xffffffff);
is(var_int->parse(hex2bin('ff0000000001000000')), 0xffffffff + 1);

is(bin2hex(var_str->build('dupa jeza')), '0964757061206a657a61');
is(bin2hex(var_bytes->build('dupa jeza')), '0964757061206a657a61');

is(var_str->parse(hex2bin('0964757061206a657a61')), 'dupa jeza');
is(var_bytes->parse(hex2bin('0964757061206a657a61')), 'dupa jeza');

done_testing;

