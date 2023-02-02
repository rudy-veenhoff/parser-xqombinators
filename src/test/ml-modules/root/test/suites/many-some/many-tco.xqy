xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: Tests to confirm that pxq:many is tail-call optimized, i.e. does not throw
   a stackoverflow error :)

let $parser := pxq:char("a")
let $long-string := fn:string-join((1 to 10000) ! "a")
return test:assert-exists(pxq:parse(
 pxq:many(fn:concat#2, "", $parser),
 $long-string
))