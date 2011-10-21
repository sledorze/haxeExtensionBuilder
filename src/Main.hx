package ;

/**
 * ...
 * @author sledorze
 */
 
import js.JQuery;
import Extensions;
using Extensions;
// import JQueryExtension; 

class Main {
	
	static function main() {
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
    
    var joe : Joe =  {
      tata : Int,
      toto : String      
    };
    
    joe.valFun(function (x, y) { } );
    
	}
  
}