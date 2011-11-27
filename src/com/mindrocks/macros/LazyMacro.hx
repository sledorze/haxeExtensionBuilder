package com.mindrocks.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import com.mindrocks.macros.Stagged;
using com.mindrocks.macros.Stagged;

/**
 * ...
 * @author sledorze
 */

class LazyMacro {

  static function alreadyLazy(type : Type) : Bool {
    switch (type) {
      case TFun(args, _): return args.length == 0;
      case TLazy(f) : return alreadyLazy(f());
      default : return false;
    };
  }

  @:macro public static function lazy(exp : Expr) : Expr {
    var type = Context.typeof(exp);    
    if ( alreadyLazy(type)) {
      return exp;
    } else {
      var res : Expr =
      "{
        var value = null;
        return function () {        
          if (value == null) {
            value = untyped 1; // not null to prevent live lock if it forms a cycle.
            value = $exp;
          }
          return value;
        };
      }
      ".stagged();
      return res;  
    }
  }

}