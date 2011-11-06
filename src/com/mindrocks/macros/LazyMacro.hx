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

  @:macro public static function lazy(exp : Expr) : Expr return {
    "{
      var computed = false;
      var value = null;
      function () return {
        if (!computed) {
          computed = true; // important to prevent exp evaluation to live lock if it forms a cycle.
          value = $exp;
        }
        value;
      };
    }
    ".stagged();
  }
  
  @:macro public static function lazyF(exp : Expr) : Expr return {
    "{
      var computed = false;
      var value = null;
      function () return {
        if (!computed) {
          computed = true; // important to prevent exp evaluation to live lock if it forms a cycle.
          value = $exp();
        }
        value;
      };
    }
    ".stagged();
  }
}