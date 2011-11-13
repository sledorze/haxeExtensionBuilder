package com.mindrocks.text;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;
//import Prelude;
// using PreludeExtensions;

// using StringTools;
using Lambda;
import haxe.data.collections.List;
using haxe.functional.FoldableExtensions;


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
  memoEntries : Hash<MemoEntry>,
  recursionHeads: Hash<Head>, // key: position (string rep)
  lrStack : List<LR>
}

enum MemoEntry {
  MemoParsed(ans : ParseResult<Dynamic>);
  MemoLR(lr : LR);
}

typedef MemoKey = String

class MemoObj {
  
  inline public static function updateCacheAndGet(r : Reader, genKey : Int -> String, entry : MemoEntry) {
    var key = genKey(r.offset);
    r.memo.memoEntries.set(key, entry);    
    return entry;
  }
  public inline static function getFromCache(r : Reader, genKey : Int -> String) : Option<MemoEntry> {
    var key = genKey(r.offset);
    var res = r.memo.memoEntries.get(key);
    return res == null?None: Some(res);
  }

  public inline static function getRecursionHead(r : Reader) : Option<Head> {
    var res = r.memo.recursionHeads.get(r.offset + "");
    return res == null?None: Some(res);
  }
  
  public inline static function setRecursionHead(r : Reader, head : Head) {
    r.memo.recursionHeads.set(r.offset + "", head);
  }

  public inline static function removeRecursionHead(r : Reader) {
    r.memo.recursionHeads.remove(r.offset + "");
  }
  
  public static function posFromResult<T>(p : ParseResult<T>) : Input
    switch (p) {
      case Success(_, rest) : return rest;
      case Failure(_, rest) : return rest;
    }
  
  inline public static function result<T>(m : MemoEntry) : ParseResult<T> {
    return 
      switch (m) {
        case MemoParsed(ans) : untyped ans;
        case MemoLR(lr):  untyped lr.head;
      }
  }
  
  inline public static function forKey(m : Memo, key : MemoKey) : Option<MemoEntry> {
    var value = m.memoEntries.get(key);
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
      memoEntries : new Hash<MemoEntry>(),
      recursionHeads: new Hash<Head>(),
      lrStack : List.nil()
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
  Failure(errorStack : FailureStack, rest : Input);
}

typedef Parser<T> = Input -> ParseResult<T>

/*
class PackRat<T> {
  public static function mkParser<T>(p : Void -> Parser<T>) return new PackRat(p)
  
  var parser : Void -> Parser<T>;
  public function new(p : Void -> Parser<T>) {    
    parser = p;
  }
  inline public function parse(input : Input) return parser()(input)
}
*/

typedef LR = {
  seed: ParseResult<Dynamic>,
  rule: Void -> Parser<Dynamic>,
  head: Option<Head>
}

typedef Head = {
  headParser: Parser<Dynamic>,
  involvedSet: List<Parser<Dynamic>>,
  evalSet: List<Parser<Dynamic>>
}

class Parsers {

  public static function mkLR<T>(seed: ParseResult<Dynamic>, rule: Void -> Parser<T>, head: Option<Head>) : LR return {
    seed: seed,
    rule: untyped rule,
    head: head
  }
  
  public static function mkHead<T>(p: Parser<T>) : Head return
    {
      headParser: untyped p,
      involvedSet: List.nil(),
      evalSet: List.nil()
    }
  
  public static function getPos(lr : LR) : Input return 
    switch(lr.seed) {
      case Success(_, rest): rest;
      case Failure(_, rest): rest;
    }

  public static function getHead<T>(hd : Head) : Parser<T> return 
    untyped hd.headParser
    
  static var _parserUid = 0;
  static function parserUid() {
    return ++_parserUid;  
  }
  
  
  static function lrAnswer<T>(p: Void -> Parser<T>, genKey : Int -> String, input: Reader, growable: LR): ParseResult<T> {
    switch (growable.head) {
      case None: throw "lrAnswer with no head!!";
      case Some(head): 
        if(head.getHead() != p()) /*not head rule, so not growing*/
          return untyped growable.seed;
        else {
          input.updateCacheAndGet(genKey, MemoParsed(growable.seed));
          switch (growable.seed) {
            case Failure(_, _) : return untyped growable.seed;
            case Success(_, _) : return untyped grow(p, genKey, input, head); /*growing*/ 
          }
        }
    }
  }
  
  static function recall<T>(p : Void -> Parser<T>, genKey : Int -> String, input : Reader) : Option<MemoEntry> {
    var cached = input.getFromCache(genKey);
    switch (input.getRecursionHead()) {
      case None:
        trace("none");
        return cached;
      case Some(head):
        trace("head");
        if (cached == None && !(head.involvedSet.cons(head.headParser).contains(p()))) {
          trace("yop");
          return Some(MemoParsed(Failure("dummy ".errorAt(input).newStack(), input)));
        }
          
        if (head.evalSet.contains(p())) {
          trace("found");
          head.evalSet = head.evalSet.filter(function (x) return x != p());
          
          var memo = MemoParsed(p()(input));          
          input.updateCacheAndGet(genKey, memo);
          cached = Some(memo);
        }
        return cached;
    }
  }
  
  static function setupLR(p: Void -> Parser<Dynamic>, input: Reader, recDetect: LR) {
    if (recDetect.head == None)
      recDetect.head = Some(p().mkHead());
    
    var stack = input.memo.lrStack;
    stack.takeWhile(function (lr) return lr.rule() != p()).map(function (x) {
      x.head = recDetect.head;
      switch (recDetect.head) {
        case Some(h):  h.involvedSet.cons(x.rule());
        default:
      }
    });    
  }
  
  static function grow<T>(p: Void -> Parser<T>, genKey : Int -> String, rest: Reader, head: Head): ParseResult<T> {
    //store the head into the recursionHeads
    rest.setRecursionHead(head);
    var oldRes =
      switch (rest.getFromCache(genKey).get()) {
        case MemoParsed(ans): ans;
        default : throw "impossible match";
      };
      
    //resetting the evalSet of the head of the recursion at each beginning of growth
    
    head.evalSet = head.involvedSet;
    var res = p()(rest);
    switch (res) {
      case Success(_,_) :
        if(oldRes.posFromResult().offset < res.posFromResult().offset ) {
          rest.updateCacheAndGet(genKey, MemoParsed(res));
          return grow(p, genKey, rest, head);
        } else {
          //we're done with growing, we can remove data from recursion head
          rest.removeRecursionHead();
          switch (rest.getFromCache(genKey).get()) {
            case MemoParsed(ans): return untyped ans;
            default: throw "impossible match";
          }
        }
      default :
        rest.removeRecursionHead();
      /*rest.updateCacheAndGet(p, MemoEntry(Right(f)));*/
        return untyped oldRes;
    }
  }
  
  public static function memo<T>(_p : Void -> Parser<T>) : Void -> Parser<T> {
    return ({
      // generates an uid for this parser.
      var uid = parserUid();
      function genKey(pos : Int) return uid+"@"+pos;
      var _p1 = _p().lazy();
      function (input :Input) {
        
        switch (recall(_p1, genKey, input)) {
          case None :
          //  trace("none");
            var base = Failure("Base Failure".errorAt(input).newStack(), input).mkLR(_p1, None);
            
            input.memo.lrStack  = input.memo.lrStack.cons(base);
            input.updateCacheAndGet(genKey, MemoLR(base));
            
            var res = _p1()(input);
            
            input.memo.lrStack  = input.memo.lrStack.tail;
            
            switch (base.head) {
              case None:
                input.updateCacheAndGet(genKey, MemoParsed(res));
                return res;
              case Some(_):
                base.seed = res;
                return lrAnswer(_p1, genKey, input, base);
            }
            
          case Some(mEntry):
            trace("entry");
            
            switch(mEntry) {
              case  MemoLR(recDetect):
                setupLR(_p1, input, recDetect);
                return untyped recDetect.seed;
              case  MemoParsed(ans):
                return untyped ans;
            }
        }
        
      };
    }).lazy();
  }
  
  public static function fail<T>(error : String) : Void -> Parser <T> return
  (function (input :Input) return Failure("error".errorAt(input).newStack(), input)).lazy()

  public static function success<T>(v : T) : Void -> Parser <T> return
    (function (input) return Success(v, input)).lazy()

  public static function identity<T>(p : Void -> Parser<T>) : Void -> Parser <T> return p

  public static function andWith < T, U, V > (p1 : Void -> Parser<T>, p2 : Void -> Parser<U>, f : T -> U -> V) : Void -> Parser <V> return
    ({
      var _p1 = p1().lazy();
      var _p2 = p2().lazy();
      function (input) {
        var res = _p1()(input);
        switch (res) {
          case Success(m1, r) :
            var res = _p2()(r);
            switch (res) {
              case Success(m2, r) : return Success(f(m1, m2), r);
              case Failure(err, r): return Failure(err, r);
            }
          case Failure(err, r): return Failure(err, r);
        }
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
      function (input) {
        var res = _p1()(input);
        switch (res) {
          case Success(m, r): return fp2(m)()(r);
          case Failure(err, r): return Failure(err, r);
        }     
      }
    }).lazy()

  // map
  public static function then < T, U > (p1 : Void -> Parser<T>, f : T -> U) : Void -> Parser < U > return
    ({
      var _p1 = p1().lazy();
      function (input) {
        var res = _p1()(input);
        switch (res) {
          case Success(m, r): return Success(f(m), r);
          case Failure(err, r): return Failure(err, r);
        };
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
          case Failure(_, _) : return _p2()(input);
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
            case Failure(_, _): matches = false;
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
        return Failure((x + " expected and not found").errorAt(input).newStack(), input);
      }
    ).lazy()

  public static function regexParser(r : EReg) : Void -> Parser<String> return
    (function (input : Input) return
      if (input.matchedBy(r)) {
        var pos = r.matchedPos();
        if (pos.pos == 0) {
          Success(input.take(pos.len), input.drop(pos.len));
        } else {
          Failure((r + " not matched at beginning").errorAt(input).newStack(), input);
        }
      } else {
        Failure((r + " not matched").errorAt(input).newStack(), input);
      }
    ).lazy()

  public static function withError<T>(p : Parser<T>, f : String -> String ) : Void -> Parser<T> return  
    (function (input : Input) {
      var r = p(input);
      switch(r) {
        case Failure(err, input): return Failure(err.report((f(err.head.msg)).errorAt(input)), input);
        default: return r;
      }
    }).lazy()
  
}
