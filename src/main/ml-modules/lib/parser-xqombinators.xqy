xquery version "1.0-ml";

module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators";

declare option xdmp:mapping "false";

declare variable $failure := json:array();

declare function pxq:parse(
    $parser as function(xs:string) as json:array,
    $string as xs:string
) as json:array
{
  $parser($string)
};

declare function pxq:is-parse-error(
  $parse-result as json:array
) as xs:boolean
{
  json:array-size($parse-result) eq 0
};

declare variable $item as function(xs:string) as json:array :=
  function($input as xs:string){
    if ($input eq "")
    then $failure
    else
      json:array()
      => json:array-with(json:to-array(fn:substring($input, 1, 1)))
      => json:array-with(fn:substring($input, 2))
  }
;

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)
(:                   TYPECLASSES                                              :)
(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:--------------FUNCTOR--------------FUNCTOR--------------FUNCTOR-------------:)

(: fmap : (a -> b) -> Parser a -> Parser b:)
declare function pxq:fmap(
  $f      as function(*),
  $parser as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){
    let $parse-result := pxq:parse($parser, $input)
    return
      if (pxq:is-parse-error($parse-result))
      then $failure
      else json:to-array((
        pxq:to-array(pxq:curry($f)(json:array-values($parse-result[1]))),
        $parse-result[2]
      ))
  }
};

(: Same as json:to-array#2, except it creates nested arrays when $items is of
   type json:array :)
declare function pxq:to-array(
  $item as item()*
) as json:array
{
  json:array() => json:array-with($item)
};

declare function pxq:curry(
  $f as function(*)
) as function(item()*) as item()*
{
  switch(fn:function-arity($f))
  case 0  return fn:error(
                  xs:QName("pxq:curry"),
                  "Cannot curry a function with arity 0"
                )
  case 1  return $f
  (: Ugly, but does the trick :)
  default return
    xdmp:value(
      "function($a){ pxq:curry($f($a "
      || fn:string-join(
          fn:map(function($n){", ?"}, (1 to fn:function-arity($f) - 1))
      ) || "))}"
    )
};


(:-------------Applicative------------Applicative------------Applicative------:)

(: pure :: a -> Parser a :)
declare function pxq:pure(
  $v as item()
) as function(xs:string) as json:array
{
  function($input as xs:string){
    json:array()
    => json:array-with(json:array() => json:array-with($v))
    => json:array-with($input)
  }
};

declare variable $pure := pxq:pure#1;

declare function pxq:appl(
  $pg as function(xs:string) as json:array,
  $px as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){
    let $parse-result := pxq:parse($pg, $input)
    return
      if (pxq:is-parse-error($parse-result))
      then $parse-result
      else pxq:parse(
            pxq:fmap(json:array-values($parse-result[1]), $px),
            $parse-result[2]
          )
  }
};

(:-------------Monad------------Monad------------Monad------------------------:)

declare function pxq:bind(
  $p as function(xs:string) as json:array,
  $f as function(item())    as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){
    let $parse-result := pxq:parse($p, $input)
    return
      if (pxq:is-parse-error($parse-result))
      then $parse-result
      else pxq:parse(
        pxq:curry($f)(json:array-values($parse-result[1])),
        $parse-result[2]
      )
  }
};

(:-------------Alternative------------Alternative------------Alternative------:)

declare function pxq:choice(
  $p as function(xs:string) as json:array,
  $q as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){
    let $parse-result := pxq:parse($p, $input)
    return
      if   (pxq:is-parse-error($parse-result))
      then pxq:parse($q, $input)
      else $parse-result
  }
};

declare variable $empty as function(xs:string) as json:array :=
  function($input as xs:string){
    $failure
  }
;

declare function pxq:choices(
  $ps as (function(xs:string) as json:array)+
) as function(xs:string) as json:array
{
  if (fn:count($ps) eq 1)
  then $empty
  else fn:fold-left(
    function($a, $p){ pxq:choice($a, $p) },
    fn:head($ps),
    fn:tail($ps)
  )
};

declare function pxq:many(
  $f    as function(item(), item()) as item()*,
  $zero as item()*,
  $p    as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){
    let $parse-result := pxq:parse(pxq:some($f, $zero, $p), $input)
    return
      if   (pxq:is-parse-error($parse-result))
      then pxq:parse($pure($zero), $input)
      else $parse-result
  }
};

declare function pxq:some(
  $f      as function(item(), item()) as item()*,
  $zero   as item()*,
  $parser as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  function($input as xs:string){ pxq:_some($parser, $f, $zero, $input) }
};

(: This function is tail call optimized using acculated parameters,
   fn:fold-left is used to fill the accumulator. :)
declare function pxq:_some(
  $parser as function(xs:string) as json:array,
  $f      as function(item(), item()) as item()*,
  $acc    as item()*,
  $input  as xs:string
) as json:array
{
  let $parse-result := pxq:parse($parser, $input)
  return
      if (pxq:is-parse-error($parse-result) )
      then json:to-array((pxq:to-array($acc), $input))
      else if ($parse-result[2] eq $input) (: Just for safety :)
      then fn:error(xs:QName("pxq_some"), "Infinite loop!") 
      else pxq:_some(
            $parser,
            $f,
            (fn:fold-left($f, $acc, json:array-values($parse-result[1]))),
            $parse-result[2]
      )
};

declare function pxq:sat(
  $pred as function(xs:string) as xs:boolean
) as function(xs:string) as json:array
{
  pxq:bind(
    $item,
    function($char){
      if ($pred($char))
      then $pure($char)
      else $empty
    }
  )
};

declare function pxq:option(
  $default as item(),
  $p       as function(xs:string) as json:array
) as function(xs:string) as json:array
{
  pxq:choice($p, $pure($default))
};

declare function pxq:char(
  $char as xs:string
) as function(xs:string) as json:array
{
  pxq:sat(function($x){($x eq $char )})
};