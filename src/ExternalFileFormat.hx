
using com.mindrocks.macros.ExternalFileFormatMacro;

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