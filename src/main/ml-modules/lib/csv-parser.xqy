(:
  A CSV parser using parser combinators.
  This library demonstrates how to use the parser combinator library.

  The ABNF for a CSV file (RFC 4180) :

  file = [header CRLF] record *(CRLF record) [CRLF]
  header = name *(COMMA name)
  record = field *(COMMA field)
  name = field
  field = (escaped / non-escaped)
  escaped = DQUOTE *(TEXTDATA / COMMA / CR / LF / 2DQUOTE) DQUOTE
  non-escaped = *TEXTDATA
  COMMA = %x2C
  CR = %x0D ;as per section 6.1 of RFC 2234 [2]
  DQUOTE =  %x22 ;as per section 6.1 of RFC 2234 [2]
  LF = %x0A ;as per section 6.1 of RFC 2234 [2]
  CRLF = CR LF ;as per section 6.1 of RFC 2234 [2]
  TEXTDATA =  %x20-21 / %x23-2B / %x2D-7E
:)
xquery version "1.0-ml";

module namespace csv = "https://github.com/rudy-veenhoff/csv";

import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

declare option xdmp:mapping "false";

(: TEXTDATA =  %x20-21 / %x23-2B / %x2D-7E :)
declare variable $TEXTDATA := pxq:sat(fn:matches(?, "[&#x20;-&#x21;&#x23;-&#x2B;\&#x2D;-&#x7E;]"));

(: CR = %x0D ;as per section 6.1 of RFC 2234 [2] :)
declare variable $CR := pxq:sat(fn:matches(?, "&#x0D;"));

(: LF = %x0A ;as per section 6.1 of RFC 2234 [2] :)
declare variable $LF := pxq:sat(fn:matches(?,"&#x0A;"));

(: CRLF = CR LF ;as per section 6.1 of RFC 2234 [2]
   This parser is a bit more forgiving as to new lines: CRLF = (CR LF) / LF:)
declare variable $CRLF :=
  pxq:choice(
    $pxq:pure(fn:concat#2) => pxq:appl($CR) => pxq:appl($LF),
    $LF
  )
;

(: DQUOTE =  %x22 ;as per section 6.1 of RFC 2234 [2]:)
declare variable $DQUOTE := pxq:sat(fn:matches(?,"&#x22;"));

(: COMMA = %x2C :)
declare variable $COMMA := pxq:sat(fn:matches(?,"&#x2C;"));

(: non-escaped = *TEXTDATA :)
declare variable $non-escaped := pxq:many(fn:concat#2, "", $TEXTDATA);

(: escaped = DQUOTE *(TEXTDATA / COMMA / CR / LF / 2DQUOTE) DQUOTE :)
declare variable $escaped :=
  $pxq:pure(fn:concat#3)
  => pxq:appl($DQUOTE)
  => pxq:appl(pxq:many(fn:concat#2, "", pxq:choices((
      $TEXTDATA,
      $COMMA,
      $CR,
      $LF,
      $pxq:pure(fn:concat#2) => pxq:appl($csv:DQUOTE) => pxq:appl($csv:DQUOTE)
  ))))
  => pxq:appl($DQUOTE)
;

(:  field = (escaped / non-escaped) :)
declare variable $field := pxq:choice($escaped, $non-escaped);

(: name = field :)
declare variable $name := $field;

(: record = field *(COMMA field) :)
(: record :: string -> Parser [string]:)
declare function csv:record()
{
  $pxq:pure(function($a, $b){ fn:fold-left(json:array-with#2, json:array(),($a, csv:get-and-forget($b) ) )})
  => pxq:appl($field)
  => pxq:appl(pxq:many(function($a, $b){ json:array-with($a, $b) }, json:array(), $pxq:pure(function($a, $b){ $b }) => pxq:appl($COMMA) => pxq:appl($field) ))
};

(: Maybe move this functionality to the many and some combinators :)
declare function csv:get-and-forget(
  $array as json:array
) as item()*
{
  (1 to json:array-size($array)) ! json:array-pop($array) => fn:reverse()
};

(: header = name *(COMMA field) :)
(: header :: string -> Parser [String] :)
declare function csv:header()
{
  $pxq:pure(function($a, $b){ fn:fold-left(json:array-with#2, json:to-array(),($a, csv:get-and-forget($b) ))})
  => pxq:appl($field)
  => pxq:appl(pxq:many(function($a, $b){json:array-with($a, $b)}, json:array(), $pxq:pure(function($a, $b){ $b }) => pxq:appl($COMMA) => pxq:appl($field) ))
};

(: file = [header CRLF] record *(CRLF record) [CRLF] :)
declare function csv:file(
) as function(xs:string) as json:array
{
  pxq:pure(
    function($header, $record, $many-records, $optional-crlf){
      (: map over a sequence of json:arrays (=records), folding each one into a json:object :)
      fn:map(function($row){
        fn:fold-left(
          function($a, $n){
            map:with($a, $header[$n], $row[$n])
          }, json:object(),
          (1 to json:array-size($header))
        )
      }, ($record, json:array-values($many-records))
      )
    }
  )
  => pxq:appl(pxq:option("", pxq:pure(function($a, $b){ $a }) => pxq:appl(csv:header()) => pxq:appl($CRLF)))
  => pxq:appl(csv:record())
  => pxq:appl(pxq:many(function($acc, $rec) { json:array-with($acc, $rec)}, json:array(), pxq:pure(function($a, $b){ $b }) => pxq:appl($CRLF) => pxq:appl(csv:record())))
  => pxq:appl(pxq:option(json:array(), $CRLF))
};

declare function csv:parse(
  $csv as xs:string
)
{
  let $parse-result := pxq:parse(csv:file(), $csv)
  return
    if (pxq:is-parse-error($parse-result))
    then fn:error(xs:QName("csv:parser-1"), "Could not parse the csv")
    else if (fn:string-length($parse-result[2]) > 0)
    then fn:error(xs:QName("csv:parser-2"), "Failed to fully parse the csv: " || $parse-result[2])
    else $parse-result[1] => json:array-values()
};