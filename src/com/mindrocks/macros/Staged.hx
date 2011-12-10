package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

#if macro
using Type;
using Lambda;
using Std;

class Staged {

  static function extractLookup(b : Expr) : Array<{ field : String, expr : Expr }> return {
    switch(b.expr) {
      case EObjectDecl(fields): fields;
      default : throw ("shouldn't happened - lookup expression " + Std.string(b.expr));
    }
  }
  
  static function substitueSeveral(src : Array<Expr>, subs : Array<{field : String, expr : Expr }>) {
    for (exp in src) {
      substitueExp(exp, subs);
    }
  }

  static function substitueName(name : String, subs : Array<{field : String, expr : Expr }>) {
    for (sub in subs) {
      if (sub.field == name) {
        switch (sub.expr.expr) {
          case EConst(v):
            switch (v) {
              case CString( s ): return s;
	            case CIdent( s ): return s;
	            case CType( s ): return s;
              default:
            }
          default:
        }
      }
    }
    return name;
  }

  static function substitueTypeParam(tp : TypeParam, subs : Array<{field : String, expr : Expr }>) {
    switch (tp) {
      case TPType( ct ) : substitueComplexType(ct, subs);
	    case TPExpr( e ) : substitueExp(e, subs);
    }
  }

  static function substitueTypePath(tp : TypePath, subs : Array<{field : String, expr : Expr }>) {
    for (param in tp.params) {
      substitueTypeParam(param, subs);
    }
  }

  static function substitueFunc(func : Function, subs : Array<{field : String, expr : Expr }>) {
    for (arg in func.args) {
      arg.name = substitueName(arg.name, subs);
      substitueComplexType(arg.type, subs);
      substitueExp(arg.value, subs);
    }
    substitueExp(func.expr, subs);
    for (param in func.params) {
      for (constraint in param.constraints) {
        substitueComplexType(constraint, subs);
      }
    }
  }
  
  static function substitueField(field : Field, subs : Array<{field : String, expr : Expr }>) {
    switch (field.kind) {
      case FVar(ct, e):
        substitueComplexType(ct, subs);
        substitueExp(e, subs);
      case FProp(get, set, t, e):
        substitueComplexType(t, subs);
        substitueExp(e, subs);
      case FFun(f):
        substitueExp(f.expr, subs);
        for (funArg in f.args) {
          funArg.name = substitueName(funArg.name, subs);
          substitueComplexType(funArg.type, subs);
          substitueExp(funArg.value, subs);
        }
        for (param in f.params) {
          for (constraint in param.constraints) {
            substitueComplexType(constraint, subs);
          }
        }
    }    
  }

  static function substitueComplexType(ct : ComplexType, subs : Array<{field : String, expr : Expr }>) {
    if (ct != null) {
      switch (ct) {
        case TPath(tp): substitueTypePath(tp, subs);
        case TParent(t): substitueComplexType(t, subs);
        case TFunction(args, ret):
          for (arg in args) {
            substitueComplexType(arg, subs);
          }
          substitueComplexType(ret, subs);
        case TExtend(tp, fields):
          substitueTypePath(tp, subs);
          for (field in fields) {
            substitueField(field, subs);
          }
        case TAnonymous(fields):
          for (field in fields) {
            substitueField(field, subs);
          }
        case TOptional(ct):
          substitueComplexType(ct, subs);
      }
    }
  }
  
  static function substitueExp(src : Expr, subs : Array<{field : String, expr : Expr }>) {
    if (src == null) return;
    switch (src.expr) {
      case EConst( c ):
        switch (c) {
          case CIdent( identName ):
            if (identName.charAt(0) == '$') {
              var name = identName.substr(1);
              for (sub in subs) {
                if (sub.field == name) {
                  try {
                    
                    var handled =
                      switch (sub.expr.typeof()) {
                        case TObject:
                          if (sub.expr.expr != null && sub.expr.pos != null) { // great chance it's an Expr..
                            src.expr = sub.expr.expr;
                            true;
                          } else false;
                        case TEnum(_):
                          if (Std.is(sub.expr, ExprDef)) {
                            src.expr = untyped sub.expr;
                          };
                          true;
                        default: false;
                      };
                      
                    trace("sub.expr " + Std.string(sub.expr));
                    trace("sub.expr.typeof() " + Std.string(sub.expr.typeof()));
                    
                    trace("name " + name + ": " + handled);
                    if (!handled) {
                      src.expr = Context.makeExpr(sub.expr, src.pos).expr;
                    }
                    
                  } catch (e : Dynamic) {
                    trace("Error while substitution" + name);
                  }
                  break;
                }
              }
            }
          default:
        }
      case EArray( e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EBinop( op, e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EField( e, field) : substitueExp(e, subs);
      case EType( e, field) :  substitueExp(e, subs);
      case EParenthesis( e ) :  substitueExp(e, subs);
      case EObjectDecl( fields) :
        for (field in fields)
        substitueExp(field.expr, subs);
      case EArrayDecl( values) : substitueSeveral(values, subs);
      case ECall( e, params) :  substitueExp(e, subs); substitueSeveral(params, subs);
      case ENew( t, params) : substitueSeveral(params, subs);
      case EUnop( op, postFix, e ) : substitueExp(e, subs); 
      case EVars( vars):
        for (vr in vars) {
          substitueExp(vr.expr, subs); 
        }
      case EFunction( name, f) : substitueFunc(f, subs);        
      case EBlock( exprs) : substitueSeveral(exprs, subs);
      case EFor( it, expr):  substitueExp(it, subs); substitueExp(expr, subs); 
      case EIn( e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EIf( econd, eif, eelse): substitueExp(econd, subs); substitueExp(eif, subs); substitueExp(eelse, subs);
      case EWhile( econd, e, normalWhile): substitueExp(econd, subs); substitueExp(e, subs);
      case ESwitch( e, cases, edef):
        substitueExp(e, subs); 
        for (cas in cases) {
          substitueExp(cas.expr, subs); 
        }        
        substitueExp(edef, subs); 
      case ETry( e, catches):
        substitueExp(e, subs); 
        for (cat in catches) {
          substitueExp(cat.expr, subs); 
        }        
      case EReturn(e):
        substitueExp(e, subs); 
      case EBreak:
      case EContinue:
      case EUntyped( e):
        substitueExp(e, subs); 
      case EThrow( e):
        substitueExp(e, subs); 
      case ECast( e, t):
        substitueExp(e, subs);
        substitueComplexType(t, subs);
      case EDisplay( e, isCall):
        substitueExp(e, subs);
      case EDisplayNew(t): //: TypePath 
        substitueTypePath(t, subs);

      case ETernary( econd, eif, eelse):
        substitueExp(econd, subs);
        substitueExp(eif, subs);
        substitueExp(eelse, subs);
      case ECheckType( e, t):
        substitueExp(e, subs);
        substitueComplexType(t, subs);
    }

  }
  
  private static var mapping : Array<Dynamic> = [];
  private static var stagedRes : Array<{ id : Int, expr : Expr }> = [];
  private static var lastReturned : Expr = null;

  public static function setMappings(m : Dynamic) {
    mapping.push(m);
  }
  public static function getMappings() : Dynamic {
    return mapping.pop();
  }

  public static function set(id : Int, m : Expr) {
    stagedRes.push({ id : id , expr : m });
  }  
  public static function get(id : Int) : Expr {
    var last = stagedRes[stagedRes.length - 1]; // it's more complicated than a basic stack because of code explosion and access..
    if (last != null && id == last.id) {
      lastReturned = stagedRes.pop().expr;
    }
    return lastReturned;
  }
  
  static var initialCode : String = "";

  public static var executeNext = true;
  @:macro public static function make(exp : Expr, id : Int) : Expr {
    var arr = [];  
    var mappings = getMappings();
    for (field in Reflect.fields(mappings)) {
      arr.push( { field : field, expr : untyped Reflect.field(mappings, field) } );
    }
    
    substitueExp(exp, arr);
    set(id, exp);
    
    executeNext = false;    
    // code explosion but it's at generation time, so maybe worst the burden..
    return Context.parse('{if (Staged.executeNext==true) {
      Staged.staged("'+initialCode+'",' + (id+1) + ');
    } else { Staged.executeNext = true; }; } ', Context.currentPos());
  }
  
  @:macro public static function staged(code : String, ?id : Int = 0) : Expr {
    initialCode = code;

    var identifiers = {
      var r : EReg = ~/\$[a-zA-Z0-9_-]+/;
      
      var res = [];
      var s = code;
      while( true ) {
        if( !r.match(s) )
          break;
        var ident = r.matched(0).substr(1); // matchedLeft().substr(1);
        if (!res.has(ident))
          res.push(ident);
        s = r.matchedRight();      
      }
      res;
    }
    
    var mappings =  "{ " + identifiers.map(function (str) return str + " : " + str).join(", ") + " }";
    
    var setMappings = "Staged.setMappings(" + mappings + ");";
    var stagedCall = "{"+setMappings+"Staged.make( " + code + ", " + id + "); Stagged.get("+id+"); }";
    return Context.parse(stagedCall, Context.currentPos());
  }

}
#end
