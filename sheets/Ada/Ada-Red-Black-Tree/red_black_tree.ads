package Red_Black_Tree is
   pragma Preelaborate;

   -- Custom types for algorithm-specific data to enforce strong typing.
   type Node_Key is new Integer range -1_000_000 .. 1_000_000;
   type Node_Value is new Float range -1.0e6 .. 1.0e6;

   type Tree is limited private;

   -- Exceptions for edge cases
   Empty_Tree_Error    : exception;
   Key_Not_Found_Error : exception;
   Duplicate_Key_Error : exception;

   -- 
   -- Core Variants & Operations
   --

   -- Inserts a new Key-Value pair into the tree.
   -- Raises Duplicate_Key_Error if the key already exists.
   procedure Insert (T : in out Tree; Key : Node_Key; Value : Node_Value)
     with Global => null;

   -- Deletes the node with the specified key.
   -- Raises Key_Not_Found_Error if the key is not in the tree.
   procedure Delete (T : in out Tree; Key : Node_Key)
     with Global => null;

   -- Retrieves the value associated with the given key.
   -- Raises Key_Not_Found_Error if the key is not found.
   function Search (T : Tree; Key : Node_Key) return Node_Value
     with Global => null;

   -- Returns True if the key exists in the tree.
   function Contains (T : Tree; Key : Node_Key) return Boolean
     with Global => null;

   -- Returns the smallest key in the tree.
   -- Raises Empty_Tree_Error if the tree is empty.
   function Minimum (T : Tree) return Node_Key
     with Global => null;

   -- Returns the largest key in the tree.
   -- Raises Empty_Tree_Error if the tree is empty.
   function Maximum (T : Tree) return Node_Key
     with Global => null;

   -- Returns the successor key in an in-order traversal.
   -- Raises Key_Not_Found_Error if the key doesn't exist or has no successor.
   function Successor (T : Tree; Key : Node_Key) return Node_Key
     with Global => null;

   -- Returns the predecessor key in an in-order traversal.
   -- Raises Key_Not_Found_Error if the key doesn't exist or has no predecessor.
   function Predecessor (T : Tree; Key : Node_Key) return Node_Key
     with Global => null;

   -- 
   -- Utility & Validation Functions
   --

   function Size (T : Tree) return Natural
     with Global => null;

   function Is_Empty (T : Tree) return Boolean
     with Global => null;

   -- Removes all elements from the tree and reclaims memory.
   procedure Clear (T : in out Tree)
     with Global => null;

   -- Validates all Red-Black Tree structural properties.
   -- Used extensively in testing to ensure correctness.
   function Is_Valid_Red_Black_Tree (T : Tree) return Boolean
     with Global => null;

private
   type Color_Type is (Red, Black);
   type Node;
   type Node_Access is access Node;

   type Node is record
      Key    : Node_Key;
      Value  : Node_Value;
      Color  : Color_Type := Red;
      Left   : Node_Access := null;
      Right  : Node_Access := null;
      Parent : Node_Access := null;
   end record;

   type Tree is record
      Root  : Node_Access := null;
      Count : Natural := 0;
   end record;
end Red_Black_Tree;
