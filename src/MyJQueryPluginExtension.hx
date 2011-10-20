package ;

/**
 * ...
 * @author sledorze
 */
import JQueryExtension;
import js.JQuery;

class MyJQueryPluginExtension implements JQueryExtension {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}
