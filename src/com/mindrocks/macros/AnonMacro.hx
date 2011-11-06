package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import com.mindrocks.text.Parser;
using com.mindrocks.text.Parser;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

//#if macro
using Lambda;
using Std;

enum Tree {
  TreeNode(name : String, sub : Array<Tree>);
  TreeValue(name : String, value : String);
}
/*
class ArrayObject {
  public static function equals<T>(t1 : Array<T>, t2 : Array<T>) return {
    t1.
  }
}
*/
class TreeObject {
  public static function equals(t1 : Tree, t2 : Tree) return {
    Std.string(t1) == Std.string(t2); // LOL
  }
}


//#end

class AnonMacro {
//  #if macro
  
  static var isHaxeIdentifier = ~/[a-zA-Z0-9_-]+/;
  
  inline static function treeName(tree : Tree) : String return
    switch (tree) {
      case TreeNode(name, _) : name;
      case TreeValue(name, _) : name;
    }
  
  inline static function partition<T>(l : Array<T>, pred : T -> Bool) : { match : Array<T>, others : Array<T> } return {
    var m = [];
    var o = [];
    for (e in l)
      if (pred(e))
        m.push(e);
      else
        o.push(e);
    {
      match : m,
      others : o
    };
  }
  
  inline static function treeHasIdentifierName(tree) return {
    var name = treeName(tree);
    isHaxeIdentifier.match(name);
    isHaxeIdentifier.matched(0).length == name.length;
  }

  static function extractTree(str : String) : Tree return {
    
    var treeStack : Array<Array<Tree>> = [[]];
    
    function addNode(tn : Tree)
      treeStack[treeStack.length - 1].push(tn);
    
    function popNode()
      treeStack.pop();
    
    function splitClean(str : String, pattern : String) : List<String> return
      str.split(pattern).map(StringTools.trim).filter(function (str) return str.length > 0); /*TODO: the place to optimize if requiered*/
    
    var forwardEntries = splitClean(str, "{");
    for (fentry in forwardEntries) {
      var backwardEntries = splitClean(fentry, "}");
      
      var x = backwardEntries.length;
      for (bentry in backwardEntries) {
        
        var entries = splitClean(bentry, ",");
        for (entry in entries ) {
          var parts = splitClean(entry, ":").array();
          
          var name = parts[0];
          var value : String = parts[1];
          
          if (value == null) {
            var newChilds = [];
            addNode(TreeNode(name, newChilds));
            treeStack.push(newChilds);
          } else {
            addNode(TreeValue(name, value));
          }
        }
        if (--x != 0) { // if not last          
          popNode();
        }
      }
    } 
    TreeNode("root", treeStack[0]);
  }

  static function extractTree2(str : String) : Tree return {
    
    
    var treeStack : Array<Array<Tree>> = [[]];
    
    function addNode(tn : Tree)
      treeStack[treeStack.length - 1].push(tn);
    
    function popNode()
      treeStack.pop();
    
    function splitClean(str : String, pattern : String) : List<String> return
      str.split(pattern).map(StringTools.trim).filter(function (str) return str.length > 0); /*TODO: the place to optimize if requiered*/
    
    var forwardEntries = splitClean(str, "{");
    for (fentry in forwardEntries) {
      var backwardEntries = splitClean(fentry, "}");
      
      var x = backwardEntries.length;
      for (bentry in backwardEntries) {
        
        var entries = splitClean(bentry, ",");
        for (entry in entries ) {
          var parts = splitClean(entry, ":").array();
          
          var name = parts[0];
          var value : String = parts[1];
          
          if (value == null) {
            var newChilds = [];
            addNode(TreeNode(name, newChilds));
            treeStack.push(newChilds);
          } else {
            addNode(TreeValue(name, value));
          }
        }
        if (--x != 0) { // if not last          
          popNode();
        }
      }
    } 
    TreeNode("root", treeStack[0]);
  }
  
  static function normalNodeGeneration(tree : Tree) return
    treeName(tree) + " : " + generateCode(tree)
  
  inline static function otherNodeGeneration(tree : Tree) return 
    "Reflect.setField(r_e_s, '" + treeName(tree) + "', " + generateCode(tree) + ");"

  static function generateCode(t : Tree) : String return {
    switch(t) {
      case TreeNode(name, subs) :
        // separate well named from others
        var parts = partition(subs, treeHasIdentifierName);
       
        var normalPart = "{"+parts.match.map(normalNodeGeneration).join(",")+"}";
        var otherParts = parts.others.map(otherNodeGeneration).join("");
            
        if (otherParts.length == 0) //everything is normal
          normalPart;
        else
          "{ var r_e_s = " + normalPart + "; " + otherParts + " r_e_s;}";
      
      case TreeValue(name, value) : value;
    }
  }
  //#end  

  @:macro public static function anon(str : String) : Expr return {
    var extract1 = extractTree(str);
    var extract2 = extractTree2(str);
    if (!TreeObject.equals(extract1, extract2))
      throw "not equals";
    var code = generateCode(extract2);
    trace("code " + code);
    Context.parse(code, Context.currentPos());
  }
}

