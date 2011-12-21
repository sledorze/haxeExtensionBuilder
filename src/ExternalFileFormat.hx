
using com.mindrocks.macros.ExternalFileFormatMacro;

import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * ...
 * @author sledorze
 */

class ExternalFileFormat {

  public static function processTest() {
    
    var toto = "c'est toto!";    
    var result = "bin/testformat.html".formatFile();
    
    trace("result: " + result);
  }
  
}