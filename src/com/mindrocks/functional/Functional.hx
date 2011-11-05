package com.mindrocks.functional;
  
/**
 * ...
 * @author sledorze
 */

typedef Tuple2<A,B> = { a : A, b : B } 

class Tuples {
  public static function t2<A,B>(a : A, b : B) : Tuple2<A,B> return { a : a, b : b }
}

enum Option<T> {
  None;
  Some(x: T);
}

typedef Lazy<T> = Void -> T

class Functionnal {
  
  public static function lazzy<T>(f : Void -> T) : Lazy<T> return {
    var value = null;
    var computed = false;
    function ()  return {
      if (computed == false) {
        computed = true;
        value = f();
      }
      value;
    }
  }
  
}