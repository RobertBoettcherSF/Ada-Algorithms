pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (Count for N <= 12); Next_Subset and Subset do nothing yet.
package Subsets with SPARK_Mode => On is
   type Item_List is array (Positive range <>) of Integer;
   type Selection is array (Positive range <>) of Boolean;

   subtype Item_Count is Natural range 0 .. 30;
   subtype Small_Selection is Selection
   with Dynamic_Predicate => Small_Selection'First = 1 and then Small_Selection'Last in 0 .. 30;

   function Count (N : Item_Count) return Positive with Global => null;
   procedure Next_Subset (S : in out Small_Selection; Found : out Boolean) with Global => null;
   function Subset (Items : Item_List; S : Selection) return Item_List
   with Global => null, Pre => S'First = Items'First and then S'Last = Items'Last;
end Subsets;
