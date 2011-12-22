package ;

// import js.Lib;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.macros.Lense;
import haxe.macro.Expr;
using com.mindrocks.macros.Lense;

import com.mindrocks.macros.CacheMacro;

import com.mindrocks.macros.LensesMacro;

using Lambda;

typedef User = {
  age : Int,
  name : String,
  toto : String -> String
}

typedef UserGroup = {
  users : Array<User>,
  lead : User,  
}

class User_ implements LensesFor<User> {}
class UserGroup_ implements LensesFor<UserGroup> { }
class Anon_ implements LensesFor<{
  age : Int,
  name : String,
  toto : String -> String
}> {}

class Expr_ implements LensesFor<Expr> { }

class LensesTest {
	
	public static function compilationTest() {
    
    var userA : User = {
      age : 6,
      name : "georges",
      toto : function (x) return "Beh.. " + x
    };

    var userGroup :  UserGroup = {
      users : [userA, userA],
      lead : userA,  
    };
    
    var users = [userA, userA, userA];
        
    var useNames = users.map(User_.name_.get);
    
    users.map(callback(User_.name_.set, "georges"));
    
    

    trace("initial " + Std.string(userGroup));
    
    var ageOfUserGroupLead = UserGroup_.lead_.andThen(User_.age_);
    
    function complexUserModification(user) {
      var newUser : User = Reflect.copy(user);
      // do you complex stuff
      return newUser;
    }
    
    userGroup.mod(UserGroup_.lead_, complexUserModification);
    
    
    var newGroup = ageOfUserGroupLead.set(5, userGroup);
    
    // same as: syntactic Sugar through another extension.
    userGroup.set(ageOfUserGroupLead, 5);
    
    var leadAge = userGroup.get(ageOfUserGroupLead);
    
    trace("original after modification " + Std.string(userGroup));
    trace("new result " + Std.string(newGroup));
  }
	
}
