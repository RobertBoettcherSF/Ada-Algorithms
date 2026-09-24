with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Sort_Merge_Join is

   -- Strong typing for algorithm-specific data
   type Join_Key is new Integer;
   
   type Row is record
      Key  : Join_Key;
      Data : Unbounded_String;
   end record;

   type Relation is array (Positive range <>) of Row;

   type Joined_Row is record
      Left_Row  : Row;
      Right_Row : Row;
   end record;

   -- Using unbounded vectors for the output relation to handle 1-to-Many and Many-to-Many products dynamically
   package Joined_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Joined_Row);

   subtype Joined_Relation is Joined_Vectors.Vector;

   -- Algorithm Exceptions
   Unsorted_Relation_Error : exception;
   Non_Unique_Key_Error    : exception;

   -- Variant 1: Standard Inner Sort-Merge Join
   -- Fully supports Many-to-Many matching (Cartesian product on duplicates).
   -- If Auto_Sort is False and inputs are unsorted, raises Unsorted_Relation_Error.
   function Inner_Join
     (Left, Right : Relation; Auto_Sort : Boolean := True)
      return Joined_Relation;

   -- Variant 2: Unique-Key Sort-Merge Join (Optimized)
   -- Enforces that the Left relation has strictly unique keys (One-to-Many or One-to-One).
   -- Eliminates the need for backward backtracking, resulting in faster execution.
   -- Raises Non_Unique_Key_Error if Left relation contains duplicates.
   function Unique_Key_Join
     (Left, Right : Relation; Auto_Sort : Boolean := True)
      return Joined_Relation;

end Sort_Merge_Join;
