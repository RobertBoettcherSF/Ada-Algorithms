pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  The distinct subsets of a list that may repeat items. The list is
--  given as its distinct values with how many copies of each it holds
--  (1 1 2 is the values 1, 2 with copies 2, 1). A distinct subset is then
--  a choice of how many copies of each value to take: Take (I) in
--  0 .. Copies (I). Next_Choice counts through all the choices like an
--  odometer, with the first value as the lowest digit. From the last one
--  (everything taken) it wraps around to the empty subset and sets Found
--  to False. Subset (Values, C) lists the chosen items, and Count (C) is
--  how many distinct subsets there are: the product of (Copies (I) + 1).
--
--  Limit: at most 30 items in all (Max_Items). Each value contributes a
--  factor Copies + 1 <= 2 ** Copies, so the count is at most 2 ** 30 =
--  1_073_741_824, which fits Natural; 31 distinct items would give 2 ** 31,
--  which does not.
package Subsets_II with SPARK_Mode => On is
   type Item_List is array (Positive range <>) of Integer;

   Max_Items : constant := 30;
   subtype Length is Natural range 0 .. Max_Items;
   type Count_List is array (Positive range <>) of Length;

   --  The first K entries summed: A (A'First) + .. + A (A'First + K - 1).
   --  Any origin (the Choice components below start at 1).
   function Total (A : Count_List; K : Natural) return Natural
   with
     Pre                => K <= A'Length and then K <= Max_Items,
     Post               => Total'Result <= Max_Items * K,
     Subprogram_Variant => (Decreases => K);

   type Choice (N : Length) is record
      Copies : Count_List (1 .. N);
      Take   : Count_List (1 .. N);
   end record
   with Dynamic_Predicate =>
     (for all I in 1 .. N => Copies (I) >= 1 and then Take (I) <= Copies (I))
     and then Total (Copies, N) <= Max_Items;

   --  (first entry + 1) * .. * (K-th entry + 1), in mathematical integers.
   function Product (A : Count_List; K : Natural) return Big_Integer
   with
     Ghost,
     Pre                => K <= A'Length,
     Subprogram_Variant => (Decreases => K);

   --  B is later than A when the highest position where they differ is
   --  higher in B (positions paired from each array's first index).
   function Colex_Less (A, B : Count_List) return Boolean is
     (for some I in A'Range =>
        A (I) < B (B'First + (I - A'First))
        and then (for all J in A'Range => (if J > I then A (J) = B (B'First + (J - A'First)))))
   with Ghost, Pre => A'Length = B'Length;

   function Count (C : Choice) return Positive
   with Global => null, Post => To_Big_Integer (Count'Result) = Product (C.Copies, C.N);

   procedure Next_Choice (C : in out Choice; Found : out Boolean)
   with
     Global => null,
     Post   => C.Copies = C.Copies'Old
               and then Found = (for some I in 1 .. C.N => C.Take'Old (I) < C.Copies (I))
               and then (if Found then Colex_Less (C.Take'Old, C.Take)
                         else (for all I in 1 .. C.N => C.Take (I) = 0));

   --  The value that position M of a subset belongs to: the last K <= Upto
   --  whose copies start before M (Total (A, K - 1) < M). For M <= Total
   --  (A, Upto) that K also has M <= Total (A, K), so position M holds one
   --  of the A (K) copies of value K.
   function Group (A : Count_List; M : Positive; Upto : Natural) return Natural
   with
     Ghost,
     Pre                => Upto <= A'Length and then Upto <= Max_Items,
     Post               => Group'Result <= Upto and then (if Upto >= 1 then Group'Result >= 1),
     Subprogram_Variant => (Decreases => Upto);

   --  Take (1) copies of the first value, then Take (2) copies of the
   --  second, .. (Values at any origin; position M of the result counted
   --  from its first index).
   function Subset (Values : Item_List; C : Choice) return Item_List
   with
     Global => null,
     Pre    => Values'Length = C.N,
     Post   => Subset'Result'Length = Total (C.Take, C.N)
               and then (for all M in 1 .. Subset'Result'Length =>
                           Subset'Result (Subset'Result'First - 1 + M)
                           = Values (Values'First - 1 + Group (C.Take, M, C.N)));

   --  2 ** K (ghost; the proof checks it doubles, the tests regenerate it).
   Pow2 : constant array (Length) of Positive :=
     [1, 2, 4, 8, 16, 32, 64, 128,
      256, 512, 1_024, 2_048, 4_096, 8_192, 16_384, 32_768,
      65_536, 131_072, 262_144, 524_288, 1_048_576, 2_097_152, 4_194_304, 8_388_608,
      16_777_216, 33_554_432, 67_108_864, 134_217_728, 268_435_456, 536_870_912, 1_073_741_824]
   with Ghost;

private
   function Total (A : Count_List; K : Natural) return Natural is
     (if K = 0 then 0 else Total (A, K - 1) + A (A'First + (K - 1)));

   function Group (A : Count_List; M : Positive; Upto : Natural) return Natural is
     (if Upto = 0 then 0 elsif M > Total (A, Upto - 1) then Upto else Group (A, M, Upto - 1));

   function Product (A : Count_List; K : Natural) return Big_Integer is
     (if K = 0 then To_Big_Integer (1) else Product (A, K - 1) * To_Big_Integer (A (A'First + (K - 1)) + 1));
end Subsets_II;
