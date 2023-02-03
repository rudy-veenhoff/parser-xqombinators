xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: return x >>= f = f x :)

for $f in (function($a){ $pxq:item }, function($a){ pxq:char($a) })
for $x in ("a", "b")
for $input in ("abc", "123")
return test:assert-equal(
  (pxq:return($x) => pxq:bind($f))($input),
  $f($x)($input)
)