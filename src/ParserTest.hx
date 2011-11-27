package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.text.Parser;
import js.JQuery;
import js.Lib;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using com.mindrocks.macros.LazyMacro;

using Lambda; 

typedef JsEntry = { name : String, value : JsValue}
enum JsValue {
  JsObject(fields : Array<JsEntry>);
  JsArray(elements : Array<JsValue>);
  JsData(x : String);
}
/**
 * Quick n dirty.
 */
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
  
  static function makeField(t : Tuple2<String, JsValue>) return
    { name : t.a, value : t.b }
  
  static var identifierR = ~/[a-zA-Z0-9_-]+/;

  static  var spaceP = " ".identifier();    
  static  var tabP = "\t".identifier();
  static  var retP = ("\r".identifier().or("\n".identifier()));
  
  static  var spacingP =
    [
      spaceP.oneMany(),
      tabP.oneMany(),
      retP.oneMany()
    ].ors().many().lazyF();
  
  static  var leftAccP = withSpacing("{".identifier());
  static  var rightAccP = withSpacing("}".identifier());
  static  var leftBracketP = withSpacing("[".identifier());
  static  var rightBracketP = withSpacing("]".identifier());
  static  var sepP = withSpacing(":".identifier());
  static  var commaP = withSpacing(",".identifier());
  static  var equalsP = withSpacing(",".identifier());
  
  
  static function withSpacing<T>(p : Void -> Parser<T>) return
    spacingP._and(p)

  static var identifierP =
    withSpacing(identifierR.regexParser());

  static var jsonDataP =
    identifierP.then(JsData);
    
  static var jsonValueP : Void -> Parser<JsValue> =
    [jsonParser, jsonDataP, jsonArrayP].ors().tag("json value").lazyF();

  static var jsonArrayP =
    leftBracketP._and(jsonValueP.repsep(commaP).and_(rightBracketP).commit()).then(JsArray);
    

  static var jsonEntryP =
    identifierP.and(sepP._and(jsonValueP).commit());
  
  static  var jsonEntriesP =
    jsonEntryP.repsep(commaP).commit();

  public static var jsonParser =
    leftAccP._and(jsonEntriesP).and_(rightAccP.commit()).then(function (entries)
      return JsObject(entries.map(makeField).array())
    );
}

class LRTest {

  static var posNumberR = ~/[0-9]+/;
  
  static var plusP = "+".identifier();
  
  static var posNumberP = posNumberR.regexParser().tag("number").lazyF();
    
  static var binop = (expr.and_(plusP)).andWith(expr.commit(), function (a, b) return a + " + " + b).tag("binop").lazyF();
  public static var expr : Void -> Parser<String> = binop.or(posNumberP).memo().tag("expression").lazyF();
}

class ParserTest {

  static function tryParse<T>(str : String, parser : Parser<T>, withResult : T -> Void, output : String -> Void) {
    try {
      switch (parser(str.reader())) {
        case Success(res, rest):
          trace("success!");
          withResult(res);
        case Failure(err, rest, _):
          var p = rest.textAround();
          output(p.text);
          output(p.indicator);          
          err.map(function (err) {
            output("Error at " + err.pos + " : " + err.msg);
          });
          
          
      }
    } catch (e : Dynamic) {
      trace("Error " + Std.string(e));
    }    
  }
  
  public static function jsonTest() {
    
    var elem = Lib.document.getElementById("haxe:trace");
    if (elem != null) {
      trace("elem[0] " + elem);
      new JQuery(elem).css("font-family", "Courier New, monospace");      // monospace!
    }
    function toOutput(str : String) {
      // REPLACE SPACES TO PREVENT THEM TO DDISAPPEAR..
      
      trace(StringTools.replace(str, " ", "_"));
    }
    
    tryParse(
      " {  aaa : aa, bbb :: [cc, dd] } ", // , bbb : ccc } ";
      JsonParser.jsonParser(),
      function (res) trace("Parsed " + JsonPrettyPrinter.prettify(res)),
      toOutput
    );
    
    tryParse(
      "5++3+2+3",
      LRTest.expr(),
      function (res) trace("Parsed " + res),
      toOutput
    );
    
  }
  
}

