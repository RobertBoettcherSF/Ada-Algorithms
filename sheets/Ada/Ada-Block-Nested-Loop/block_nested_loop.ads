-- block_nested_loop.ads
package Block_Nested_Loop is

   -- Strong custom typing for the algorithm data
   type Key_Type is new Integer;
   type Data_Type is new Integer;

   -- Tuple representations for relations
   type Row_R is record
      Key  : Key_Type;
      Data : Data_Type;
   end record;

   type Row_S is record
      Key  : Key_Type;
      Data : Data_Type;
   end record;

   -- Resulting joined tuple
   type Joined_Row is record
      Key    : Key_Type;
      Data_R : Data_Type;
      Data_S : Data_Type;
   end record;

   -- Relations represented as unconstrained arrays
   type Table_R is array (Natural range <>) of Row_R;
   type Table_S is array (Natural range <>) of Row_S;
   type Joined_Table is array (Natural range <>) of Joined_Row;

   -- Exception for invalid configurations
   Invalid_Block_Size : exception;

   -- Variant 1: Standard Nested Loop Join (Naive iteration)
   -- Conceptual Block Size = 1. Used as a baseline.
   function Nested_Loop_Join 
     (R : Table_R; 
      S : Table_S) return Joined_Table;

   -- Variant 2: Block Nested Loop Join
   -- Reduces inner loops by comparing entire outer blocks against the inner relation.
   function Block_Nested_Loop_Join 
     (R          : Table_R; 
      S          : Table_S; 
      Block_Size : Integer) return Joined_Table;

end Block_Nested_Loop;
