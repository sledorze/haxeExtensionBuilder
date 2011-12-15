package ;

/**
 * ...
 * @author sledorze
 */
 
class Main {
	
	static function main() {

    ExternalFileFormat.processTest();
    LangParser.langTest();
    MonadTest.compilationTest();
    ParserTest.jsonTest();
    StructureTest.test();
    MergeTest.compilationTest();
    JsonTest.compilationTest();    
    LensesTest.compilationTest();
    StagedTest.compilationTest();
    ExtensionTest.compilationTest; // compile but no execution (it crashs, the test means nothing; it just can prove the macro works!)
	}
  
}