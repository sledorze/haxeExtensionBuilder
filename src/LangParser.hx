package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.text.Parser;
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

typedef Identifier = String;

enum RExpression {
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

class LambdaTest {
  
  static var identifierR = ~/[a-zA-Z0-9_-]+/;

  static  var spaceP = " ".identifier();    
  static  var tabP = "\t".identifier();
  static  var retP = ("\r".identifier().or("\n".identifier()));
  
  static  var spacingP =
    [
      spaceP.oneMany(),
      tabP.oneMany(),
      retP.oneMany()
    ].ors().many().lazyF();
  
  static  var leftAccP = withSpacing("{".identifier());
  static  var rightAccP = withSpacing("}".identifier());
  static  var leftBracketP = withSpacing("[".identifier());
  static  var rightBracketP = withSpacing("]".identifier());
  static  var sepP = withSpacing(":".identifier());
  static  var commaP = withSpacing(",".identifier());
  static  var equalsP = withSpacing("=".identifier());
  static  var arrowP = withSpacing("=>".identifier());
  
  
  static function withSpacing<T>(p : Void -> Parser<T>) return
    spacingP._and(p).lazyF()

  static var identifierP =
    withSpacing(identifierR.regexParser()).tag("identifier").lazyF();

  static  var letP = withSpacing("let".identifier());
  static  var inP = withSpacing("in".identifier());
  
  static var identP : Void -> Parser<RExpression> =
    identifierP.then(function (id) return Ident(id)).tag("identifier").lazyF();
  
  static var lambdaP : Void -> Parser<RExpression> =
    identifierP.and_(arrowP).and(expressionP.commit()).then(function (p) return LambdaExpr(p.a, p.b)).tag("lambda").lazyF();
  
  static var applicationP : Void -> Parser<RExpression> =
    rExpressionP.and(identifierP).then(function (p) return Apply(p.a, p.b)).tag("application").lazyF();
    
  static var rExpressionP : Void -> Parser<RExpression> =
    [
      lambdaP,
      applicationP,
      identP,
    ].ors().memo().tag("RExpression").lazyF();
    
  static var letExpressionP : Void -> Parser<LetExpression> =
    identifierP.and_(equalsP).and(rExpressionP.commit()).then(function (p) return { ident: p.a, expr: p.b }).tag("let expression").lazyF();
  
  public static var expressionP : Void -> Parser<Expression> =
    (letP._and(leftAccP)._and(letExpressionP.rep1sep(commaP)).and_(rightAccP).and_(inP)).and(leftAccP._and(rExpressionP).and_(rightAccP)).then(function (p) {
/*      var lets =
        switch (p.a) {
          case Some(ls): ls;
          case None: [];
        };*/
      return { lets : p.a, expr : p.b };
    }).tag("expression").lazyF();
    
    public static var programP =
      expressionP.tag("program").commit().lazyF();
      
}

class LangParser {

  static function tryParse<T>(str : String, parser : Parser<T>, withResult : T -> Void, output : String -> Void) {
    try {
      switch (parser(str.reader())) {
        case Success(res, rest):
          trace("success!");
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
      let {
        a = c,
        add = a b,
        b = d
      } in {
        add c d
      }
    ",
//      "let x == y; {  aaa : aa, bbb :: [cc, dd] } ", // , bbb : ccc } ";
      LambdaTest.programP(),
      function (res) trace("Parsed " + Std.string(res)),
      toOutput
    );
    
  }
  
}

