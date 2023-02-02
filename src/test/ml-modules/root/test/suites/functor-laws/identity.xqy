xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: fmap id = id 
   fmap id :: Parser a -> Parser a:)
let $id := function($a){ $a }
return
    for $parser in ($pxq:item, pxq:char("a"))
    for $input in ("abc", "", "@")
    return test:assert-equal(
        pxq:fmap($id, ?)($pxq:item)($input),
        $id($pxq:item)($input)
    )
