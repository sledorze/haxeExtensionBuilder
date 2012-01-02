package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.functional.monads.Standard;
using com.mindrocks.functional.monads.Standard;

import com.mindrocks.macros.NodeCont;
using com.mindrocks.macros.NodeCont;

// Fake classes

class Obj {
  var name : String;
  public function new(name : String) {    
    this.name = name;
  }
}

class Collection {
  var objs : Array<Obj>;
  public function new() { 
    objs = [new Obj("a"), new Obj("b")];
  }
  public function all(name : String) return function (cb : Error -> Array<Obj> -> Void) {    
    // cb("Aieeeuu!!", null);
    cb(null, objs);
  }
}

class DB {
  var coll : Collection;
  public function new() {
    coll = new Collection();
  }
  public function collection(name : String) return function (cb : Error -> Collection -> Void) {
    // cb("Aieeeuu!!", null);
    cb(null, coll);
  }
}

class MonadContTest {

  public static function compilationTest() {
    
    var db = new DB();
    
    var res =
      NodeM.Do({
        coll <= db.collection("avatars");
        avatars <= coll.all("");
        ret(avatars.length);
      })(function (err, res) trace("res " + err + " | " + res));
  }
  
}