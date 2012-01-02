package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */

import haxe.macro.Expr;
import haxe.macro.Context;
import com.mindrocks.macros.Monad;

 
typedef Error = Dynamic
typedef RC<R,A> = (Error -> A -> R) -> R

@:native("NodeM") class NodeM {

  @:macro public static function dO(body : Expr) return
    Monad.dO("NodeM", body, Context)

  inline static public function ret <A,R>(i:A):RC<R,A>
    return function(cont) return cont(null, i)

  static public function flatMap <A, B, R>(m:RC<R,A>, k: A -> RC<R,B>): RC<R,B>
    return function(cont : Error -> B -> R) {
      return m(function(err, a) {
        if (err != null)
          return cont(err, null);
        else
          return k(a)(cont);
      });
    }
    
    // return m(function(err, a) return k(a)(cont));

  static public function map <A, B, R>(m:RC<R,A>, k: A -> B): RC<R,B>
    return function(cont : Error -> B -> R)
      return m(function (err, a) {
        if (err != null)
          return cont(err, null);
        else
          return cont(null, k(a));
      })
}
