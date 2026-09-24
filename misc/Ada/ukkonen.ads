with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Ukkonen is
   type Suffix_Tree is private;

   -- Custom Exceptions
   Invalid_Input : exception;

   -- Core API
   function Build_Suffix_Tree (Text : String) return Suffix_Tree;
   function Contains_Substring (Tree : Suffix_Tree; Substr : String) return Boolean;

private
   use Ada.Strings.Unbounded;

   -- Use Natural to allow 0 (Null_Node) and Positive integers (real nodes).
   -- This resolves the a-convec.ads range check constraint error.
   subtype Node_Index is Natural;
   Null_Node : constant Node_Index := 0;
   Infinity  : constant Integer := Integer'Last;

   -- Array for O(1) character lookups, spanning all possible characters
   type Children_Array is array (Character) of Node_Index;

   -- Node Structure for Suffix Tree
   type Node is record
      Start_Index : Integer := 1;
      End_Index   : Integer := Infinity;
      Suffix_Link : Node_Index := Null_Node;
      Children    : Children_Array := (others => Null_Node);
   end record;

   -- Vector instantiated with Positive. 
   -- Extended_Index implicitly aligns perfectly with Natural (0 to limit).
   package Node_Vectors is new Ada.Containers.Vectors (
      Index_Type   => Positive,
      Element_Type => Node
   );

   -- Main state structure
   type Suffix_Tree is record
      Text          : Unbounded_String;
      Nodes         : Node_Vectors.Vector;
      Root          : Node_Index := Null_Node;
      Active_Node   : Node_Index := Null_Node;
      Active_Edge   : Integer := 0;
      Active_Length : Integer := 0;
      Remainder     : Integer := 0;
      Current_Phase : Integer := 0;
   end record;

end Ukkonen;
