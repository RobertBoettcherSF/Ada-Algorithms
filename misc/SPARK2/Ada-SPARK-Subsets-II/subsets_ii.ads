pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (2 ** N for N <= 12 values); Next_Choice and Subset do
--  nothing yet.
package Subsets_II with SPARK_Mode => On is
   type Item_List is array (Positive range <>) of Integer;
   type Count_List is array (Positive range <>) of Natural;

   Max_Items : constant := 30;
   subtype Length is Natural range 0 .. Max_Items;

   type Choice (N : Length) is record
      Copies : Count_List (1 .. N);
      Take   : Count_List (1 .. N);
   end record;

   function Count (C : Choice) return Positive with Global => null;
   procedure Next_Choice (C : in out Choice; Found : out Boolean) with Global => null;
   function Subset (Values : Item_List; C : Choice) return Item_List
   with Global => null, Pre => Values'First = 1 and then Values'Last = C.N;
end Subsets_II;
