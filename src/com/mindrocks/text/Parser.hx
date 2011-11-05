package com.mindrocks.text;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using StringTools;
using Lambda;

/**
 * ...
 * @author sledorze
 */

enum ParseResult<T> {
  Success(match : T, rest : String);
  Failure(error : String);
}
typedef Input = String
typedef Parser<T> = Input -> ParseResult<T>


class Parsers {

  public static function fail<T>(error : String) : Parser <T> return
    function (input) return Failure(error)

  public static function success<T>(v : T) : Parser <T> return
    function (input) return Success(v, input)

  public static function identity<T>(p : Parser<T>) : Parser <T> return p


  public static function and < T, U > (p1 : Parser<T>, p2 : Parser<U>) : Parser < Tuple2 < T, U >> return
    function (input) return {
      switch (p1(input)) {
        case Success(m1, r) :
          switch (p2(r)) {
            case Success(m2, r) : Success(Tuples.t2(m1, m2), r);
            case Failure(err) : Failure(err);
          }
        case Failure(err) : Failure(err);
      }
    }

  public static function _and < T, U > (p1 : Parser<T>, p2 : Parser<U>) : Parser < U > return
    andThen(and(p1, p2), function (res) return function (input) return Success(res.b, input))

  public static function and_ < T, U > (p1 : Parser<T>, p2 : Parser<U>) : Parser < T > return
    andThen(and(p1, p2), function (res) return function (input) return Success(res.a, input))

  public static function andThen < T, U > (p1 : Parser<T>, fp2 : T -> Parser<U>) : Parser < U > return {    
    function (input) return {
      switch (p1(input)) {
        case Success(m, r): fp2(m)(r);
        case Failure(err): Failure(err);
      }
    }
  }

  public static function then < T, U > (p1 : Parser<T>, f : T -> U) : Parser < U > return {    
    function (input) return {
      switch (p1(input)) {
        case Success(m, r): Success(f(m), r);
        case Failure(err): Failure(err);
      }
    }
  }

  public static function filter<T>(p : Parser<T>, pred : T -> Bool) : Parser <T> return
    andThen(p, function (x) return pred(x) ? success(x) : fail("not matched"))
  
  public static function or < T > (p1 : Parser<T>, p2 : Parser<T>) : Parser < T > return
    function (input) return {
      switch (p1(input)) {
        case Success(m, r) : Success(m, r);
        case Failure(err) : p2(input);
      }
    }
    
    public static function ors<T>(ps : Array<Parser<T>>) : Parser<T> return
      ps.fold(function (p, accp) return or(accp, p), fail("none match"))
    
  /*
   * 0..n
   */
  public static function many < T > (p1 : Parser<T>) : Parser < Array<T> > return {    
    function (input) return {
      var arr = [];
      function internal(input) return {
        switch (p1(input)) {
          case Success(m, r) : arr.push(m); internal(r);
          case Failure(err) : Success(arr, input);
        }
      }
      internal(input);
    }
  }

  /*
   * 1..n
   */
  public static function oneMany < T > (p1 : Parser<T>) : Parser < Array<T> > return
    filter(many(p1), function (arr) return arr.length>0)

  /*
   * 0..n
   */
  public static function rep1sep < T > (p1 : Parser<T>, sep : Parser<Dynamic> ) : Parser < Array<T> > return    
    then(and(p1, many(_and(sep, p1))), function (t) return { t.b.insert(0, t.a); t.b;} ) /* Optimize that! */

  /*
   * 0..n
   */
  public static function repsep < T > (p1 : Parser<T>, sep : Parser<Dynamic> ) : Parser < Array<T> > return
    or(rep1sep(p1, sep), success([]))

  /*
   * 0..1
   */
  public static function option < T > (p1 : Parser<T>) : Parser < Option<T> > return
    function (input) return {
      switch (p1(input)) {
        case Failure(err) : Success(None, input);
        case Success(m, r) : Success(Some(m), r);
      }
    }

  public static function trace<T>(p : Parser<T>, f : T -> String) : Parser<T> return
    then(p, function (x) return { trace(f(x)); x;} )

  public static function identifier(x : String) : Parser<String> return
    function (input : String) return {
      if (input.startsWith(x)) {
        var rest = input.substr(x.length);
        Success(x, rest);
      } else {
        Failure(x + " expected and not found");
      }
  }

  public static function regex(r : EReg) : Parser<String> return
    function (input : String) return {
      if (r.match(input)) {
        var pos = r.matchedPos();
        if (pos.pos == 0) {
          Success(input.substr(0, pos.len), input.substr(pos.len));
        } else {
          Failure(r + " not matched at beginning");
        }
      } else {
        Failure(r + " not matched");
      }
  }

  public static function withError<T>(p : Parser<T>, f : String -> String ) : Parser<T> return  
    function (input : String) return {
      var r = p(input);
      switch(r) {
        case Failure(err): Failure(f(err));
        default: r;
      }
    }
  
}
