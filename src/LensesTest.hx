package ;

// import js.Lib;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.macros.Lense;
using com.mindrocks.macros.Lense;

import com.mindrocks.macros.LenseMacro;

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


class LensesTest {
	
	public static function compilationTest() {
    
    var userA : User = {
      age : 6,
      name : "georges",
      toto : function (x) return x
    };

    var userGroup :  UserGroup = {
      users : [userA, userA],
      lead : userA,  
    };

    trace("initial " + Std.string(userGroup));
    
    var ageOfUserGroupLead = UserGroup_.lead_.andThen(User_.age_);
    
    var result = ageOfUserGroupLead.set(5, userGroup);
    
    trace("original after modification " + Std.string(userGroup));
    trace("new result " + Std.string(result));
  }
	
}
