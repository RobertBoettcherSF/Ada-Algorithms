pragma Ada_2022;

--  All subsets of a list by binary counting. A Selection says for each
--  item whether it is in the subset. Next_Subset counts up by one with
--  item 1 as the lowest bit, so stepping from the empty selection visits
--  all 2 ** N subsets once and then wraps around to the empty one (Found
--  is then False). Subset (Items, S) lists the selected items in order.
--
--  Count (N) = 2 ** N for N <= 30. Why 30: 2 ** 30 = 1_073_741_824 fits
--  Natural and 2 ** 31 does not. Selections that are counted through are
--  limited to the same 30 items (Small_Selection), so that their rank
--  is a Natural. Subset works on lists of any length.
package Subsets with SPARK_Mode => On is
   type Item_List is array (Positive range <>) of Integer;
   type Selection is array (Positive range <>) of Boolean;

   Max_Items : constant := 30;
   subtype Item_Count is Natural range 0 .. Max_Items;

   --  Any origin: position P (1 .. Length) is S (S'First + P - 1).
   subtype Small_Selection is Selection
   with Dynamic_Predicate => Small_Selection'Length <= Max_Items;

   --  2 ** K; the proof checks that each entry doubles the one before
   --  (Lemma_Pow2), and the tests regenerate it.
   Pow2 : constant array (Item_Count) of Positive :=
     [1, 2, 4, 8, 16, 32, 64, 128,
      256, 512, 1_024, 2_048, 4_096, 8_192, 16_384, 32_768,
      65_536, 131_072, 262_144, 524_288, 1_048_576, 2_097_152, 4_194_304, 8_388_608,
      16_777_216, 33_554_432, 67_108_864, 134_217_728, 268_435_456, 536_870_912, 1_073_741_824]
   with Ghost;

   --  Pow2 doubles from each entry to the next (Lemma_Pow2 proves it).
   function Pow2_Doubles return Boolean is
     (for all K in 1 .. Max_Items => Pow2 (K) = 2 * Pow2 (K - 1))
   with Ghost;

   --  The number the first L positions of S stand for, with S (S'First) the
   --  lowest bit: Rank (S, L) = Rank (S, L - 1) + (if S (S'First + L - 1)
   --  then 2 ** (L - 1)).
   function Rank (S : Small_Selection; L : Natural) return Natural
   with
     Ghost,
     Pre                => L <= S'Length and then Pow2_Doubles,
     Post               => Rank'Result < Pow2 (L),
     Subprogram_Variant => (Decreases => L);

   --  How many of S (S'First .. I) are True.
   function Count_True (S : Selection; I : Natural) return Natural
   with
     Ghost,
     Pre                => I in S'First - 1 .. S'Last,
     Post               => Count_True'Result <= I - (S'First - 1),
     Subprogram_Variant => (Decreases => I);

   function Count (N : Item_Count) return Positive
   with Global => null, Post => Count'Result = Pow2 (N);

   procedure Next_Subset (S : in out Small_Selection; Found : out Boolean)
   with
     Global => null,
     Post   => Found = (Rank (S'Old, S'Length) < Pow2 (S'Length) - 1)
               and then (if Found then Rank (S, S'Length) = Rank (S'Old, S'Length) + 1
                         else (for all K in S'Range => not S (K)));

   function Subset (Items : Item_List; S : Selection) return Item_List
   with
     Global => null,
     Pre    => S'Length = Items'Length,
     Post   => (if S'Length = 0 then Subset'Result'Length = 0
                else Subset'Result'Length = Count_True (S, S'Last)
                     and then (for all K in S'Range =>
                                 (if S (K) then Count_True (S, K) in 1 .. Subset'Result'Length
                                                and then Subset'Result (Subset'Result'First - 1 + Count_True (S, K))
                                                         = Items (Items'First + (K - S'First)))));
   --  Pow2 doubles (the precondition of Rank).
   procedure Lemma_Pow2
   with Ghost, Global => null, Post => Pow2_Doubles;

private
   function Rank (S : Small_Selection; L : Natural) return Natural is
     (if L = 0 then 0 else Rank (S, L - 1) + (if S (S'First + (L - 1)) then Pow2 (L - 1) else 0));

   function Count_True (S : Selection; I : Natural) return Natural is
     (if I < S'First then 0 else Count_True (S, I - 1) + (if S (I) then 1 else 0));
end Subsets;
