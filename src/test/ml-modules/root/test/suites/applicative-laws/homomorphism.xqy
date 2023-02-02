xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: pure (g x) = pure g <*> pure x :)

for $parser in ($pxq:item, pxq:char("a"))
for $input  in ("abc", "", "@")
for $g in (function($n){ $n + 1 }, function($n){ $n div 5 })
for $x in (-1, 0, 1, 2e2, xs:float("INF"))
return test:assert-equal(
  pxq:parse(pxq:pure($g($x)), $input),
  pxq:parse(pxq:pure($g) => pxq:appl(pxq:pure($x)), $input)
)