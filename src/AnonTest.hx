package ;

/**
 * ...
 * @author sledorze
 */

using com.mindrocks.macros.AnonMacro;
 
class AnonTest {

  public static function compilationTest() {
    
    var res = 
      "
      {
        $inc : {
          toto.tata : 5,
          xzzzz : {
            tetete : '12',
            $inc : 5,
            $dec : 15,
            tototo : '54',
          }
          tata : 6,
        },
        $dec : {
          foo : 5
        },
      }
      ".anon();
      
    trace("anon " + Std.string(res));
    
  }
  
} 