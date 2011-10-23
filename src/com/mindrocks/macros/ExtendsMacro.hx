package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

#if macro

class ExtendsTypeMacroHelper {
  
  static function baseTypeAsTypePath(bt : BaseType, params : Array<Type>) : TypePath return {
    pack : bt.pack,
    name : bt.name,
    params : params.map(function (x) return TPType(toComplexType(x))).array(),
    sub : null
  }

  static function classFieldAsField(cf : ClassField) : Field  return {
    name : cf.name,
    doc : cf.doc,
    access : [cf.isPublic?APublic:APrivate],
    kind : FVar(toComplexType(cf.type)),
    pos : cf.pos,
    meta : []
  }
  
  public static function  toComplexType(p : Type) : ComplexType return
    switch (p) {
      case TMono(t): if (t == null) throw "unknown type" else toComplexType(t.get());
      case TEnum(t, params): TPath(baseTypeAsTypePath(t.get(), params));
      case TInst(t, params): TPath(baseTypeAsTypePath(t.get(), params));
      case TType(t , params): TPath(baseTypeAsTypePath(t.get(), params));
      case TFun(args, ret): TFunction(args.map(function (x) return toComplexType(x.t)).array(), toComplexType(ret));
      case TAnonymous(a): TAnonymous(a.get().fields.map(classFieldAsField).array());
      case TDynamic( t ): throw "Dynamic type not supported"; null;
      case TLazy( f ): throw "Lazy type not supported"; null;
    }
  
}

class ExtendsMacro<T> {
  
  
  static  function addIfNotPresent(arr : Array<Access>, e) {
    if (!arr.has(e)) arr.push(e);
    return arr;
  }
  
  static  function isNativeMeta(meta) return
    meta.name == ":native"

  static var extensionClassName = "Extends";
  static function isExtension(el) return
    el.t.get().name == extensionClassName
  
  public static function build(): Array<Field> {    
    
    var retFields : Array<Field> = [];
    
    var additionalArg : FunctionArg = {
      var newType : ComplexType = {
        var extensionType = {
          var clazz : ClassType = Context.getLocalClass().get();      
          clazz.interfaces.filter(isExtension).array()[0].params[0];
        }
        ExtendsTypeMacroHelper.toComplexType(extensionType);
      }
      
      {
        name : "__tp",
        opt : false,
        type : newType,
        value : null,
      }
    };

    var arr = Context.getClassPath();
    Context.getBuildFields().map(function (field : Field) {
        
      var nativeMetas = field.meta.filter(isNativeMeta);
      if (nativeMetas.length == 1) {
        var meta = nativeMetas.first();
        
        meta.params.map(function (param) {          
          switch (param.expr) {
            case EConst( c ):
              switch(c) {
                case CIdent( funcName ) :
               
                  var newKind = 
                    switch (field.kind) {
                      case FFun(f):
                        var currentPos =  field.pos;
                        
                        var newArgs = {
                          function argToParam(arg) return
                            { expr : EConst(CIdent(arg.name)), pos : currentPos }
                          f.args.map(argToParam).array();
                        }
                        
                        // coz I think it's faster than reparsing..
                        var newExpr : Expr = {
                            expr : EReturn(
                                { expr : EUntyped(
                                    { expr : ECall(
                                        { expr : EField(
                                            { expr : EConst(CIdent("__tp")), pos : currentPos, },
                                            funcName + " " /*TODO: fix the real issue; don't know why yet but it prevents an issue.. (it's late) */
                                          ), pos : currentPos
                                        },
                                        newArgs
                                      ), pos : currentPos
                                    }
                                  ), pos : currentPos
                                }
                              ), pos : currentPos
                          };
                        
                        var newFunc =
                          FFun({
                            ret : f.ret,
                            params : f.params,
                            expr : newExpr,
                            args : [additionalArg].concat(f.args)
                          });
                          
                        newFunc;
                      default : throw ":native can only be used on functions, not : " + Std.string(field.kind); null;
                    }
               
                  var newMetas = field.meta.copy();
                    newMetas.remove(meta);

                  var newAcess = {
                    var res = field.access;
                    addIfNotPresent(res, AStatic);
                    addIfNotPresent(res, AInline);
                    if (!res.has(APrivate))
                      addIfNotPresent(res, APublic);
                    res;
                  }
                  
                  var newField : Field =  {
                    name : field.name,
                    doc : field.doc,
                    access : newAcess,
                    kind : newKind,
                    pos : field.pos,
                    meta : newMetas
                  };
                  retFields.push(newField);
                default : throw "only string are allowed for :native parameter";
              }
              default:
            }
            
        });
      } else {
        retFields.push(field);            
      }
    });
    return retFields;
  }
}
#end

@:autoBuild(com.mindrocks.macros.ExtendsMacro.build()) interface Extends<T> { } 
