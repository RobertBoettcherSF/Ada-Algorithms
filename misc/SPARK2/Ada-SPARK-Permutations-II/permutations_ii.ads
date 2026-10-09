pragma SPARK_Mode (On);

--  Distinct permutations of a list that may repeat items, in dictionary
--  order. An Arrangement keeps the items unchanged and arranges them
--  through an index permutation Order (position K shows Items (Order (K)))
--  with its inverse Place; the predicate keeps Order and Place inverse, so
--  every arrangement shows exactly the items of the list, each as often.
--
--  Next_Permutation moves to the next distinct arrangement in dictionary
--  order of the shown values: equal items are never swapped with each
--  other, so no arrangement repeats. From the last one (values never
--  increasing) it wraps around to the sorted one and sets Found to False.
--
--  Count_Distinct (Items) = N! / (m1! m2! ..), where m1, m2, .. are how
--  often each value occurs, for N <= 12. Why 12: the computation goes
--  through N!, and 12! = 479_001_600 fits Natural, 13! = 6_227_020_800
--  does not. Next_Permutation does no counting; its only bound is
--  Positive'Last - 1 (it reads index K + 1).
package Permutations_II is
   type Index_Array is array (Positive range <>) of Positive;
   type Value_Array is array (Positive range <>) of Integer;

   subtype Length is Natural range 0 .. Positive'Last - 1;

   type Arrangement (N : Length) is record
      Items : Value_Array (1 .. N);
      Order : Index_Array (1 .. N);
      Place : Index_Array (1 .. N);
   end record
   with Dynamic_Predicate =>
     (for all K in 1 .. Arrangement.N =>
        Arrangement.Order (K) <= Arrangement.N and then Arrangement.Place (Arrangement.Order (K)) = K)
     and then (for all V in 1 .. Arrangement.N =>
                 Arrangement.Place (V) <= Arrangement.N and then Arrangement.Order (Arrangement.Place (V)) = V);

   subtype List is Value_Array
   with Dynamic_Predicate => List'First = 1 and then List'Last in Length;

   --  The values as currently arranged.
   function Values (A : Arrangement) return Value_Array is
     ([for K in 1 .. A.N => A.Items (A.Order (K))]);

   --  The items in their given order.
   function Start (Items : List) return Arrangement
   with Post => Start'Result.N = Items'Length and then Start'Result.Items = Items
                and then Values (Start'Result) = Items;

   --  The last arrangement: the values never increase.
   function Is_Last (A : Arrangement) return Boolean is
     (for all K in 1 .. A.N - 1 => A.Items (A.Order (K)) >= A.Items (A.Order (K + 1)));

   --  The first arrangement: the values never decrease.
   function Is_Sorted (A : Arrangement) return Boolean is
     (for all K in 1 .. A.N - 1 => A.Items (A.Order (K)) <= A.Items (A.Order (K + 1)));

   --  A comes before B in dictionary order.
   function Lex_Less (A, B : Value_Array) return Boolean is
     (A'First = B'First and then A'Last = B'Last
      and then (for some I in A'Range =>
                  A (I) < B (I) and then (for all K in A'First .. I - 1 => A (K) = B (K))))
   with Ghost;

   procedure Next_Permutation (A : in out Arrangement; Found : out Boolean)
   with
     Global => null,
     Post   => A.Items = A.Items'Old
               and then Found = not Is_Last (A'Old)
               and then (if Found then Lex_Less (Values (A'Old), Values (A)) else Is_Sorted (A));

   subtype Small_List is List
   with Dynamic_Predicate => Small_List'Last <= 12;

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

   --  How many of Items (1 .. J) equal V.
   function Count_Equal (Items : Small_List; V : Integer; J : Natural) return Natural
   with
     Ghost,
     Pre                => J <= Items'Last,
     Post               => Count_Equal'Result <= J,
     Subprogram_Variant => (Decreases => J);

   --  The K-th item is the Seen-th copy of its value in Items (1 .. K).
   function Seen (Items : Small_List; K : Positive) return Positive is
     (Count_Equal (Items, Items (K), K))
   with Ghost, Pre => K <= Items'Last;

   --  Seen (1) * .. * Seen (K) = the product of m! over the values of
   --  Items (1 .. K).
   function Copies (Items : Small_List; K : Natural) return Positive
   with
     Ghost,
     Pre                => K <= Items'Last,
     Post               => Copies'Result <= Fact (K),
     Subprogram_Variant => (Decreases => K);

   --  The number of distinct arrangements of Items.
   function Count_Distinct (Items : Small_List) return Factorial_Value
   with
     Global => null,
     Post   => Count_Distinct'Result = Fact (Items'Last) / Copies (Items, Items'Last);

private
   function Count_Equal (Items : Small_List; V : Integer; J : Natural) return Natural is
     (if J = 0 then 0 else Count_Equal (Items, V, J - 1) + (if Items (J) = V then 1 else 0));

   function Copies (Items : Small_List; K : Natural) return Positive is
     (if K = 0 then 1 else Copies (Items, K - 1) * Seen (Items, K));

   function Fact (N : Count_Range) return Factorial_Value is
     (if N = 0 then 1 else N * Fact (N - 1));
end Permutations_II;
