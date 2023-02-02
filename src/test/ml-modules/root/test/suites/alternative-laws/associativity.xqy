xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: x <|> ( y <|> z ) = ( x <|>  y ) <|> z  :)

for $x in (pxq:char("a"), $pxq:item, $pxq:empty)
for $y in (pxq:char("a"), $pxq:item, $pxq:empty)
for $z in (pxq:char("a"), $pxq:item, $pxq:empty)
for $input in ("abc", "123", "")
return test:assert-equal(
    pxq:choice($x, pxq:choice($y, $z))($input),
    pxq:choice(pxq:choice($x, $y), $z)($input)
)