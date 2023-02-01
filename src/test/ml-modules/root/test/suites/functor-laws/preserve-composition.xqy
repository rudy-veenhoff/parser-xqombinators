xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: fmap (f.g) = fmap f . fmap g :)

declare function local:compose($f,$g){ function($x){$f($g($x))} };

for $f      in (function($a){ $a || "bc"}, function($a){ "b" })
for $g      in (function($a){ $a || "cd"}, function($a){ "d" })
for $parser in ($pxq:item, pxq:char("a"))
for $input  in ("abc", "", "@")
return test:assert-equal(
    pxq:fmap(local:compose($f, $g), ?)($parser)($input),
    local:compose(pxq:fmap($f, ?), pxq:fmap($g, ?))($parser)($input)
)