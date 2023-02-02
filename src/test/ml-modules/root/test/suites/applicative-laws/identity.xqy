xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: pure id <*>  x = x :)

let $id := function($a){ $a }
for $parser in ($pxq:item, pxq:char("a"))
for $input  in ("abc", "", "@")
return 
  test:assert-equal(
    pxq:parse(pxq:pure($id) => pxq:appl($parser), $input),
    pxq:parse($parser, $input)
  ) 