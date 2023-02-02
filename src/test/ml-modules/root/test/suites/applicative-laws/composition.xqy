xquery version '1.0-ml';

import module namespace test = 'http://marklogic.com/test' at '/test/test-helper.xqy';
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

(: x <*> ( y <*> z ) = ( pure (.) <*> x <*> y) <*> z

	Some type arithmetic is needed to construct the tests:
	as (<*>) :: f (a->b) -> f a -> f b one concludes:
	x <*> ( y <*> z ) becomes f (b -> c) -> ( f (a -> b) -> f b )
	Hence, one can use
		x :: Parser (xs:int -> xs:string)
		y :: Parser (xs:string -> xs:int)
		z :: Parser xs:string
 :)

let $x := pxq:pure(xs:string#1)
let $y := pxq:pure(xs:int#1)
let $z := $pxq:item
let $input  := "123"
return test:assert-equal(
	pxq:appl($x, pxq:appl($y, $z))($input),
  ((pxq:pure(function($f, $g){function($x){$f($g($x))}}) => pxq:appl($x) => pxq:appl($y)) => pxq:appl($z))($input)
)
