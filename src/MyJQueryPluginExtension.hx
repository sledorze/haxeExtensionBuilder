package ;

/**
 * ...
 * @author sledorze
 */
import com.mindrocks.macros.ExtensionBuilder;
import JQueryExtension;
import js.JQuery;

class MyJQueryPluginExtension implements GenExtension<JQuery> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestExtension implements GenExtension<Foo<Toto>> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
  
//  public static function toToto(x : { x : Int, y : String }, foo : String) {}
}
typedef Joe = {
  tata : Int, toto : String
}
class TestStructExtension implements GenExtension<{ tata : Int, toto : Array<String>}> {
// class TestStructExtension implements GenExtension<Joe> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}
