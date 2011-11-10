package com.mindrocks.structure;

/**
 * ...
 * @author sledorze
 */

// represents of all acceptables structures of an Object, including alternatives.
// Iteration would go:
//   object is Dynamic.
//     add an alternative node.
//     set some variables, objects not corresponding are shown.
//     refine variables types and/or structure.
//     name structures to reuse them.
//
//   stats per structure.
//
//   repair non conformming entries.
//
//   output well behaving parsers.
//
//   provides type safe migration scripts.
//

// recursive types??? (!)

// allow everything.

// Parsing Structure.
// Parsed result.
// .

using Std;
import Prelude;
using Prelude;
import PreludeExtensions;
using PreludeExtensions;
using haxe.data.collections.ArrayExtensions;
import haxe.data.collections.Map;
using haxe.data.collections.MapExtensions;

typedef NamedValue<T> = {
  name : String,
  value : T
}


enum JsDefValue<NextT> {
  JsDefString;
  JsDefNumber;
  JsDefDynamic;
  JsDefObj(fields : Array<NamedValue<NextT>>);
  JsDefArray(def : NextT);
}

enum Choice<T> {
  Nothing;
  Or(xs : Array<Choice<T>>);
  Elem(x : T);
}
typedef JsChoice = Choice<JsDefValue<JsChoice>>

enum JsValidValue<NextT> {
  JsValString;
  JsValNumber;
  JsValDynamic;
  JsValObj(fields : Array<NamedValue<NextT>>);
  JsValArray(elems : Array<NextT>);
}

enum ValidChoice<T> {
  ValNothing;
  ValOr(valids : Array<Validation<ValidChoice<T>>>);
  ValElem(x : JsValidValue<Validation<ValidChoice<T>>>);
}
typedef JsValidChoice = ValidChoice<JsValidValue<JsValidChoice>>

enum Validation<T> {
  Valid(x: JsValidChoice); // everything under is valid.
  Partial(x: JsValidChoice); // not everything under is valid
  Failed(x: JsChoice, specimen : Array<Dynamic>); // invalid
}
typedef JsValidation = Validation<JsValidChoice>

class Repr {

  public static function isValid<T>(x : Validation<T>) : Bool return
    switch (x) {
      case Valid(_): true;
      case Partial(_): false;
      case Failed(_, _): false;
    }

  public static function defFrom(obj : Dynamic) : JsChoice return {
    if (obj == null) { /*TODO: represent Null*/    
      Nothing;
    } else if (obj.is(String)) {
      Elem(JsDefString);
    } else if (obj.is(Int) || obj.is(Float)) {
      Elem(JsDefNumber);
    } else if (obj.is(Array) == true) {
      var elems : Array<Dynamic> = cast(obj, Array<Dynamic>);
      var elemDefs =  elems.map(defFrom);
      var uniqueDefs = elemDefs.toSet().toArray(); // uniques
      var elemDef : JsChoice = 
        if (uniqueDefs.length == 0) {
          Nothing;
        } else if (uniqueDefs.length == 1) {
          uniqueDefs[0];
        } else {
          Or(uniqueDefs);
        }
        
      Elem(JsDefArray(elemDef));
    } else { // Object
      var namedValues =
        Reflect.fields(obj).foldl([], function (acc, fieldName) {
          var value = Reflect.field(obj, fieldName);
          var newValue = { name : fieldName, value : defFrom(value) };
          acc.push(newValue);
          return acc;
        });
      Elem(JsDefObj(namedValues));
    }
  }
  
  public static function areSame(a : JsChoice, b : JsChoice) : Bool {
    throw "implement"; return null;
  }
  
  public static function includes(a : JsChoice, b : JsChoice) : JsChoice {    
    throw "implement"; return null;
  }

  public static function merge(a : JsChoice, b : JsChoice) : JsChoice {
    throw "implement"; return null;
  }
    
  // returns the matchings and failures (a tree with all rules, if they matched or failed and the reasons).
  public static function validatesObj(choice : JsChoice, obj : Dynamic) : JsValidation {
    var res =
      switch (choice) {
        case Nothing:
          if (obj==null)
            Valid(ValNothing);
          else
            Failed(choice, [obj]);
        case Or(xs) :
          var results = xs.map(function (choice) return validatesObj(choice, obj));
          var validResults = results.filter(isValid);
          if (validResults.length > 0) {
            Valid(ValOr(validResults));
          }
        case Elem(def):
          var res =
            switch (def) {
              case JsDefString : 
                obj.is(String) ? Valid(ValElem(JsValString)) : Failed(Elem(def), obj);
                
              case JsDefNumber : 
                (obj.is(Int) || obj.is(Float)) ? Valid(ValElem(JsValNumber)) : Failed(Elem(def), obj);
                
              case JsDefDynamic : 
                Valid(ValElem(JsValDynamic));
              
              case JsDefObj(fields) :
                var nameAndValues =
                  Reflect.fields(obj).foldl(Map.create(), function (acc, fieldName) return acc.add(fieldName.entuple(Reflect.field(obj, fieldName))));
                
                var missingField = false;
                
                var results = 
                  fields.map(function (field) return {
                    name  : field.name,
                    value :
                      switch(nameAndValues.get(field.name)) {
                        case None: missingField = true; Failed(field.value, []);
                        case Some(subObj): validatesObj(field.value, subObj);
                      }
                  });
                  
                if (missingField) {
                  Failed(Elem(def), [obj]);
                } else {
                  if (results.forAll(function (field) return isValid(field.value))) {
                    Valid(ValElem(JsValObj(results)));
                  } else {
                    Partial(ValElem(JsValObj(results)));
                  }
                }
                
              case JsDefArray(elemDef) :
                if (obj.is(Array) == true) {
                  var elems : Array<Dynamic> = cast(obj, Array<Dynamic>);
                  var results = elems.map(function (value) return validatesObj(elemDef, value));

                  if (results.forAll(isValid)) {
                    Valid(ValElem(JsValArray(results)));
                  } else {
                    Partial(ValElem(JsValArray(results)));
                  }
                } else {
                  Failed(Elem(def), [obj]);
                }
            };
          res;
      };
    return res;
  }

  
}