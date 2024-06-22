import Map "mo:map/Map";
import { phash } "mo:map/Map";
import Principal "mo:base/Principal";

actor {

    type GenderType = {
        #male;
        #female;
    };

    type User = { 
        id: Principal;
        name: Text;
        email: Text;
        isAdmin: Bool;
        rating: Nat;
        gender: GenderType;
    };

    let users_map = Map.new<Principal, User>();

    public shared ({caller}) func addUsertoMap(user: User) : async User {
        Map.set(users_map, phash, caller, user);
        return user;
    }; 

    public shared ({caller}) func getUserfromMap() : async ?User {
        return Map.get(users_map, phash, caller);
    };
};
