package ;

/**
 * ...
 * @author sledorze
 */
import com.mindrocks.macros.ExtendsMacro;
import js.JQuery;

class Foo<T, U> {
  public function new() {
    
  }
}

class Tata {
  
}
class Toto {
  
}

class MyJQueryPluginExtension implements Extends<JQuery> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestExtension implements Extends<Foo<Toto, Tata>> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

typedef Joe = {
  tata : Int,
  toto : String
}

class TestTypedefExtension implements Extends<Joe> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet<T>(x : T, cb : Int -> Void ) : Void;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestStructExtension implements Extends<{ tata : Int, toto : Array<String> -> Int -> { b : Bool, c : Int } }> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

class TestFunExtension implements Extends<Toto -> Void -> Tata> {
  @:native(val) public function valGet() : Dynamic;
  @:native(val) public function valSet(x : Dynamic) : JQuery;
  @:native(val) public function valFun(f : Int -> Dynamic -> Dynamic) : JQuery;
}

/*
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
*/

using ExtensionTest;

import js.JQuery;
// import Extensions;
// using Extensions;

class ExtensionTest {

  public static function compilationTest() {
    
    var jq = new JQuery("#someId");
    
    jq.valGet(); // generates jq.val();
    jq.valSet("content"); // generates jq.val("content");
    jq.valFun(function (i, v) return v); // jq.val(function (i, v) { return v;});
    
    var foo = new Foo<Toto, Tata>();
    
    var x = {
      tata : 5,
      toto : function (a : Array<String>, b: Int) : { b : Bool, c : Int } {
        return null;
      }
    };

    x.valFun(function (x, y) { } );
    
    var joe : Joe = {
      tata : 5,
      toto : "toto"
    };
    
    var z = joe.valSet(5, function (i) { } );

//    var x = joe.valSet.cc; // (5); // just to verify we can chain with other using extensions.. (nice, nice)

  }
}

