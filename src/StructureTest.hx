package ;

using Std;
import Prelude;
import PreludeExtensions;
using PreludeExtensions;
import haxe.data.collections.ArrayExtensions;
using haxe.data.collections.ArrayExtensions;

import com.mindrocks.structure.Repr;

import js.JQuery;

/**
 * ...
 * @author sledorze
 */

/*
enum TreeNode {  
}
*/
 
class NodeRendering {

  public static function node(x : String) : JQuery {
    return new JQuery(Std.format("<div>$x</div>"));
  }
  
  public static function sub(jq : JQuery, sub : JQuery) : JQuery {
    sub.css("position", "relative");
    sub.css("left", "10px");
    return jq.append(sub);
  }

  public static function subs(jq : JQuery, subs : Array<JQuery>) : JQuery {
    subs.foreach(function (s) sub(jq, s));
    return jq;
  }
  
}
using StructureTest;

class StructureTest {

  
  static function displayJsValue(jsValue : JsValue) : JQuery {
    return 
      switch (jsValue) {
        case JsValString: "String".node();
        case JsValNumber: "Number".node();
        case JsValDynamic: "Dynamic".node();
        case JsValObj(fields):
          var res = "Obj".node();
          fields.map(function (named) res.sub(named.name.node().sub(displayValidation(named.value))));
          res;
        case JsValArray(elems):
          var res = "Array".node();
          elems.foreach(function (val) res.sub(displayValidation(val)));
          res;
      };
  }

  static function displayDefValue(defValue : JsDef) : JQuery {
    var res =
      switch (defValue) {      
        case JsDefString:  "Def String".node();
        case JsDefNumber: "Def Number".node();
        case JsDefDynamic: "Def Dynamic".node();
        case JsDefObj(fields):
          var res = "Def Obj".node();
          fields.foreach(function (named) res.sub(named.name.node().subs(named.value.map(displayDefValue))));
          res;
        case JsDefArray(elems):
          var res = "Def Array".node();
          elems.foreach(function (val) res.sub(displayDefValue(val)));
          res;
      };
    res.css("color", "blue");
    return res;
  }

  static function displayStatus(status : ValidStatus) : JQuery {
    return
      switch (status) {      
        case Valid(valid): displayJsValue(valid).css("color", "green"); // everything under is valid.
        case Partial(valid): displayJsValue(valid).css("color", "orange");  // not everything under is valid
        case Failed(): "Failed".node().css("color", "red");
      };
  }
  
  static function displayEntry(entry : ValidEntry) : JQuery {
//    var node = "entry".node();
    var statusNode = displayStatus(entry.status);    
//    node.sub(statusNode);
    entry.choice.map(displayDefValue).map(statusNode.sub);
    
   //entry.
//  choice : JsDefValues,
//  status : ValidStatus,
    return statusNode;
  }

  static function displayValidation(valid : Validation) : JQuery {
    var node = "valid".node();
    
    var objRepr =
      new JQuery("<div>" + Std.string(valid.obj) + "</div>").css("color", "grey");
    
    var doms =
      [
        [objRepr],
        valid.succeed.map(displayEntry),
        valid.partial.map(displayEntry),
        valid.failed.map(displayEntry),
      ].flatten().flatMap(function (jq) return jq.get());
    
    // node.sub();
    /*
    valid.succeed.map(displayEntry).map(node.sub);
    valid.partial.map(displayEntry).map(node.sub);
    valid.failed.map(displayEntry).map(node.sub);
    */
//    node.sub();
    return new JQuery("").add(doms);
  }
  
  public static function test() {

    var value = {
      a : "toto",
      b : [ {c : 5, d : 2.5 }, {c : 5, d : 2 } ],
      c : [55, 43],
    }
    
    var def =
      [
        JsDefObj([
          { name : "a", value : [JsDefNumber, JsDefString] },
          { name : "b", value : [JsDefArray([JsDefObj([{ name : "c", value : [JsDefNumber]}, { name : "d", value : [JsDefNumber] }])])] },
          { name : "c", value : [JsDefArray([JsDefNumber])] },
        ])
      ]; 
      
    var objDef = Repr.defFrom(value);
    trace("Def " + objDef.string());
    var objResult = Repr.validatesObj(objDef, value);
    trace("ObjResult " + objResult.string());
   
    
    var result = Repr.validatesObj(def, value);
    
    new JQuery("body").sub(displayValidation(result));
    
    trace("Result " + result.string());
    
  }
  
}