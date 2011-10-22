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
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestExtension implements ExtendsType<Foo<Toto, Tata>> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

typedef Joe = {
  tata : Int,
  toto : String
}

class TestTypedefExtension implements ExtendsType<Joe> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet<T>(x : T, cb : Int -> Void ) : Void;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestStructExtension implements ExtendsType<{ tata : Int, toto : Array<String> -> Int -> { b : Bool, c : Int } }> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestFunExtension implements ExtendsType<Toto -> Void -> Tata> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}


class Future<T> {
  static public function create<T>(x : T) : Future<T>  { return null;  }
  public function bind<U>(f : T -> Future<U>) : Future<U> { return null;  }
}

class Fut0 {
  public static function cc < R > (f : (R -> Void) -> Void) : Future<R> { return null; }
}
class Fut1 {
  public static function cc < A, R > (f : A -> (R -> Void) -> Void, a : A) : Future<R> { return null; }
}
class Fut2 {
  public static function cc < A, B, R > (f : A -> B -> (R -> Void) -> Void, a : A, b : B) : Future<R> { return null; }
}
class Fut3 {
  public static function cc < A, B, C, R> (f : A -> B -> C -> (R -> Void) -> Void, a : A, b : B, c : C) : Future<R> { return null; }
}

  /*
  public static function cc < A, B> (f : A -> (B -> Void) -> Void) : A -> Future<B> { // should return a future
    // ..
  }*/

