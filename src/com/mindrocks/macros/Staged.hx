package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;
import haxe.macro.Type;

#if macro
using Type;
using Lambda;
using Std;

class Substituer {
  var transfo : Expr -> String -> Void;
  public function new(transfo : Expr -> String -> Void) {
    this.transfo = transfo;    
  }
  
  static function extractLookup(b : Expr) : Array<{ field : String, expr : Expr }> return {
    switch(b.expr) {
      case EObjectDecl(fields): fields;
      default : throw ("shouldn't happened - lookup expression " + Std.string(b.expr));
    }
  }
  
  function substitueSeveral(src : Array<Expr>) {
    for (exp in src) {
      substitueExp(exp);
    }
  }
/*
  function substitueName(name : String) {
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
*/
  function substitueTypeParam(tp : TypeParam) {
    switch (tp) {
      case TPType( ct ) : substitueComplexType(ct);
	    case TPExpr( e ) : substitueExp(e);
    }
  }

  function substitueTypePath(tp : TypePath) {
    for (param in tp.params) {
      substitueTypeParam(param);
    }
  }

  function substitueFunc(func : Function) {
    for (arg in func.args) {
  //    arg.name = substitueName(arg.name);
      substitueComplexType(arg.type);
      substitueExp(arg.value);
    }
    substitueExp(func.expr);
    for (param in func.params) {
      for (constraint in param.constraints) {
        substitueComplexType(constraint);
      }
    }
  }
  
  function substitueField(field : Field) {
    switch (field.kind) {
      case FVar(ct, e):
        substitueComplexType(ct);
        substitueExp(e);
      case FProp(get, set, t, e):
        substitueComplexType(t);
        substitueExp(e);
      case FFun(f):
        substitueExp(f.expr);
        for (funArg in f.args) {
  //        funArg.name = substitueName(funArg.name);
          substitueComplexType(funArg.type);
          substitueExp(funArg.value);
        }
        for (param in f.params) {
          for (constraint in param.constraints) {
            substitueComplexType(constraint);
          }
        }
    }    
  }

  function substitueComplexType(ct : ComplexType) {
    if (ct != null) {
      switch (ct) {
        case TPath(tp): substitueTypePath(tp);
        case TParent(t): substitueComplexType(t);
        case TFunction(args, ret):
          for (arg in args) {
            substitueComplexType(arg);
          }
          substitueComplexType(ret);
        case TExtend(tp, fields):
          substitueTypePath(tp);
          for (field in fields) {
            substitueField(field);
          }
        case TAnonymous(fields):
          for (field in fields) {
            substitueField(field);
          }
        case TOptional(ct):
          substitueComplexType(ct);
      }
    }
  }
    
  public function substitueExp(src : Expr) {
    if (src == null) return;
    switch (src.expr) {
      case EConst( c ):
        switch (c) {
          case CIdent( identName ):
            if (identName.charAt(0) == '$') {
              transfo(src, identName);
            }
          default:
        }
      case EArray( e1, e2) : substitueExp(e1); substitueExp(e2);
      case EBinop( op, e1, e2) : substitueExp(e1); substitueExp(e2);
      case EField( e, field) : substitueExp(e);
      case EType( e, field) :  substitueExp(e);
      case EParenthesis( e ) :  substitueExp(e);
      case EObjectDecl( fields) :
        for (field in fields)
        substitueExp(field.expr);
      case EArrayDecl( values) : substitueSeveral(values);
      case ECall( e, params) :  substitueExp(e); substitueSeveral(params);
      case ENew( t, params) : substitueSeveral(params);
      case EUnop( op, postFix, e ) : substitueExp(e); 
      case EVars( vars):
        for (vr in vars) {
          substitueExp(vr.expr); 
        }
      case EFunction( name, f) : substitueFunc(f);        
      case EBlock( exprs) : substitueSeveral(exprs);
      case EFor( it, expr):  substitueExp(it); substitueExp(expr); 
      case EIn( e1, e2) : substitueExp(e1); substitueExp(e2);
      case EIf( econd, eif, eelse): substitueExp(econd); substitueExp(eif); substitueExp(eelse);
      case EWhile( econd, e, normalWhile): substitueExp(econd); substitueExp(e);
      case ESwitch( e, cases, edef):
        substitueExp(e); 
        for (cas in cases) {
          substitueExp(cas.expr); 
        }        
        substitueExp(edef); 
      case ETry( e, catches):
        substitueExp(e); 
        for (cat in catches) {
          substitueExp(cat.expr); 
        }        
      case EReturn(e):
        substitueExp(e); 
      case EBreak:
      case EContinue:
      case EUntyped( e):
        substitueExp(e); 
      case EThrow( e):
        substitueExp(e); 
      case ECast( e, t):
        substitueExp(e);
        substitueComplexType(t);
      case EDisplay( e, isCall):
        substitueExp(e);
      case EDisplayNew(t): //: TypePath 
        substitueTypePath(t);

      case ETernary( econd, eif, eelse):
        substitueExp(econd);
        substitueExp(eif);
        substitueExp(eelse);
      case ECheckType( e, t):
        substitueExp(e);
        substitueComplexType(t);
    }
  }

}

class Staged {

  
  private static var mapping : Array<Dynamic> = [];
  private static var stagedRes : Array<{ id : Int, expr : Expr }> = [];
  private static var lastReturned : Expr = null;

	public static function __init__() {
		if (mapping == null) mapping = [];
		if (stagedRes == null) stagedRes = [];
	}
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

  static function fieldToExpr(subs : Array<{field : String, expr : Expr }>) return function (src : Expr, identName : String) {
    var name = identName.substr(1);
    for (sub in subs) {
      if (sub.field == name) {
        try {
//          trace("before " + Std.string(sub.expr));
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
  /*          
          trace("sub.expr " + Std.string(sub.expr));
          trace("sub.expr.typeof() " + Std.string(sub.expr.typeof()));
          
          trace("name " + name + ": " + handled);
          */
          if (!handled) {
            src.expr = Context.makeExpr(sub.expr, src.pos).expr;
          }
          
        } catch (e : Dynamic) {
          trace("Error during substitution" + name);
        }
        break;
      }
    }
  }

  public static function subtituedWithExpForField(exp : Expr, arr : Array<{field : String, expr : Expr }>) {
    new Substituer(fieldToExpr(arr)).substitueExp(exp);
  }

  public static function collectIdentifiers(exp : Expr) : Array<String> {
    var res = [];
    var subs = new Substituer(function (_, identifier) {
      res.push(identifier);
    });
    subs.substitueExp(exp);
    return res;
  }
  
  public static var executeNext = true;
  @:macro public static function make(exp : Expr, id : Int) : Expr {
    var arr = [];  
    var mappings = getMappings();
    for (field in Reflect.fields(mappings)) {
      arr.push( { field : field, expr : untyped Reflect.field(mappings, field) } );
    }
    
    subtituedWithExpForField(exp, arr);
    set(id, exp);
    
    executeNext = false;    
    // code explosion but it's at generation time, so maybe worst the burden..
    return
      Context.parse('{
          if (Staged.executeNext==true) {
            Staged.staged("'+initialCode+'",' + (id+1) + ');
          } else {
            Staged.executeNext = true;
          };
        }',
        Context.currentPos()
      );
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
    
    var stagedCall = "{ Staged.setMappings(" + mappings + "); Staged.make( " + code + ", " + id + "); Staged.get("+id+"); }";
    return Context.parse(stagedCall, Context.currentPos());
  }

  static var id = 0;
  static function getId():String {
    id++;
    return "" + id;
  }
  private static var slice : Hash<Expr> = new Hash<Expr>();

  public static function setSlice(e : Expr) : String {
    var id = getId();
    slice.set(id, e);
    return id;
  }
  public static function getSlice(id : String) : Expr {
    return slice.get(id);
  }

  public static function mk(expDef : ExprDef) {
    return { expr : expDef, pos : Context.currentPos() };
  }
  
  @:macro public static function staged2(code : Expr, ?id : Int = 0) : Expr {
    var idStr = setSlice(code);
    
    var identifiers = Staged.collectIdentifiers(code);

    var cp = mk(ECall(mk(EField(mk(EConst(CType("Context"))), "currentPos")), []));
    
    var allMaps = identifiers.map(function (str) return str.substr(1)).map(function (str) {
        if (StringTools.startsWith(str, "_")) {
          str = str.substr(1);
          return mk(EObjectDecl([
            { field : "field", expr : mk(EConst(CString("_"+str))) },
            { field : "expr", expr : mk(EConst(CIdent(str))) }
          ]));

        } else {
          return mk(EObjectDecl([
            { field : "field", expr : mk(EConst(CString(str))) },
            { field : "expr", expr : mk(ECall(mk(EField(mk(EConst(CType("Context"))), "makeExpr")), [mk(EConst(CIdent(str))), cp])) }
          ]));          
        }
      });
    
    var expMapp : ExprDef = 
      EVars([
        { name : "mappings", type : null, expr : mk(
          EArrayDecl(allMaps.array())
        )}
      ]);

    var exp1 : ExprDef = 
      EVars([
        { name : "res", type : null, expr : mk(ECall(mk(EConst(CIdent("cpy"))), [mk(ECall(mk(EField(mk(EConst(CType("Staged"))), "getSlice")), [mk(EConst(CString(idStr)))]))])
        ) }
      ]);
    
    var res =
      mk(EBlock([
        mk(expMapp),
        mk(exp1),
        mk(ECall(mk(EField(mk(EConst(CType("Staged"))), "subtituedWithExpForField")), [mk(EConst(CIdent("res"))), mk(EConst(CIdent("mappings")))])),
        mk(EConst(CIdent("res")))
      ]));
    return res;
  }

}
#end
