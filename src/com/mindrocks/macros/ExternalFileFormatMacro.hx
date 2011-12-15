package com.mindrocks.macros;

#if macro
import haxe.macro.Context;
import neko.io.File;
#end
/**
 * ...
 * @author sledorze
 */

class ExternalFileFormatMacro {

  @:macro public static function formatFile(src : String) {
    #if macro
    var content = File.read(src).readAll().toString();    
//    return Context.parse("Std.format('"+content+"')", Context.currentPos());
    return Context.parse("Std.format('"+content+"')", Context.currentPos());
    #end
  }
  
}