pragma Ada_2022;

--  Flashsort (K.-D. Neubert, "Flashsort1", Dr. Dobb's Journal, Feb. 1998)
--  of 8 values. Classification: with Min / Max of the input (nothing to do
--  when Min = Max), the class of X is 1 + ((Classes - 1) * (X - Min)) /
--  (Max - Min), Classes = 3 (about 0.42 n); class counts and their prefix
--  sums give L (K), the end of class K's region. The maximum is exchanged
--  into slot 1. Permutation (cycle leader): from the first slot not yet
--  placed, the key there (the "flash") is dropped at L (class of flash),
--  L (class) decreasing, and the key found there becomes the flash, until a
--  drop lands on the leader's own slot; repeated until n - 1 drops. Here
--  the flash stays in the leader slot and each drop is an exchange of the
--  leader slot with L (class): the same keys land in the same slots in the
--  same order as Neubert's flash / hold. Final pass: straight insertion
--  from the top, by adjacent exchanges.
package Flash_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   Classes : constant := 3;

   --  The slot of every drop of the permutation phase, in order.
   type Move_Log is array (Positive range <>) of Index;

   --  How many of A (1 .. Last) equal V.
   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural
   with Global             => null,
        Pre                => Last <= Index'Last,
        Post               => Occ'Result <= Last,
        Subprogram_Variant => (Decreases => Last);

   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural is
     (if Last = 0 then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B hold the same values, each equally often (Value has 32
   --  elements, so this is cheap to check at run time).
   function Is_Perm (A, B : Input_Array) return Boolean is
     (for all V in Value => Occ (A, V, Index'Last) = Occ (B, V, Index'Last))
   with Global => null;

   function Is_Sorted (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1))
   with Global => null;

   --  Sort, also returning the drop slots of the permutation phase
   --  (Moves (1 .. Count)).
   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Moves : out Move_Log; Count : out Natural)
     with Global => null,
          Pre    => Moves'First = 1 and then Moves'Last = Index'Last,
          Post   => Is_Sorted (Output) and then Is_Perm (Output, Input) and then Count <= Index'Last;

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Flash_Sort;
