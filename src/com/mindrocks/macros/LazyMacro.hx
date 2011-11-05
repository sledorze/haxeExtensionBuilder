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
    "
      function () return {
        var computed = false;
        var value = null;
        if (!computed) {
          computed = true;
          value = $exp;
        }
        value;
      }
    ".stagged();
  }
  
}