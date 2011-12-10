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


enum JsDef {
  JsDefString;
  JsDefNumber;
  JsDefDynamic;
  JsDefObj(fields : Array<NamedValue<JsDefs>>);
  JsDefArray(def : JsDefs);
}

typedef JsDefs = Array<JsDef>

enum JsValue {
  JsValString;
  JsValNumber;
  JsValDynamic;
  JsValObj(fields : Array<NamedValue<Validation>>);
  JsValArray(elems : Array<Validation>);
}

enum ValidStatus {
  Valid(valid : JsValue); // everything under is valid.
  Partial(valid : JsValue); // not everything under is valid
  Failed(); // invalid   
}

typedef ValidEntry = {
  choice : JsDefs,
  status : ValidStatus,
}

typedef Validation = {
  succeed : Array<ValidEntry>,
  partial : Array<ValidEntry>,
  failed : Array<ValidEntry>,
  obj : Option<Dynamic>,
}

class Repr {

  public static function isValid(x : Validation) : Bool return
    x.succeed.length > 0

  public static function validEntry(entry : ValidEntry) : Bool return
    switch (entry.status) {
      case Valid(_): true;
      default : false;
    }

  public static function partialEntry(entry : ValidEntry) : Bool return
    switch (entry.status) {
      case Partial(_): true;
      default : false;
    }

  public static function failedEntry(entry : ValidEntry) : Bool return
    switch (entry.status) {
      case Failed: true;
      default : false;
    }

  public static function defFrom(obj : Dynamic) : JsDefs return {
    if (obj == null) { /*TODO: represent Null*/    
      [];
    } else if (obj.is(String)) {
      [JsDefString];
    } else if (obj.is(Int) || obj.is(Float)) {
      [JsDefNumber];
    } else if (obj.is(Array) == true) {
      var elems : Array<Dynamic> = cast(obj, Array<Dynamic>);
      var elemDefs =  elems.map(defFrom);
      elemDefs.toSet().toArray().flatten(); // uniques
    } else { // Object
      var namedValues =
        Reflect.fields(obj).foldl([], function (acc, fieldName) {
          var value = Reflect.field(obj, fieldName);
          var newValue = { name : fieldName, value : defFrom(value) };
          acc.push(newValue);
          return acc;
        });
      [JsDefObj(namedValues)];
    }
  }
  
  public static function areSame(a : JsDefs, b : JsDefs) : Bool {
    throw "implement"; return null;
  }
  
  public static function includes(a : JsDefs, b : JsDefs) : JsDefs {    
    throw "implement"; return null;
  }

  public static function merge(a : JsDefs, b : JsDefs) : JsDefs {
    throw "implement"; return null;
  }
    
  // returns the matchings and failures (a tree with all rules, if they matched or failed and the reasons).
  public static function validatesObj(choices : JsDefs, obj : Dynamic) : Validation {
    
    function validateWithDef(def : JsDef) : ValidEntry {
      var status : ValidStatus =
        switch (def) {
          case JsDefString : 
            obj.is(String) ? Valid(JsValString) : Failed;
            
          case JsDefNumber : 
            (obj.is(Int) || obj.is(Float)) ? Valid(JsValNumber) : Failed;
            
          case JsDefDynamic : 
            Valid(JsValDynamic);
          
          case JsDefObj(fields) :
            var nameAndValues =
              Reflect.fields(obj).foldl(Map.create(), function (acc, fieldName) return acc.add(fieldName.entuple(Reflect.field(obj, fieldName))));
            
            var missingField = false;
            
            var results = 
              fields.map(function (field) return {
                name  : field.name,
                value :
                  switch(nameAndValues.get(field.name)) {
                    case Some(subObj): validatesObj(field.value, subObj);
                    case None:
                      missingField = true;
                      var res : Validation = {
                        succeed:[],
                        partial:[],
                        failed:[ { choice : field.value, status : Failed } ],
                        obj : None
                      };
                      res;
                  }
              });
            
            if (missingField) {
              Failed;
            } else {
              if (results.forAll(function (field) return isValid(field.value))) {
                Valid(JsValObj(results));
              } else {
                Partial(JsValObj(results));
              }
            }
            
          case JsDefArray(elemDef) :
            if (obj.is(Array) == true) {
              var elems : Array<Dynamic> = cast(obj, Array<Dynamic>);
              var results = elems.map(function (value) return validatesObj(elemDef, value));

              if (results.forAll(isValid)) {
                Valid(JsValArray(results));
              } else {
                Partial(JsValArray(results));
              }
            } else {
              Failed;
            }
        };
        return {
          choice : [def],
          status : status,
        };
    }

    var results : Array<ValidEntry> = choices.map(validateWithDef);

    return {
      succeed : results.filter(validEntry),
      partial : results.filter(partialEntry),
      failed : results.filter(failedEntry),
      obj : obj,
    };
  }

  
}