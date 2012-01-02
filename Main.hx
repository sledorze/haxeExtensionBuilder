package ;

/**
 * ...
 * @author sledorze
 */

 import haxe.macro.Expr;
 
class Main {
	
	static function main() {

    /*
    ExternalFileFormat.processTest();        
    
    LangParser.langTest();
    
    MonadTest.compilationTest();
    */
    ParserTest.jsonTest();
    
    /*
    MonadContTest.compilationTest();
    
    StructureTest.test();
    
    // MergeTest.compilationTest(); // live lock
    
    LensesTest.compilationTest();
    
    StagedTest.compilationTest();    
    
    ExtensionTest.compilationTest; // compile but no execution (it crashs, the test means nothing; it just can prove the macro works!)
    */
	}
  
}