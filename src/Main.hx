package ;

/**
 * ...
 * @author sledorze
 */
 
import js.JQuery;
using MyJQueryPluginExtension;
 
class Main {
	
	static function main() {
    var jq = new JQuery("#someId");
    
    jq.valGet(); // generates jq.val();
    jq.valSet("content"); // generates jq.val("content");
    jq.valFun(function (i, v) return v); // jq.val(function (i, v) { return v;});
	}
  
}