pragma Ada_2022;

--  Fisher-Yates shuffle (Durstenfeld's in-place form) driven by
--  caller-supplied choices: for I = Length down to 1, swap Data (I) with
--  Data (Choices (I)), where 1 <= Choices (I) <= I. Each of the Length!
--  valid choice vectors gives a different permutation, so uniform random
--  choices give a uniform random shuffle.
package Fisher_Yates_Shuffle with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Item is Integer range -100 .. 100;
   type Item_Array is array (Index) of Item;

   --  Choice for position I: one of positions 1 .. I.
   type Swap_Array is array (Index) of Index
   with Dynamic_Predicate => (for all I in Index => Swap_Array (I) <= I);

   --  Number of positions among 1 .. Upto holding V.
   function Occ (A : Item_Array; V : Item; Upto : Natural) return Natural
   with
     Ghost,
     Pre                => Upto <= Length,
     Post               => Occ'Result <= Upto,
     Subprogram_Variant => (Decreases => Upto);

   --  A and B hold the same values the same number of times.
   function Is_Perm (A, B : Item_Array) return Boolean is
     (for all V in Item => Occ (A, V, Length) = Occ (B, V, Length))
   with Ghost;

   procedure Shuffle (Data : in out Item_Array; Choices : Swap_Array)
   with Post => Is_Perm (Data, Data'Old);
private
   function Occ (A : Item_Array; V : Item; Upto : Natural) return Natural is
     (if Upto = 0 then 0
      else Occ (A, V, Upto - 1) + (if A (Upto) = V then 1 else 0));
end Fisher_Yates_Shuffle;
