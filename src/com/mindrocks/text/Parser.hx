package com.mindrocks.text;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

// using StringTools;
using Lambda;

using com.mindrocks.macros.LazyMacro;

/**
 * ...
 * @author sledorze
 */

typedef Reader = {
  content : String,
  offset : Int,
  memo : Memo
}

typedef Memo = {
  memoEntry : Hash<MemoEntry>,
}

enum MemoEntry {
  Parsed(ans : ParseResult<Dynamic>);
}

typedef MemoKey = String

class MemoObj {
  inline public static function result<T>(m : MemoEntry) : ParseResult<T> {
    return 
      switch (m) {
        case Parsed(ans) : untyped ans;
      }
  }
  
  inline public static function forKey(m : Memo, key : MemoKey) : Option<MemoEntry> {
    var value = m.memoEntry.get(key);
    if (value == null) { // TODO: toOption()
      return None;
    } else {
      return Some(value);
    }
  }
}

class ReaderObj {
  
  inline public static function position(r : Input) : Int return
    r.offset
  
  inline public static function reader(str : String) : Input return {
    content : str,
    offset : 0,
    memo : {
      memoEntry : new Hash<MemoEntry>()
    }
  }
  
  inline public static function take(r : Input, len : Int) : String {
    return r.content.substr(r.offset, len);
  }
  
  inline public static function drop(r : Input, len : Int) : Input {
    return {
      content : r.content,
      offset : r.offset + len,
      memo  : r.memo
    };
  }
  
  inline public static function startsWith(r : Input, x : String) : Bool {
    return take(r, x.length) == x;
  }
  
  inline public static function matchedBy(r : Input, e : EReg) : Bool { // this is deadly unfortunate that RegEx don't support offset and first char maching constraint..
    return e.match(rest(r));
  }
  
  inline static function rest(r : Input) : String {
    if (r.offset == 0) {
      return r.content;
    } else {
      return r.content.substr(r.offset);
    }
  }
}

class FailureObj {
  public static function newStack(failure : FailureMsg) : FailureStack {
    var newStack = FailureStack.nil();
    return newStack.cons(failure);
  }
  public static function errorAt(msg : String, pos : Input) : FailureMsg {
    return {
      msg : msg,
      pos : pos.offset      
    };
  }
  public static function report(stack : FailureStack, msg : FailureMsg) : FailureStack {
    return stack.cons(msg);
  }
}

using com.mindrocks.text.Parser; 


typedef Input = Reader
typedef FailureStack = haxe.data.collections.List<FailureMsg>
typedef FailureMsg = {
  msg : String,
  pos : Int
}

enum ParseResult<T> {
  Success(match : T, rest : Input);
  Failure(errorStack : FailureStack);
}
typedef Parser<T> = Input -> ParseResult<T>


class Parsers {

  static var _parserUid = 0;
  static function parserUid() {
    return ++_parserUid;  
  }
  
  public static function memo<T>(p : Void -> Parser<T>) : Void -> Parser<T> {
    return ({
      // generates an uid for this parser.
      var uidPrefix = parserUid()+"@";
      var _p1 = p().lazy();
      function (input :Input) {
        var memoKey = uidPrefix + input.position();
     
        switch (input.memo.forKey(memoKey)) {
          case None:
            var res = _p1()(input);
            input.memo.memoEntry.set(memoKey, Parsed(res));
            return res;
          case Some(res):
            return res.result();
        }
      };
    }).lazy();    
  }
  
  public static function fail<T>(error : String) : Void -> Parser <T> return
    (function (input :Input) return Failure("error".errorAt(input).newStack())).lazy()

  public static function success<T>(v : T) : Void -> Parser <T> return
    (function (input) return Success(v, input)).lazy()

  public static function identity<T>(p : Void -> Parser<T>) : Void -> Parser <T> return p

  public static function andWith < T, U, V > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>, f : T -> U -> V) : Void -> Parser <V> return
    ({
      var _p1 = p1().lazy();
      var _p2 = p2().lazy();
      function (input)
        switch (_p1()(input)) {
          case Success(m1, r) :
            switch (_p2()(r)) {
              case Success(m2, r) : return Success(f(m1, m2), r);
              case Failure(err) : return Failure(err);
            }
          case Failure(err) : return Failure(err);
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
    ( {
      var _p1 = p1().lazy();
      function (input)
        switch (_p1()(input)) {
          case Success(m, r): return fp2(m)()(r);
          case Failure(err): return Failure(err);
        }     
    }).lazy()

  // map
  public static function then < T, U > (p1 : Void -> Parser<T>, f : T -> U) : Void -> Parser < U > return
    ({
      var _p1 = p1().lazy();
      function (input)
        switch (_p1()(input)) {
          case Success(m, r): return Success(f(m), r);
          case Failure(err): return Failure(err);
        }
    }).lazy()

  public static function filter<T>(p : Void -> Parser<T>, pred : T -> Bool) : Void -> Parser <T> return
    andThen(p, function (x) return pred(x) ? success(x) : fail("not matched"))
  
  public static function or < T > (p1 : Void -> Parser<T>, p2 : Void -> Parser<T>) : Void -> Parser < T > return
    ({
      var _p1 = p1().lazy();
      var _p2 = p2().lazy();
      function (input) {
        var res = _p1()(input);
        switch (res) {
          case Success(_, _) : return res;
          case Failure(err) : return _p2()(input);
        };
      }
    }).lazy()
    
  public static function ors<T>(ps : Array<Void -> Parser<T>>) : Void -> Parser<T> return
    ps.fold(function (p, accp) return or(accp, p), fail("none match"))
    
  /*
   * 0..n
   */
  public static function many < T > (p1 : Void -> Parser<T>) : Void -> Parser < Array<T> > return
    ( {
      var _p1 = p1().lazy();
      function (input) {
        var parser = _p1();
        var arr = [];
        var matches = true;
        while (matches) {
          switch (parser(input)) {
            case Success(m, r): arr.push(m); input = r;
            case Failure(_): matches = false;
          }
        }
        return Success(arr, input);
      }
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
    then(and(p1, many(_and(sep, p1))), function (t) { t.b.insert(0, t.a); return t.b;}) /* Optimize that! */

  /*
   * 0..n
   */
  public static function repsep < T > (p1 : Void -> Parser<T>, sep : Void -> Parser<Dynamic> ) : Void -> Parser < Array<T> > return
    or(rep1sep(p1, sep), success([]))

  /*
   * 0..1
   */
  public static function option < T > (p1 : Void -> Parser<T>) : Void -> Parser < Option<T> > return
    ( {
      var _p1 = p1().lazy();
      function (input)
        switch (_p1()(input)) {
          case Failure(_) : return Success(None, input);
          case Success(m, r) : return Success(Some(m), r);
        }
    }).lazy()

  public static function trace<T>(p : Void -> Parser<T>, f : T -> String) : Void -> Parser<T> return
    then(p, function (x) { trace(f(x)); return x;} )

  public static function identifier(x : String) : Void -> Parser<String> return
    (function (input : Input)
      if (input.startsWith(x)) {
        return Success(x, input.drop(x.length));
      } else {
        return Failure((x + " expected and not found").errorAt(input).newStack());
      }
    ).lazy()

  public static function regexParser(r : EReg) : Void -> Parser<String> return
    (function (input : Input) return
      if (input.matchedBy(r)) {
        var pos = r.matchedPos();
        if (pos.pos == 0) {
          Success(input.take(pos.len), input.drop(pos.len));
        } else {
          Failure((r + " not matched at beginning").errorAt(input).newStack());
        }
      } else {
        Failure((r + " not matched").errorAt(input).newStack());
      }
    ).lazy()

  public static function withError<T>(p : Parser<T>, f : String -> String ) : Void -> Parser<T> return  
    (function (input : Input) {
      var r = p(input);
      switch(r) {
        case Failure(err): return Failure(err.report((f(err.head.msg)).errorAt(input)));
        default: return r;
      }
    }).lazy()
  
}
