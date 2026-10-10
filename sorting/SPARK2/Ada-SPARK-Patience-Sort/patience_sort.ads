pragma Ada_2022;

--  Patience sort of 8 values (deal / pick the smallest pile top; D. Aldous
--  and P. Diaconis, "Longest increasing subsequences: from patience sorting
--  to the Baik-Deift-Johansson theorem", Bull. AMS 36 (1999), section 1).
--  Deal: each key in input order goes onto the leftmost pile whose top is
--  >= the key, or onto a new pile on the right, so every pile is
--  nonincreasing from bottom to top. Output: repeatedly remove the smallest
--  pile top (the leftmost pile on ties). The piles live in the array
--  itself, side by side (pile Q occupies Ends (Q - 1) + 1 .. Ends (Q), top
--  at Ends (Q)): putting a key on top of pile Q, or moving the top of pile
--  Q to the end of the output, is a rotation by adjacent exchanges, which
--  shifts the piles in between by one slot. The piles, their order and the
--  key moved at each step are those of the textbook description.
package Patience_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  Pile_Log (K): the pile of the K-th key dealt, or of the K-th removal.
   type Pile_Log is array (Index) of Index;

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

   --  Sort, also returning the pile of every key dealt (Deal), the pile of
   --  every removal (Take) and the number of piles (Piles).
   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Deal, Take : out Pile_Log; Piles : out Index)
     with Global => null,
          Post   => Is_Sorted (Output) and then Is_Perm (Output, Input);

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Patience_Sort;
