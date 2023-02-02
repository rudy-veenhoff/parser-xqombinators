xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: empty <|> x = x :)
for $x in (pxq:char("a"), $pxq:item)
for $input in ("", "abc", "123")
return test:assert-equal(
  pxq:choice($pxq:empty, $x)($input),
  $x($input)
)

;

xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: x <|> empty = x :)
for $x in (pxq:char("a"), $pxq:item)
for $input in ("", "abc", "123")
return test:assert-equal(
  pxq:choice($x, $pxq:empty)($input),
  $x($input)
)
