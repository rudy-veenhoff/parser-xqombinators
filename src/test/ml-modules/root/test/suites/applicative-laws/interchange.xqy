xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: x <*> pure y = pure (\g -> g y) <*> x :)

for $x in (pxq:pure(fn:string#1), pxq:pure(function($a){ 1 }))
for $y in ("123", 123, "", json:array())
for $input in ("abc", "", "@")
return test:assert-equal(
  pxq:appl($x, pxq:pure($y))($input),
  (pxq:pure(function($g){$g($y)}) => pxq:appl($x))($input)
)