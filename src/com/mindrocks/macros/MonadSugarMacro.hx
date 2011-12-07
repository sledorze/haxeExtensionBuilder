package com.mindrocks.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;

using Lambda;

using com.mindrocks.macros.Stagged;
import com.mindrocks.macros.Stagged;

/**
 * ...
 * @author sledorze
 */

class MonadSugarMacro {

  @:macro public static function monad(body : Expr, monad : Expr) {

    function mk(e : ExprDef) return { pos : Context.currentPos(), expr : e };
    
    var res =
      switch (body.expr) {
        case EBlock(exprs):
          switch (exprs[0].expr) {
            case EBinop(op, l, r) :
              switch (op) {
                case OpLte:
                  
                  var name : String =
                    switch (l.expr) {
                      case EConst(c) :
                        switch (c) {
                          case CIdent(name) : name;
                          default : return body;
                        }
                      default : return body;
                    }                  
                    
                  trace("NAME " + name);
                  var rest = exprs[1];
                  var lExpr = l.expr;                  
                  
//                  var evars = EVars([{name  : name, type : null, expr : } ]);
                  var func = EFunction(null, { args : [ { name : name, type : null, opt : false, value : null } ], ret : null, expr : "{ return $rest; }".stagged(), params : []} );
                  
                  var newF : Expr = "{ OptionIsAMonad.bind_( $r , $func ); }".stagged();
                  
                  // Not good
                  // Faire la transfo correcte.. (bind etc..)
//                  src/com/mindrocks/macros/MonadSugarMacro.hx:61: res { expr => EBlock([{ expr => EBlock([{ expr => ECall({ expr => EField({ expr => EConst(CType(OptionIsAMonad)), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:46: characters 97-111) },bind_), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:46: characters 97-117) },[{ expr => ECall({ expr => EConst(CType(Some)), pos => #pos(src/MonadTest.hx:31: characters 19-23) },[{ expr => EConst(CInt(55)), pos => #pos(src/MonadTest.hx:31: characters 24-26) }]), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:47: characters 0-2) }, { expr => EFunction(null,{ args => [{ ??? => ___x, type => null, ??? => false, value => null }], expr => { expr => EBlock([{ expr => EReturn({ expr => ECall({ expr => EConst(CType(Some)), pos => #pos(src/MonadTest.hx:32: characters 10-14) },[{ expr => EBinop(OpAdd,{ expr => EConst(CIdent(value)), pos => #pos(src/MonadTest.hx:32: characters 15-20) },{ expr => EConst(CInt(5)), pos => #pos(src/MonadTest.hx:32: characters 23-24) }), pos => #pos(src/MonadTest.hx:32: characters 15-24) }]), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:48: characters 1-6) }), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:47: lines 47-48) }]), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:47: lines 47-48) }, params => [], ??? => null }), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:47: lines 47-48) }]), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:46: lines 46-48) }]), pos => #pos(src/com/mindrocks/macros/MonadSugarMacro.hx:46: lines 46-48) }]), pos => #pos(src/MonadTest.hx:29: lines 29-35) }
                  mk(EBlock([
                    newF //ECall(mk(EFunction("OptionIsAMonad.bind_", bindFunc)), [l]))
                  ]));
                  
                default : body;
              }
            default:  body;
          }
        default : body;
      };
    trace("body " + body);
    trace("res " + res);
    trace("monad " + monad);
    return res;
  }
  
}