package ;

/**
 * ...
 * @author sledorze
 */
import com.mindrocks.macros.ExtendsType;
import js.JQuery;

class Foo<T, U> {
  public function new() {
    
  }
}

class Tata {
  
}
class Toto {
  
}

class MyJQueryPluginExtension implements ExtendsType<JQuery> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestExtension implements ExtendsType<Foo<Toto, Tata>> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

typedef Joe = {
  tata : Int,
  toto : String
}

class TestTypedefExtension implements ExtendsType<Joe> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestStructExtension implements ExtendsType<{ tata : Int, toto : Array<String> -> Int -> { b : Bool, c : Int } }> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestFunExtension implements ExtendsType<Toto -> Void -> Tata> {
  @:native("val") public function valGet() : Dynamic;
  @:native("val") public function valSet(x : Dynamic) : JQuery;
  @:native("val") public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}
