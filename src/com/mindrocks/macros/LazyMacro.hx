<<<<<<< HEAD
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
  /*  
    if ( alreadyLazy(Context.typeof(exp))) {
      trace("EXP " + exp);
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
//    }
  }

  @:macro public static function lazyF(exp : Expr) : Expr return {
    "{
      var value = null;
      function () {
        if (value == null) {
          value = untyped 1; // not null to prevent live lock if it forms a cycle.
          value = $exp();
        }
        return value;
      };
    }
  }

}
=======
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

  // detect if applying lazy would change anything (this obviously is not working, would requiers inspecting the actual AST).
  static function alreadyLazy(type : Type) : Bool {
    switch (type) {
      case TFun(args, _): return args.length == 0;
      case TLazy(f) : return alreadyLazy(f());
      default : return false;
    };
  }
  
  @:macro public static function lazy(exp : Expr) : Expr {
  /*  
    if ( alreadyLazy(Context.typeof(exp))) {
      trace("EXP " + exp);
      return exp;
    } else {
*/    
    return
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
//    }
  }

  @:macro public static function lazyF(exp : Expr) : Expr return {
    "{
      var value = null;
      function () {
        if (value == null) {
          value = untyped 1; // not null to prevent live lock if it forms a cycle.
          value = $exp();
        }
        return value;
      };
    }
    ".stagged();
  }

}
>>>>>>> revert back lazy implementation; cannot ensure idempotence
