pragma SPARK_Mode (On);

package body Permutations_II is
   --  The identity order 1 .. N (a function of N: an inline
   --  [for K in 1 .. Items'Length => K] range-checks the bound 0 against
   --  Positive at run time for an empty list).
   function Identity (N : Length) return Index_Array is
     ([for K in 1 .. N => K]);

   function Start (Items : List) return Arrangement is
     ((N => Items'Length, Items => Items, Order => Identity (Items'Length),
       Place => Identity (Items'Length)));

   --  The index that lands at K when entries A and B are exchanged.
   function Sw (K, A, B : Positive) return Positive is
     (if K = A then B elsif K = B then A else K);

   --  A with the entries at positions X and Y exchanged.
   function Swapped (A : Arrangement; X, Y : Positive) return Arrangement
   with
     Pre  => X <= A.N and then Y <= A.N,
     Post => Swapped'Result.N = A.N and then Swapped'Result.Items = A.Items
             and then (for all K in 1 .. A.N => Swapped'Result.Order (K) = A.Order (Sw (K, X, Y)));

   function Swapped (A : Arrangement; X, Y : Positive) return Arrangement is
     ((N     => A.N,
       Items => A.Items,
       Order => [for K in 1 .. A.N => A.Order (Sw (K, X, Y))],
       Place => [for V in 1 .. A.N => Sw (A.Place (V), X, Y)]));

   --  Reverse positions From .. N.
   procedure Reverse_Tail (A : in out Arrangement; From : Positive)
   with
     Global => null,
     Pre    => From <= A.N,
     Post   => A.Items = A.Items'Old
               and then (for all K in 1 .. From - 1 => A.Order (K) = A.Order'Old (K))
               and then (for all K in From .. A.N => A.Order (K) = A.Order'Old (A.N - (K - From)));

   procedure Reverse_Tail (A : in out Arrangement; From : Positive) is
      N  : constant Length := A.N;
      O0 : constant Index_Array (1 .. N) := A.Order with Ghost;
      Lo : Positive := From;
      Hi : Positive := N;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Lo in From .. N and then Hi in From .. N and then Lo - From = N - Hi);
         pragma Loop_Invariant (A.Items = A.Items'Loop_Entry);
         pragma Loop_Invariant (for all K in 1 .. From - 1 => A.Order (K) = O0 (K));
         pragma Loop_Invariant (for all K in From .. Lo - 1 => A.Order (K) = O0 (N - (K - From)));
         pragma Loop_Invariant (for all K in Hi + 1 .. N => A.Order (K) = O0 (N - (K - From)));
         pragma Loop_Invariant (for all K in Lo .. Hi => A.Order (K) = O0 (K));
         pragma Loop_Variant (Decreases => Hi - Lo);
         A := Swapped (A, Lo, Hi);
         Lo := Lo + 1;
         Hi := Hi - 1;
      end loop;
   end Reverse_Tail;

   procedure Next_Permutation (A : in out Arrangement; Found : out Boolean) is
      N : constant Length := A.N;
      I : Positive;
      J : Positive;
   begin
      if N <= 1 then
         Found := False;
         return;
      end if;

      --  The longest non-increasing tail (I + 1 .. N).
      I := N - 1;
      while A.Items (A.Order (I)) >= A.Items (A.Order (I + 1)) loop
         pragma Loop_Invariant (I <= N - 1);
         pragma Loop_Invariant (for all K in I .. N - 1 => A.Items (A.Order (K)) >= A.Items (A.Order (K + 1)));
         pragma Loop_Variant (Decreases => I);
         if I = 1 then
            --  The last arrangement: reversing it gives the sorted one.
            Reverse_Tail (A, 1);
            Found := False;
            return;
         end if;
         I := I - 1;
      end loop;

      --  Value (I) < Value (I + 1): the rightmost J with a larger value.
      J := N;
      while A.Items (A.Order (J)) <= A.Items (A.Order (I)) loop
         pragma Loop_Invariant (J in I + 2 .. N);
         pragma Loop_Variant (Decreases => J);
         J := J - 1;
      end loop;

      declare
         V0 : constant Value_Array := Values (A) with Ghost;
      begin
         A := Swapped (A, I, J);
         Reverse_Tail (A, I + 1);
         pragma Assert (Values (A) (I) > V0 (I));
         pragma Assert (for all K in 1 .. I - 1 => Values (A) (K) = V0 (K));
      end;
      Found := True;
   end Next_Permutation;

   function Count_Distinct (Items : Small_List) return Factorial_Value is
      F : Positive := 1;     --  K!
      D : Positive := 1;     --  the product of m! over the values so far
      C : Natural;
   begin
      for K in 1 .. Items'Length loop
         pragma Loop_Invariant (F = Fact (K - 1) and then D = Copies (Items, K - 1));
         C := 0;
         for J in 1 .. K loop
            pragma Loop_Invariant (C = Count_Equal (Items, Items (Items'First + (K - 1)), J - 1));
            if Items (Items'First + (J - 1)) = Items (Items'First + (K - 1)) then
               C := C + 1;
            end if;
         end loop;
         pragma Assert (C = Seen (Items, K));
         F := F * K;
         D := D * C;
         pragma Assert (F = Fact (K) and then D = Copies (Items, K));
      end loop;
      pragma Assert (F = Fact (Items'Length) and then D = Copies (Items, Items'Length));
      pragma Assert (D <= F);
      return F / D;
   end Count_Distinct;
end Permutations_II;
