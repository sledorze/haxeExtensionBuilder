package com.mindrocks.text;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;


using Lambda;
import haxe.data.collections.List; // reimplement minimal version.

using com.mindrocks.macros.LazyMacro;

/**
 * ...
 * @author sledorze
 */

typedef Input = {
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

class ParserObj {
  inline public static function castType<T, U>(p : Parser<T>) : Parser<U> return 
    untyped p
}

class ResultObj {
  
  inline public static function castType<T, U>(p : ParseResult<T>) : ParseResult<U> return 
    untyped p
  
  public static function posFromResult<T>(p : ParseResult<T>) : Input
    switch (p) {
      case Success(_, rest) : return rest;
      case Failure(_, rest, _) : return rest;
    }
    
  public static function matchFromResult<T>(p : ParseResult<T>) 
    switch (p) {
      case Success(x, _) : return Std.string(x);
      case Failure(_, _, _) : return "";
    }

}
using com.mindrocks.text.Parser; 

class MemoObj {
  
  inline public static function updateCacheAndGet(r : Input, genKey : Int -> String, entry : MemoEntry) {
    var key = genKey(r.offset);
    r.memo.memoEntries.set(key, entry);    
    return entry;
  }
  public inline static function getFromCache(r : Input, genKey : Int -> String) : Option<MemoEntry> {
    var key = genKey(r.offset);
    var res = r.memo.memoEntries.get(key);
    return res == null?None: Some(res);
  }

  public inline static function getRecursionHead(r : Input) : Option<Head> {
    var res = r.memo.recursionHeads.get(r.offset + "");
    return res == null?None: Some(res);
  }
  
  public inline static function setRecursionHead(r : Input, head : Head) {
    r.memo.recursionHeads.set(r.offset + "", head);
  }

  public inline static function removeRecursionHead(r : Input) {
    r.memo.recursionHeads.remove(r.offset + "");
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



typedef FailureStack = haxe.data.collections.List<FailureMsg>
typedef FailureMsg = {
  msg : String,
  pos : Int
}

enum ParseResult<T> {
  Success(match : T, rest : Input);
  Failure(errorStack : FailureStack, rest : Input, isError : Bool);
}

typedef Parser<T> = Input -> ParseResult<T>

typedef LR = {
  seed: ParseResult<Dynamic>,
  rule: Parser<Dynamic>,
  head: Option<Head>
}

typedef Head = {
  headParser: Parser<Dynamic>,
  involvedSet: List<Parser<Dynamic>>,
  evalSet: List<Parser<Dynamic>>
}

class Parsers {

  public static function mkLR<T>(seed: ParseResult<Dynamic>, rule: Parser<T>, head: Option<Head>) : LR return {
    seed: seed,
    rule: rule.castType(),
    head: head
  }
  
  public static function mkHead<T>(p: Parser<T>) : Head return
    {
      headParser: p.castType(),
      involvedSet: List.nil(),
      evalSet: List.nil()
    }
  
  public static function getPos(lr : LR) : Input return 
    switch(lr.seed) {
      case Success(_, rest): rest;
      case Failure(_, rest, _): rest;
    }

  public static function getHead<T>(hd : Head) : Parser<T> return 
    hd.headParser.castType()
    
  static var _parserUid = 0;
  static function parserUid() {
    return ++_parserUid;  
  }
  
  
  static function lrAnswer<T>(p: Parser<T>, genKey : Int -> String, input: Input, growable: LR): ParseResult<T> {
    switch (growable.head) {
      case None: throw "lrAnswer with no head!!";
      case Some(head): 
        if (head.getHead() != p) /*not head rule, so not growing*/{
          //trace(" head.getHead() != p() ");
          return growable.seed.castType();
        } else {
          //trace(" head.getHead() == p() ");
          input.updateCacheAndGet(genKey, MemoParsed(growable.seed));
          switch (growable.seed) {
            case Failure(_, _, _) :
              //trace("failure");
              return growable.seed.castType();
            case Success(_, _) :
              //trace("grow");
              return grow(p, genKey, input, head).castType(); /*growing*/ 
          }
        }
    }
  }
  
  static function recall<T>(p : Parser<T>, genKey : Int -> String, input : Input) : Option<MemoEntry> {
    var cached = input.getFromCache(genKey);
    switch (input.getRecursionHead()) {
      case None: return cached;
      case Some(head):
        if (cached == None && !(head.involvedSet.cons(head.headParser).contains(p))) {
          return Some(MemoParsed(Failure("dummy ".errorAt(input).newStack(), input, false)));
        }          
        if (head.evalSet.contains(p)) {
          head.evalSet = head.evalSet.filter(function (x) return x != p);
          
          var memo = MemoParsed(p(input));
          input.updateCacheAndGet(genKey, memo); // beware; it won't update lrStack !!! Check that !!!
          cached = Some(memo);
        }
        return cached;
    }
  }
  
  static function setupLR(p: Parser<Dynamic>, input: Input, recDetect: LR) {
    if (recDetect.head == None)
      recDetect.head = Some(p.mkHead());
    
    var stack = input.memo.lrStack;

    var h = recDetect.head.get(); // valid (see above)
    while (stack.head.rule != p) {
      var head = stack.head;
      head.head = recDetect.head;
      h.involvedSet = h.involvedSet.cons(head.rule);
      stack = stack.tail;
    }
/*
    stack.takeWhile(function (lr) return lr.rule != p).map(function (x) {
      x.head = recDetect.head;
      switch (recDetect.head) {
        case Some(h):  h.involvedSet = h.involvedSet.cons(x.rule);
        default:
      }
    });    
    */
  }
  
  static function grow<T>(p: Parser<T>, genKey : Int -> String, rest: Input, head: Head): ParseResult<T> {
    //store the head into the recursionHeads
    rest.setRecursionHead(head);
    var oldRes =
      switch (rest.getFromCache(genKey).get()) {
        case MemoParsed(ans): ans;
        default : throw "impossible match";
      };
      
    //resetting the evalSet of the head of the recursion at each beginning of growth
    
    head.evalSet = head.involvedSet;
    var res = p(rest);
    switch (res) {
      case Success(_, _) :
        //trace("res " + oldRes.matchFromResult() + " " + res.matchFromResult());
        //trace("pos " + oldRes.posFromResult().offset + " " + res.posFromResult().offset);
        
        if (oldRes.posFromResult().offset < res.posFromResult().offset ) {
          //trace("inferior");
          rest.updateCacheAndGet(genKey, MemoParsed(res));
          return grow(p, genKey, rest, head);
        } else {
          //trace("not inferior");
          //we're done with growing, we can remove data from recursion head
          rest.removeRecursionHead();
          switch (rest.getFromCache(genKey).get()) {
            case MemoParsed(ans): return ans.castType();
            default: throw "impossible match";
          }
        }
      default :
        //trace("default");
        rest.removeRecursionHead();
      /*rest.updateCacheAndGet(p, MemoEntry(Right(f)));*/
        return oldRes.castType();
    }
  }
  
  public static function memo<T>(_p : Void -> Parser<T>) : Void -> Parser<T> {
    return ({
      // generates an uid for this parser.
      var uid = parserUid();
      function genKey(pos : Int) return uid+"@"+pos;
      var _p1 = _p().lazy();
      function (input :Input) {
        
        switch (recall(_p1(), genKey, input)) {
          case None :
            var base = Failure("Base Failure".errorAt(input).newStack(), input, false).mkLR(_p1(), None);
            
            input.memo.lrStack  = input.memo.lrStack.cons(base);
            input.updateCacheAndGet(genKey, MemoLR(base));
            //trace("add base failure");
            
            var res = _p1()(input);
            
            //trace("remove base failure");
            input.memo.lrStack = input.memo.lrStack.tail;
            
            switch (base.head) {
              case None:
                //trace("base.head is None");
                input.updateCacheAndGet(genKey, MemoParsed(res));
                return res;
              case Some(_):
                //trace("base.head is Some");
                base.seed = res;
                return lrAnswer(_p1(), genKey, input, base);
            }
            
          case Some(mEntry):            
            switch(mEntry) {
              case  MemoLR(recDetect):
                //trace("MemoLR");
                setupLR(_p1(), input, recDetect);
                return recDetect.seed.castType();
              case  MemoParsed(ans):
                //trace("Parsed " + ans);
                return ans.castType();
            }
        }
        
      };
    }).lazy();
  }
  
  public static function fail<T>(error : String) : Void -> Parser <T> return
    (function (input :Input) return Failure(error.errorAt(input).newStack(), input, false)).lazy()

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
              case Failure(_, _, _): return res.castType();
            }
          case Failure(_, _, _): return res.castType();
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
          case Failure(_, _, _): return res.castType();
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
          case Failure(_, _, _): return res.castType();
        };
      }
    }).lazy()

  public static function filter<T>(p : Void -> Parser<T>, pred : T -> Bool) : Void -> Parser <T> return
    andThen(p, function (x) return pred(x) ? success(x) : fail("not matched"))
  
  public static function commit < T > (p1 : Void -> Parser<T>) : Void -> Parser < T > return
    ( {
      var _p1 = p1().lazy();
      function (input) {        
        var res = p1()(input);
        switch(res) {
          case Success(_, _): return res.castType();
          case Failure(err, rest, isError) : return isError ? res : Failure(err, rest, true);
        }
      }
    }).lazy()
  
  public static function or < T > (p1 : Void -> Parser<T>, p2 : Void -> Parser<T>) : Void -> Parser < T > return
    ({
      var _p1 = p1().lazy();
      var _p2 = p2().lazy();
      function (input) {
        var res = _p1()(input);
        switch (res) {
          case Success(_, _) : return res;
          case Failure(_, _, isError) : return isError ? res.castType() : _p2()(input); // isError means that we commited to a parser that failed; this reports to the top..
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
            case Failure(_, _, _): matches = false;
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
    p1.then(Some).or(success(None))

  public static function trace<T>(p : Void -> Parser<T>, f : T -> String) : Void -> Parser<T> return
    then(p, function (x) { trace(f(x)); return x;} )

  public static function identifier(x : String) : Void -> Parser<String> return
    (function (input : Input)
      if (input.startsWith(x)) {
        return Success(x, input.drop(x.length));
      } else {
        return Failure((x + " expected and not found").errorAt(input).newStack(), input, false);
      }
    ).lazy()

  public static function regexParser(r : EReg) : Void -> Parser<String> return
    (function (input : Input) return
      if (input.matchedBy(r)) {
        var pos = r.matchedPos();
        if (pos.pos == 0) {
          Success(input.take(pos.len), input.drop(pos.len));
        } else {
          Failure((r + "not matched at beginning").errorAt(input).newStack(), input, false);
        }
      } else {
        Failure((r + " not matched").errorAt(input).newStack(), input, false);
      }
    ).lazy()

  public static function withError<T>(p : Void -> Parser<T>, f : String -> String ) : Void -> Parser<T> return  
    ( {
      var _p1 = p().lazy();
      function (input : Input) {
        var r = _p1()(input);
        switch(r) {
          case Failure(err, input, isError): return Failure(err.report((f(err.head.msg)).errorAt(input)), input, isError);
          default: return r;
        }
      }
    }).lazy()

  public static function tag<T>(p : Void -> Parser<T>, tag : String) : Void -> Parser<T> return  
    withError(p, function (_) return tag +" expected")
  
}
