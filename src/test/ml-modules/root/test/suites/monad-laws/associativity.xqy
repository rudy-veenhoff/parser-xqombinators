xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: (px >>= f) >>= g = px >>= (\x -> (f x >>= g)) :)
for $px in ($pxq:item, pxq:char("a"), pxq:return("a"))
for $f  in (function($a){$pxq:item}, function($a){pxq:char($a)}, function($a){pxq:return($a)})
for $g  in (function($a){$pxq:item}, function($a){pxq:char($a)}, function($a){pxq:return($a)})
for $input in ("abc", "123", "")
return test:assert-equal(
  (pxq:bind($px, $f) => pxq:bind($g))($input),
  pxq:bind($px, function($x){pxq:bind($f($x), $g)})($input)
)