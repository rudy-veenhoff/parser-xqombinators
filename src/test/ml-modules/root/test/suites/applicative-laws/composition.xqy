xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: x <*> ( y <*> z ) = ( pure (.) <*> x <*> y) <*> z 
	Some type arithmetic is needed to construct the tests:
	as (<*>) :: f (a->b) -> f a -> f b one concludes:
	x <*> ( y <*> z )  becomes f (b -> c) -> ( f (a -> b) -> f b )
 :)

let $x := pxq:pure(xs:string#1)
let $y := pxq:pure(xs:int#1)
let $z := $pxq:item
let $input  := "123"
return (
	pxq:appl($x, pxq:appl($y, $z))($input),
  ((pxq:pure(function($f, $g){function($x){$f($g($x))}}) => pxq:appl($x) => pxq:appl($y)) => pxq:appl($z))($input)
)
