pragma Ada_2022;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;

-- | The Eclat_Algorithm package provides a robust implementation of the Eclat 
-- | (Equivalence Class Transformation) algorithm for frequent itemset mining.
-- | It includes both the Standard Eclat (using vertical database intersection) 
-- | and dEclat (using diffsets for memory and execution time optimization).
package Eclat_Algorithm is

   -- Domain-specific types to enforce strong typing
   type Item_ID is new Positive;
   type Transaction_ID is new Positive;
   type Support_Count is new Natural;

   -- Container for a set of Items
   package Item_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Item_ID);
   
   -- Container for a set of Transaction IDs
   package TID_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Transaction_ID);

   -- Represents a mined frequent itemset and its support count
   type Itemset_Type is record
      Items   : Item_Sets.Set;
      Support : Support_Count;
   end record;

   -- Vector container for holding the final mined itemsets
   package Itemset_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Itemset_Type);

   -- Opaque type for the Vertical Database representation
   type Vertical_DB is tagged private;

   -- Exception raised when minimum support is less than or equal to 0
   Invalid_Min_Support : exception;

   -- | Adds an item-transaction pair to the vertical database.
   -- | If the item doesn't exist, it creates a new TID set for it.
   -- | If the TID already exists for the item, it remains idempotent.
   procedure Add_Item_TID
     (DB   : in out Vertical_DB;
      Item : Item_ID;
      TID  : Transaction_ID);

   -- | Returns the number of unique items currently registered in the database.
   function Item_Count (DB : Vertical_DB) return Natural;

   -- | Empties the vertical database.
   procedure Clear (DB : in out Vertical_DB);

   -- | The Standard Eclat algorithm.
   -- | Explores the itemset search space in a depth-first manner using the 
   -- | intersection of TID sets to compute the support of itemsets.
   function Mine_Standard
     (DB      : Vertical_DB;
      Min_Sup : Support_Count) return Itemset_Vectors.Vector
     with Pre => Min_Sup > 0;

   -- | The dEclat algorithm variant.
   -- | Uses "diffsets" (differences of TID sets) instead of full TID sets.
   -- | This drastically reduces memory footprint and intersection time for dense datasets.
   function Mine_Diffset
     (DB      : Vertical_DB;
      Min_Sup : Support_Count) return Itemset_Vectors.Vector
     with Pre => Min_Sup > 0;

private

   -- Maps an Item_ID directly to its set of Transaction_IDs (Vertical format)
   package DB_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Item_ID,
      Element_Type => TID_Sets.Set,
      "="          => TID_Sets."=");

   type Vertical_DB is tagged record
      Data : DB_Maps.Map;
   end record;

end Eclat_Algorithm;
