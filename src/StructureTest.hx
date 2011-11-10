package ;

using Std;
import Prelude;
import PreludeExtensions;
using PreludeExtensions;
import haxe.data.collections.ArrayExtensions;
using haxe.data.collections.ArrayExtensions;

import com.mindrocks.structure.Repr;

/**
 * ...
 * @author sledorze
 */

class StructureTest {

  public static function test() {
    
    var value = {
      a : "toto",
      b : [ {c : 5, d : 2.5 }, {c : 5, d : 2 } ],
      c : [55, 43],
    }
    
    var def =
      Elem(JsDefObj([
        { name : "a", value : Or([Elem(JsDefNumber), Elem(JsDefString)]) },
        { name : "b", value : Elem(JsDefArray(Elem(JsDefObj([{ name : "c", value : Elem(JsDefNumber)}, { name : "d", value : Elem(JsDefNumber) }]))))},
        { name : "c", value : Elem(JsDefArray(Elem(JsDefNumber))) },
      ]));
    
      
    var objDef = Repr.defFrom(value);
    trace("Def " + objDef.string());
    var objResult = Repr.validatesObj(objDef, value);
    trace("ObjResult " + objResult.string());
   
    
    var result = Repr.validatesObj(def, value);
    trace("Result " + result.string());
    
  }
  
}