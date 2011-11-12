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

  public static var computing = new Array<Dynamic>();
  
  @:macro public static function lazy(exp : Expr) : Expr return {
    "function(){
      var value = null;
      return function () {        
        if (value == null) {
          value = untyped 1; // not null to prevent live lock if it forms a cycle.
          value = $exp;
        }
        return value;
      };
    }()
    ".stagged();
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