package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.text.Parser;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using Lambda;
 
typedef JsEntry = { name : String, value : JsValue}
enum JsValue {
  JsObject(fields : Array<JsEntry>);
  JsArray(elements : Array<JsValue>);
  JsData(x : String);
}

class JsonPrettyPrinter {
  public static function prettify(json : JsValue) : String return {
    function internal(json : JsValue) : String return {
      switch (json) {
        case JsObject(fields):
          "{\n" + fields.map(function (field) return field.name + " : " + internal(field.value)).join(",\n") + "\n}";
        case JsArray(elements):
          "[\n" + elements.map(internal).join(",\n") + "\n]";
        case JsData(x):
          x;
      } 
    }
    internal(json);
  }
}

class JsonParser {
  
  static function makeField(name : String, x : JsValue) return
    { name : name, value : x }
  
  static function withSpacing<T>(p : Parser<T>) return
    spacingP._and(p).and_(spacingP)
  
  static var identifierR = ~/[a-zA-Z0-9_-]+/;

  static  var identifierP = withSpacing(identifierR.regex());
  
  static  var leftAccP = withSpacing("{".identifier());
  static  var rightAccP = withSpacing("}".identifier());
  static  var leftBracketP = withSpacing("[".identifier());
  static  var rightBracketP = withSpacing("]".identifier());
  static  var sepParP = withSpacing(":".identifier());
  static  var commaParP = withSpacing(",".identifier());
  
  static  var spaceP = " ".identifier();    
  static  var tabP = "\t".identifier();
  static  var retP = ("\r".identifier().or("\n".identifier()));
  
  static  var spacingP = 
    [
      spaceP.oneMany(),
      tabP.oneMany(),
      retP.oneMany()        
    ].ors().many();
  
  
  static var valueP : Void -> Parser<JsValue> =
    (function () return
      identifierP.then(JsData).trace(function (x) return "valueP " + Std.string(x))
    ).lazy();
  
  static var jsonEntryP : Void -> Parser < Tuple2 < String, JsValue >> =
    (function () return
      identifierP.and_(sepParP).and(valueOrJsonP()).trace(function (x) return "jsonEntryP " + Std.string(x))
    ).lazy();
    
  static  var jsonContentP =
    (function() return
      jsonEntryP().repsep(commaParP).trace(function (x) return "jsonContentP " + Std.string(x))
    ).lazy();
  
  public static var jsonP : Void -> Parser<JsValue> =
    (function () return
      leftAccP._and(jsonContentP()).and_(rightAccP).then(function (entries)
        return JsObject(entries.map(function (p) return makeField(p.a, p.b)).array())
      )
    ).lazy();

  static var jsonArrayP : Void -> Parser<JsValue> =
    (function () return
      leftBracketP._and(valueOrJsonP().repsep(commaParP)).and_(rightBracketP).then(JsArray)
    ).lazy();

  static var valueOrJsonP : Void -> Parser<JsValue> = 
    (function () return
      [jsonP(), valueP(), jsonArrayP()].ors().trace(function (x) return "valueOrJsonP " + Std.string(x))
    ).lazy();
    
}

class ParserTest {

  public static function jsonTest() {
    try {
      
    var json = " {  aaa : aa } "; // , bbb : ccc } ";
    JsonParser.jsonP();
    switch (JsonParser.jsonP()(json)) {
      case Success(res, rest):
        trace("Parsed " + JsonPrettyPrinter.prettify(res));
      case Failure(err): 
        trace("parse error " + err);
     }
     
    } catch (e : Dynamic) {
    //  trace("Error " + Std.string(e));
    }
    
  }
  
}

