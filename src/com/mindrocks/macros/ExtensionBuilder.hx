package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

#if macro
class ExtensionBuilder {
  
  static  function addIfNotPresent(arr : Array<Access>, e) {
    if (!arr.has(e)) arr.push(e);
    return arr;
  }
  
  static  function isNativeMeta(meta) return
    meta.name == ":native"
  
  public static function build(_extendedType : String): Array<Field> {    
    var retFields = [];
    
    var pack = _extendedType.split('.');
    var extendedType = pack[pack.length - 1];
    pack.pop();
    
    var additionalJQueryArg : FunctionArg = {
      name : "__tp",
      opt : false,
      type : TPath({ pack : pack, name : extendedType, params : [], sub : null }),
      value : null,
    };

    var arr = Context.getClassPath();
    Context.getBuildFields().map(function (field) {
          
      var isNative = field.meta.exists(isNativeMeta);
      if (isNative) {

        
        field.meta.filter(isNativeMeta).map(function (meta) {
              
          meta.params.map(function (param) {          
            switch (param.expr) {
              case EConst( c ):
                switch(c) {
                  case CString( funcName ):
                 
                    var newKind = 
                      switch (field.kind) {
                        case FFun(f):

                          var currentPos =  field.pos;
                          
                          var newArgs = {
                            function argToParam(arg) return
                              { expr : EConst(CIdent(arg.name)), pos : currentPos }
                            f.args.map(argToParam).array();
                          }
                          
                          // coz I thinks it's faster than reparsing..
                          var newExpr : Expr = {
                              expr : EReturn(
                                  { expr : EUntyped(
                                      { expr : ECall(
                                          { expr : EField(
                                              { expr : EConst(CIdent("__tp")), pos : currentPos, },
                                              funcName + " " /*TODO: fix the real issue; don't know why yet but it prevents an issue.. (it's late) */
                                            ),
                                            pos : currentPos
                                          },
                                          newArgs
                                        ),
                                        pos : currentPos
                                      }
                                    ),
                                    pos : currentPos
                                  }
                                ),
                              pos : currentPos
                            };
                          
                          var newFunc =
                            FFun({
                              ret : f.ret,
                              params : f.params,
                              expr : newExpr,
                              args : [additionalJQueryArg].concat(f.args)
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
                      res;
                    }
                    
                    var newField =  {
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
        });
            
      } else {
        retFields.push(field);            
      }
    });
    
    return retFields;
  }
}
#end
