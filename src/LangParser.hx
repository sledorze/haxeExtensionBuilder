package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.text.Parser;
import haxe.Timer;
import js.JQuery;
import js.Lib;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

using com.mindrocks.macros.LazyMacro;

using Lambda; 

// Parse a definition base on text based specification of expressions.
/*
			Letrec("factorial", // letrec factorial =
				Lambda("n",    // fn n =>
					Apply(
						Apply(   // cond (zero n) 1
							Apply(Ident("cond"),     // cond (zero n)
								Apply(Ident("zero"), Ident("n"))),
							Ident("1")),
						Apply(    // times n
							Apply(Ident("times"), Ident("n")),
							Apply(Ident("factorial"),
								Apply(Ident("pred"), Ident("n")))
						)
					)
				),      // in
				Apply(Ident("factorial"), Ident("5"))
			),
*/

enum PrimitiveType {
  Number(x : Int);
  FloatNumber(x : Float);
}

typedef Identifier = String;

enum RExpression {
  Primitive(p : PrimitiveType);
  Ident(id : Identifier);
  LambdaExpr(param : Identifier, expr : Expression);
  Apply(fun : RExpression, param : Identifier);
}

typedef LetExpression = {
  ident : Identifier,
  expr : RExpression
}

typedef Expression = {
  lets : Array<LetExpression>,
  expr : RExpression
}

typedef Definition = {
  name : Identifier,
  expr : Expression
}

class LambdaTest {
  
  static var identifierR = ~/[a-zA-Z0-9_-]+/;
  static var numberR = ~/[-]*[0-9]+/;

  static  var spaceP = " ".identifier().lazyF();    
  static  var tabP = "\t".identifier().lazyF();
  static  var retP = ("\r".identifier().or("\n".identifier())).lazyF();
  
  static  var spacingP =
    [
      spaceP.oneMany(),
      tabP.oneMany(),
    ].ors().many().lazyF();
  
  static  var spacingOrRetP =
    [
      spaceP.oneMany(),
      tabP.oneMany(),
      retP.oneMany()
    ].ors().many().lazyF();
    
  static  var stringStartP = withSpacing("\"".identifier());
  static  var stringStopP = "\"".identifier();
  static  var leftAccP = withSpacing("{".identifier());
  static  var rightAccP = withSpacing("}".identifier());
  static  var leftBracketP = withSpacing("[".identifier());
  static  var rightBracketP = withSpacing("]".identifier());
  static  var sepP = withSpacing(":".identifier());
  static  var commaP = withSpacing(",".identifier());
  static  var equalsP = withSpacing("=".identifier());
  static  var arrowP = withSpacing("=>".identifier());
  static  var dotP = ".".identifier();
  
  static function maybeRet<T>(p : Void -> Parser<T>) return 
    spacingOrRetP.option()._and(p)
    
  static function withSpacing<T>(p : Void -> Parser<T>) return
    spacingP._and(p).lazyF()

  static var identifierP =
    withSpacing(identifierR.regexParser()).tag("identifier").lazyF();

  static  var letP = withSpacing("let".identifier()).lazyF();
  static  var inP = withSpacing("in".identifier()).lazyF();
  
  static var identP : Void -> Parser<RExpression> =
    identifierP.then(function (id) return Ident(id)).tag("identifier").lazyF();

  static var numberP : Void -> Parser<PrimitiveType> =
    numberR.regexParser().then(function (n) return Number(Std.parseInt(n)));
  
  static var floatNumberP : Void -> Parser<PrimitiveType> = // TODO: change this!
    numberP.and_(dotP).and(numberP).then(function (p) return FloatNumber(Std.parseFloat(p.a + "." + p.b)));
  
// TODO
//  static var stringP =
//    stringStartP._and(    
    
  static var primitiveP : Void -> Parser<RExpression> = [
      floatNumberP,
      numberP,
    ].ors().then(Primitive).tag("primitive").lazyF();
    
  static var lambdaP : Void -> Parser<RExpression> =
    identifierP.and_(arrowP).and(maybeRet(expressionP.commit())).then(function (p) return LambdaExpr(p.a, p.b)).tag("lambda").lazyF();
  
  static var applicationP : Void -> Parser<RExpression> =
    rExpressionP.and(identifierP).then(function (p) return Apply(p.a, p.b)).tag("application").lazyF();
  
  static var rExpressionP : Void -> Parser<RExpression> =
    [
      lambdaP,
      applicationP,
      identP,
      primitiveP
    ].ors().memo().tag("RExpression").lazyF();
    
  static var letExpressionP : Void -> Parser<LetExpression> =
    identifierP.and_(equalsP).and(maybeRet(rExpressionP.commit())).then(function (p) return { ident: p.a, expr: p.b }).tag("let expression").lazyF();
  
  public static var expressionP : Void -> Parser<Expression> =
    (letP._and(maybeRet(maybeRet(letExpressionP).rep1sep(commaP.or(retP)).and_(commaP.option())).and_(maybeRet(inP)).commit())).option().and(maybeRet(rExpressionP)).then(function (p) {
      var lets =
        switch (p.a) {
          case Some(ls): ls;
          case None: [];
        };
      return { lets : lets, expr : p.b };
    }).tag("expression").lazyF();
    
    
  static var definitionP =
    maybeRet(identifierP).and_(equalsP).and(maybeRet(expressionP.commit())).then(function (p) return { name : p.a, expr : p.b } ).tag("definition").lazyF();
    
  public static var programP =
    definitionP.many().tag("program").commit().lazyF();
  
}

class LangParser {

  static function tryParse<T>(str : String, parser : Parser<T>, withResult : T -> Void, output : String -> Void) {
    try {
      var res = 
        Timer.measure(function () return parser(str.reader()));
      
      switch (res) {
        case Success(res, rest):
          var remaining = rest.rest();
          if (StringTools.trim(remaining).length == 0) {
            trace("success!");            
          } else {
            trace("cannot parse " + remaining);
          }
          withResult(res);
        case Failure(err, rest, _):
          var p = rest.textAround();
          output(p.text);
          output(p.indicator);          
          err.map(function (err) {
            output("Error at " + err.pos + " : " + err.msg);
          });
          
          
      }
    } catch (e : Dynamic) {
      trace("Error " + Std.string(e));
    }    
  }
  
  public static function langTest() {
    
    var elem = Lib.document.getElementById("haxe:trace");
    if (elem != null) {
      new JQuery(elem).css("font-family", "Courier New, monospace");      // monospace!
    }
    
    function toOutput(str : String) {
      trace(StringTools.replace(str, " ", "_"));
    }

    tryParse("
      toto =
        let
          a = 56
          b = d
          v = a =>
            let x = 12
            in x
          b = d
        in
          add c d          
    ",
      LambdaTest.programP(),
      function (res) trace("Parsed " + Std.string(res)),
      toOutput
    );
    
  }
  
}

//  Sensitive layout requiers another kind of parsing phase, .. and must provide a way to reorganize code while keeping position information / coherence (without the lexer phase!)
//  Regarder ce qui avait ete propose pour les quotations et le layout.. (peut etre qq chose d'interessant a cette intersection.. -> Tree at language level)  

// Compile-time et runtime stagging blurred.. type level manipulation to remove by param number repetition.
// Very lightweight code with runtime inlining (call site specification with depth limitation).
// Type class approach (variables implicits and call site inlining).
// Type states and phantom types.
// Pattern matching and auto boxing of Anonymous unions.
// Trampoline.
// Scope manipulation in metaprogramming (!?! Relationnal Query Style? awesome.. cope with fresh names, etc.. annotation propagation)
// No inheritence! Structural typing (and good error report).
// Monad support aka Higher order Kinds.
// Operator overloading and free variable naming (think JSON - mongodb needs).
// Dependent typing (almost thanks to stagging).
// Intuition; Neko makes it at the wrong level (should be web).
