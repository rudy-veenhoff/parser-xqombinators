xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: px >>= return  = px :)

for $px    in ( $pxq:item,  pxq:char("a") )
for $input in ("abc", "123")
return test:assert-equal(
  ($px => pxq:bind(pxq:return#1))($input),
  $px($input)
)
