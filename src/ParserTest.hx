package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.text.Parser;
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
  
  
  static function withSpacing<T>(p : Void -> Parser<T>) return
    spacingP._and(p)

  static var identifierP =
    withSpacing(identifierR.regexParser());

  static var jsonDataP =
    identifierP.then(JsData).lazyF();
    
  static var jsonArrayP =
    leftBracketP._and(jsonValueP.repsep(commaP)).and_(rightBracketP).then(JsArray).lazyF();
    
  static var jsonValueP : Void -> Parser<JsValue> =
    [jsonParser, jsonDataP, jsonArrayP].ors().lazyF();

  static var jsonEntryP =
    identifierP.and_(sepP).and(jsonValueP).lazyF();
  
  static  var jsonEntriesP =
    jsonEntryP.repsep(commaP).lazyF();

  public static var jsonParser =
    leftAccP._and(jsonEntriesP).and_(rightAccP).then(function (entries)
      return JsObject(entries.map(makeField).array())
    ).lazyF();
}

class LRTest {

  static var posNumberR = ~/[0-9]+/;
  
  static var plusP = "+".identifier();
  
  static var posNumberP =
    posNumberR.regexParser().lazyF().memo().lazyF();
    
  static var binop = expr.and_(plusP).andWith(expr, function (a, b) return a + " + " + b).lazyF().memo().lazyF();
  public static var expr : Void -> Parser<String> = binop.or(posNumberP).lazyF().memo().lazyF();
}

class ParserTest {

  static function tryParse<T>(str : String, parser : Parser<T>, withResult : T -> Void) {
    try {
      switch (parser(str.reader())) {
        case Success(res, rest):
          withResult(res);
        case Failure(err, rest):
          err.map(function (err) {
            trace("Error..");
            trace("Error at " + err.pos + " : " + err.msg);
          });        
      }     
    } catch (e : Dynamic) {
      trace("Error " + Std.string(e));
    }    
  }
  
  public static function jsonTest() {

    tryParse(
      " {  aaa : aa, bbb : [cc, dd] } ", // , bbb : ccc } ";
      JsonParser.jsonParser(),
      function (res) trace("Parsed " + JsonPrettyPrinter.prettify(res))
    );
    
    tryParse(
      "5+3",
      LRTest.expr(),
      function (res) trace("Parsed " + res)
    );
    
  }
  
}

