# parser-xqombinators
A Parser Combinator Library for XQuery. Contains combinators for choice(s),
sequences, zero-or-one, zero-or-more, one-or-more (called respectively optional, many and some).

## The Parser Type in XQuery
In a language with a richer type system, a simple type for a Parser
could be `String -> [(a, String)]`. For this XQuery
implementation, the type `function(xs:string) as json:array` has been chosen.
As sequences cannot be nested in XQuery, the convention was adopted to model
the tuple `(a, String)` as a `json:array` of length 2, where the first element
is a list (i.e. a `json:array`) and the second one is a string.
The empty array, `[]`, was chosen to represent failure.

## Examples
Using the pxq library, a parser that parsers the word '_Hello_' can be implemented as follows:
```xquery
import module namespace pxq = "https://github.com/rudy-veenhoff/parser-xqombinators"
 at "/parser-xqombinators.xqy";

declare function local:string(
  $word as xs:string
) as function(xs:string) as json:array
{
  if ($word eq "")
  then pxq:pure("")
  else pxq:pure(fn:concat#2)
    => pxq:appl(pxq:char(fn:substring($word, 1, 1)))
    => pxq:appl(local:string(fn:substring($word, 2)))

};

pxq:parse(local:string("Hello"), "Hello World")
```

As a more realistic example, a basic CSV parser is also given:
```xquery
xquery version "1.0-ml";

import module namespace csv = "https://github.com/rudy-veenhoff/csv"
  at "/csv-parser.xqy";

csv:parse('Year,Make,Model,Description,Price
1997,Ford,E350,"ac, abs, moon",3000.00
1999,Chevy,"Venture ""Extended Edition""","",4900.00
1999,Chevy,"Venture ""Extended Edition, Very Large""","",5000.00
1996,Jeep,Grand Cherokee,"MUST SELL!
air, moon roof, loaded",4799.00')
```
Returns
```json
[
  {
    "Year": "1997",
    "Make": "Ford",
    "Model": "E350",
    "Description": "\"ac, abs, moon\"",
    "Price": "3000.00"
  },
  {
    "Year": "1999",
    "Make": "Chevy",
    "Model": "\"Venture \"\"Extended Edition\"\"\"",
    "Description": "\"\"",
    "Price": "4900.00"
  },
  {
    "Year": "1999",
    "Make": "Chevy",
    "Model": "\"Venture \"\"Extended Edition, Very Large\"\"\"",
    "Description": "\"\"",
    "Price": "5000.00"
  },
  {
    "Year": "1996",
    "Make": "Jeep",
    "Model": "Grand Cherokee",
    "Description": "\"MUST SELL!\nair, moon roof, loaded\"",
    "Price": "4799.00"
  }
]
```




## Useful References
- Hutton, G. (2016). _Programming in Haskell_ (2nd ed). Cambridge University
- Grune D, Jacobs C.F.D. (2008). _Parsing Techniques A Practical Guide_ (2nd ed). Springer Science+Business Media, LLC