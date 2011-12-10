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
            tetete : 12,
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
  
  /*
  {
    var r_e_s = { };
    Reflect.setField(r_e_s, '$inc', {
      var r_e_s = {
        xzzzz : {
          var r_e_s = {
            tetete : '12',
            tototo : '54'
          };
          Reflect.setField(r_e_s, '$inc', 5);
          Reflect.setField(r_e_s, '$dec', 15);
          r_e_s;
        },
        tata : 6
      };
      Reflect.setField(r_e_s, 'toto.tata', 5);
      r_e_s;
    });
    Reflect.setField(r_e_s, '$dec', {
      foo : 5
    });
    r_e_s;
  }*/
} 