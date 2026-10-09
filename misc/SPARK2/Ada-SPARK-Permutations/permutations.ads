pragma SPARK_Mode (On);

--  Permutations of N items in dictionary order. A Perm holds the
--  arrangement Order (position K takes item Order (K)) together with its
--  inverse Place (item V stands at position Place (V)); the predicate keeps
--  them inverse to each other, so Order holds every number 1 .. N once.
--
--  Next_Permutation moves P to the next permutation in dictionary order.
--  From the last one (N, N - 1, .., 1) it wraps around to the first
--  (1, 2, .., N) and sets Found to False. The proof shows that every step
--  keeps a permutation and goes strictly up in dictionary order; the tests
--  check by enumeration and by rank that it is the next one.
--
--  Count (N) = N! for N <= 12. Why 12: 12! = 479_001_600 fits Natural,
--  13! = 6_227_020_800 does not. Next_Permutation does no counting, so the
--  only bound on its length is Positive'Last - 1 (it uses index K + 1).
package Permutations is
   type Index_Array is array (Positive range <>) of Positive;

   subtype Length is Natural range 0 .. Positive'Last - 1;

   --  A permutation of 1 .. N with its inverse: position K holds item
   --  Order (K), and item V stands at position Place (V). The predicate
   --  makes each the inverse of the other, so Order holds every number
   --  1 .. N exactly once.
   type Perm (N : Length) is record
      Order : Index_Array (1 .. N);
      Place : Index_Array (1 .. N);
   end record
   with Dynamic_Predicate =>
     (for all K in 1 .. Perm.N => Perm.Order (K) <= Perm.N and then Perm.Place (Perm.Order (K)) = K)
     and then (for all V in 1 .. Perm.N => Perm.Place (V) <= Perm.N and then Perm.Order (Perm.Place (V)) = V);

   --  1, 2, .., N: the first permutation in dictionary order.
   function Identity (N : Length) return Perm
   with Post => Identity'Result.N = N and then (for all K in 1 .. N => Identity'Result.Order (K) = K);

   --  The last permutation: Order never increases.
   function Is_Last (P : Perm) return Boolean is
     (for all K in 1 .. P.N - 1 => P.Order (K) >= P.Order (K + 1));

   --  A comes before B in dictionary order.
   function Lex_Less (A, B : Index_Array) return Boolean is
     (A'First = B'First and then A'Last = B'Last
      and then (for some I in A'Range =>
                  A (I) < B (I) and then (for all K in A'First .. I - 1 => A (K) = B (K))))
   with Ghost;

   procedure Next_Permutation (P : in out Perm; Found : out Boolean)
   with
     Global => null,
     Post   => Found = not Is_Last (P'Old)
               and then (if Found then Lex_Less (P.Order'Old, P.Order)
                         else (for all K in 1 .. P.N => P.Order (K) = K));

   subtype Count_Range is Natural range 0 .. 12;
   subtype Factorial_Value is Positive range 1 .. 479_001_600;

   --  Ghost proof aid for the overflow bound: N! for N <= 12. The proof
   --  checks every entry against the recurrence (Post of Fact); the tests
   --  regenerate it. The code does not use it.
   function Fact_Table (N : Count_Range) return Factorial_Value is
     (case N is
        when 0 => 1, when 1 => 1, when 2 => 2, when 3 => 6, when 4 => 24,
        when 5 => 120, when 6 => 720, when 7 => 5_040, when 8 => 40_320,
        when 9 => 362_880, when 10 => 3_628_800, when 11 => 39_916_800,
        when 12 => 479_001_600)
   with Ghost;

   function Fact (N : Count_Range) return Factorial_Value
   with
     Ghost,
     Post               => Fact'Result = Fact_Table (N),
     Subprogram_Variant => (Decreases => N);

   --  The number of permutations of N items.
   function Count (N : Count_Range) return Factorial_Value
   with
     Global => null,
     Post   => Count'Result = Fact (N);

private
   function Fact (N : Count_Range) return Factorial_Value is
     (if N = 0 then 1 else N * Fact (N - 1));
end Permutations;
