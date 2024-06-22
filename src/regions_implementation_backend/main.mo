import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Nat64 "mo:base/Nat64";
import Region "mo:base/Region";


actor{

  var users_data = TrieMap.TrieMap<Principal, Nat64>(Principal.equal, Principal.hash);
  // var users_Regions = R

// index of the user blob that will be stored in the Regions memory
  public type Index = Nat64;

  type GenderType={
    #male;
    #female;
  };

  type User={
    id:Principal;
    name:Text;
    email:Text;
    isAdmin:Bool;
    rating:Nat;
    gender:GenderType;
  };
  
  stable var state = {
    bytes = Region.new();
    var bytes_count : Nat64 = 0;
    elems = Region.new ();
    var elems_count : Nat64 = 0;
  };
    // Element = Position and size of a saved a Blob.
  type Elem = {
    pos : Nat64;
    size : Nat64;
  };

  func regionEnsureSizeBytes(r : Region, new_byte_count : Nat64) {
    let pages = Region.size(r);
    if (new_byte_count > pages << 16) {
      let new_pages = ((new_byte_count + ((1 << 16) - 1)) / (1 << 16)) - pages;
      assert Region.grow(r, new_pages) == pages
    }
  };

  let elem_size = 16 : Nat64; /* two Nat64s, for pos and size. */

  // Count of elements (Blobs) that have been logged.
  public func size() : async Nat64 {
      state.elems_count
  };

  func get(index : Index) : async Blob {
    assert index < state.elems_count;
    let pos = Region.loadNat64(state.elems, index * elem_size);
    let size = Region.loadNat64(state.elems, index * elem_size + 8);
    let elem = { pos ; size };
    Region.loadBlob(state.bytes, elem.pos, Nat64.toNat(elem.size))
  };

  // Add Blob to the log, and return the index of it.
  func add(blob : Blob) : async Index {
    let elem_i = state.elems_count;
    state.elems_count += 1;

    let elem_pos = state.bytes_count;
    state.bytes_count += Nat64.fromNat(blob.size());

    regionEnsureSizeBytes(state.bytes, state.bytes_count);
    Region.storeBlob(state.bytes, elem_pos, blob);

    regionEnsureSizeBytes(state.elems, state.elems_count * elem_size);
    Region.storeNat64(state.elems, elem_i * elem_size + 0, elem_pos);
    Region.storeNat64(state.elems, elem_i * elem_size + 8, Nat64.fromNat(blob.size()));
    elem_i
  };
  
  public shared({caller}) func storeuser(_userData:User):async Index{
    let user:User={
      id=caller;
      name=_userData.name;
      email=_userData.email;
      isAdmin=_userData.isAdmin;
      rating=_userData.rating;
      gender=_userData.gender;
    };
    let blob = to_candid(user);
    Debug.print("The blob for the " # debug_show(caller) # " is: " # debug_show(blob));
    let index = await add(blob);
    Debug.print("The index for the user data is " # debug_show(index));
    users_data.put(caller,index);
    return index;
  };
  
  public shared ({caller = User}) func getUser():async Result.Result<User,Text>{
    
    let index = users_data.get(User);
    switch(index){
      case(null){
        return #err("User not found");
      };
      case(?val){
        let blob = await get(val);
        Debug.print("The blob for the " # debug_show(User) # " is: " # debug_show(blob));
        let user : ?User = from_candid(blob);
        Debug.print("The user data for the " # debug_show(User) # " is: " # debug_show(user));
        switch(user){
          case(null){
            return #err("Empty user");
          };
          case(?val){
            return #ok(val);
          }
        }
      }
    };
  }
}