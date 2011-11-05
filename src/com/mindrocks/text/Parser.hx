package com.mindrocks.text;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using StringTools;
using Lambda;

using com.mindrocks.macros.LazyMacro;

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

  public static function fail<T>(error : String) : Void -> Parser <T> return
    (function (input) return Failure(error)).lazy()

  public static function success<T>(v : T) : Void -> Parser <T> return
    (function (input) return Success(v, input)).lazy()

  public static function identity<T>(p : Void -> Parser<T>) : Void -> Parser <T> return p

  public static function andWith < T, U, V > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>, f : T -> U -> V) : Void -> Parser <V> return
    (function (input) return {
      switch (p1()(input)) {
        case Success(m1, r) :
          switch (p2()(r)) {
            case Success(m2, r) : Success(f(m1, m2), r);
            case Failure(err) : Failure(err);
          }
        case Failure(err) : Failure(err);
      }
    }).lazy()

  inline public static function and < T, U > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>) : Void -> Parser < Tuple2 < T, U >> return
    andWith(p1, p2, Tuples.t2)

  public static function _and < T, U > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>) : Void -> Parser < U > return
    andWith(p1, p2, function (_, b) return b)

  public static function and_ < T, U > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>) : Void -> Parser < T > return
    andWith(p1, p2, function (a, _) return a)

  // aka flatmap
  public static function andThen < T, U > (p1 : Void -> Parser<T>, fp2 : T -> (Void -> Parser<U>)) : Void -> Parser < U > return
    (function (input) return {
        switch (p1()(input)) {
          case Success(m, r): fp2(m)()(r);
          case Failure(err): Failure(err);
        }
      }
    ).lazy()

  // map
  public static function then < T, U > (p1 : Void -> Parser<T>, f : T -> U) : Void -> Parser < U > return
    (function (input) return {
      switch (p1()(input)) {
        case Success(m, r): Success(f(m), r);
        case Failure(err): Failure(err);
      }
    }).lazy()

  public static function filter<T>(p : Void -> Parser<T>, pred : T -> Bool) : Void -> Parser <T> return
    andThen(p, function (x) return pred(x) ? success(x) : fail("not matched"))
  
  public static function or < T > (p1 : Void -> Parser<T>, p2 : Void -> Parser<T>) : Void -> Parser < T > return
    (function (input) return {
      switch (p1()(input)) {
        case Success(m, r) : Success(m, r);
        case Failure(err) : p2()(input);
      }
    }).lazy()
    
  public static function ors<T>(ps : Array<Void -> Parser<T>>) : Void -> Parser<T> return
    ps.fold(function (p, accp) return or(accp, p), fail("none match"))
    
  /*
   * 0..n
   */
  public static function many < T > (p1 : Void -> Parser<T>) : Void -> Parser < Array<T> > return
    (function (input) return {
      var parser = p1();
      var arr = [];
      var matches = true;
      while (matches) {
        switch (parser(input)) {
          case Success(m, r): arr.push(m); input = r;
          case Failure(_): matches = false;
        }
      }
      Success(arr, input);
    }).lazy()

  /*
   * 1..n
   */
  public static function oneMany < T > (p1 : Void -> Parser<T>) : Void -> Parser < Array<T> > return
    filter(many(p1), function (arr) return arr.length>0)

  /*
   * 0..n
   */
  public static function rep1sep < T > (p1 : Void -> Parser<T>, sep : Void -> Parser<Dynamic> ) : Void -> Parser < Array<T> > return    
    then(and(p1, many(_and(sep, p1))), function (t) return { t.b.insert(0, t.a); t.b;}) /* Optimize that! */

  /*
   * 0..n
   */
  public static function repsep < T > (p1 : Void -> Parser<T>, sep : Void -> Parser<Dynamic> ) : Void -> Parser < Array<T> > return
    or(rep1sep(p1, sep), success([]))

  /*
   * 0..1
   */
  public static function option < T > (p1 : Void -> Parser<T>) : Void -> Parser < Option<T> > return
    (function (input) return {
      switch (p1()(input)) {
        case Failure(err) : Success(None, input);
        case Success(m, r) : Success(Some(m), r);
      }
    }).lazy()

  public static function trace<T>(p : Void -> Parser<T>, f : T -> String) : Void -> Parser<T> return
    then(p, function (x) return { trace(f(x)); x;} )

  public static function identifier(x : String) : Void -> Parser<String> return
    (function (input : String) return {
      if (input.startsWith(x)) {
        var rest = input.substr(x.length);
        Success(x, rest);
      } else {
        Failure(x + " expected and not found");
      }
    }).lazy()

  public static function regex(r : EReg) : Void -> Parser<String> return
    (function (input : String) return {
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
    }).lazy()

  public static function withError<T>(p : Parser<T>, f : String -> String ) : Void -> Parser<T> return  
    (function (input : String) return {
      var r = p(input);
      switch(r) {
        case Failure(err): Failure(f(err));
        default: r;
      }
    }).lazy()
  
}
