with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Maps;

package Nested_Loop_Join is

   -- Strong typing for algorithm-specific data
   type Key_Type is new Integer;
   type Data_Type is new Integer;

   -- Base Tuple representing a row in a relation
   type Tuple is record
      Key  : Key_Type;
      Data : Data_Type;
   end record;

   -- Array type representing a Relation (e.g., Table)
   type Tuple_Array is array (Positive range <>) of Tuple;

   -- Joined Tuple representing the result of a join
   type Joined_Tuple is record
      Outer_Key  : Key_Type;
      Outer_Data : Data_Type;
      Inner_Data : Data_Type;
   end record;

   -- Generic package to hold dynamically sized joined results
   package Joined_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Joined_Tuple);
      
   subtype Joined_Relation is Joined_Vectors.Vector;

   -- Exception for invalid parameters
   Invalid_Block_Size : exception;

   -----------------------------------------------------------------------------
   -- 1. Naive (Simple) Nested Loop Join
   -- Scans the inner relation entirely for every tuple in the outer relation.
   -- Time Complexity: O(|Outer| * |Inner|)
   -----------------------------------------------------------------------------
   function Naive_Nested_Loop_Join
     (Outer_Rel : Tuple_Array;
      Inner_Rel : Tuple_Array) return Joined_Relation;

   -----------------------------------------------------------------------------
   -- 2. Block Nested Loop Join
   -- Chunks the outer relation into blocks. For each block, the inner relation
   -- is scanned only once, reducing I/O overhead.
   -----------------------------------------------------------------------------
   function Block_Nested_Loop_Join
     (Outer_Rel  : Tuple_Array;
      Inner_Rel  : Tuple_Array;
      Block_Size : Integer) return Joined_Relation;

   -----------------------------------------------------------------------------
   -- 3. Index Nested Loop Join
   -- Uses an Index over the inner relation to find matches instantly without
   -- scanning the entire inner relation.
   -----------------------------------------------------------------------------
   
   -- Hashing function for our Key_Type
   function Hash (K : Key_Type) return Ada.Containers.Hash_Type;

   -- A vector of tuples to allow 1-to-N relationships in the inner relation
   package Tuple_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tuple);

   -- EXPLICITLY make the Vector equality operator visible for the Hash Map
   use type Tuple_Vectors.Vector;

   -- Hash map acting as our Index
   package Inner_Index_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => Key_Type,
      Element_Type    => Tuple_Vectors.Vector,
      Hash            => Hash,
      Equivalent_Keys => "=",
      "="             => Tuple_Vectors."="); -- Explicit mapping to prevent visibility errors
      
   subtype Inner_Index is Inner_Index_Maps.Map;

   -- Helper: Builds a hash map index from a given relation
   function Build_Index (Inner_Rel : Tuple_Array) return Inner_Index;

   -- Index-based join execution
   function Index_Nested_Loop_Join
     (Outer_Rel : Tuple_Array;
      Index     : Inner_Index) return Joined_Relation;

end Nested_Loop_Join;
