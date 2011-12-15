
using com.mindrocks.macros.ExternalFileFormatMacro;

/**
 * ...
 * @author sledorze
 */

class ExternalFileFormat {

  public static function processTest() {
    
    var context = { toto : "c'est toto!" };
    var result = "bin/testformat.html".format(context);
    
    trace("result: " + result);
  }
  
}