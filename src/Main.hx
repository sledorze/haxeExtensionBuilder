package ;

/**
 * ...
 * @author sledorze
 */
 
class Main {
	
	static function main() {
    LensesTest.compilationTest();
    SubstTest.compilationTest();
   // MetaTest.compilationTest();
    ExtensionTest.compilationTest; // compile but no execution (it crashs, the test means nothing; it just can prove the macro works!)
	}
  
}