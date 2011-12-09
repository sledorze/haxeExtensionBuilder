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

class OptionIsAMonad {
//  public static function return_ <T>(x : T) : Option<T> return Some(x)
  
  public static function flatMap < T, U > (x : Option<T>, f : T -> Option<U>) : Option<U> {
    switch (x) {
      case Some(v) : return f(v);
      case None : return None;
    }
  }
}

class Functionnal {

  public static function get<T>(o : Option<T>) : T
    switch(o) {
      case Some(x) : return x;
      default : throw "Error Option get on None";
    }
  
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
