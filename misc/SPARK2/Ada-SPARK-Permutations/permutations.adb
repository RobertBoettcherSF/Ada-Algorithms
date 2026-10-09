pragma SPARK_Mode (On);

package body Permutations is
   --  The index that lands at K when entries A and B are exchanged.
   function Sw (K, A, B : Positive) return Positive is
     (if K = A then B elsif K = B then A else K);

   function Identity (N : Length) return Perm is
     ((N => N, Order => [for K in 1 .. N => K], Place => [for K in 1 .. N => K]));

   --  P with the items at positions A and B exchanged.
   function Swapped (P : Perm; A, B : Positive) return Perm
   with
     Pre  => A <= P.N and then B <= P.N,
     Post => Swapped'Result.N = P.N
             and then (for all K in 1 .. P.N => Swapped'Result.Order (K) = P.Order (Sw (K, A, B)));

   function Swapped (P : Perm; A, B : Positive) return Perm is
      R : constant Perm :=
        (N     => P.N,
         Order => [for K in 1 .. P.N => P.Order (Sw (K, A, B))],
         Place => [for V in 1 .. P.N => Sw (P.Place (V), A, B)]);
   begin
      return R;
   end Swapped;

   procedure Next_Permutation (P : in out Perm; Found : out Boolean) is
      N : constant Length := P.N;
      I : Positive;
      J : Positive;
   begin
      if N <= 1 then
         P := Identity (N);
         Found := False;
         return;
      end if;

      --  The longest non-increasing tail P (I + 1 .. N).
      I := N - 1;
      while P.Order (I) >= P.Order (I + 1) loop
         pragma Loop_Invariant (I <= N - 1);
         pragma Loop_Invariant (for all K in I .. N - 1 => P.Order (K) >= P.Order (K + 1));
         pragma Loop_Variant (Decreases => I);
         if I = 1 then
            --  The last permutation: wrap around to the first.
            P := Identity (N);
            Found := False;
            return;
         end if;
         I := I - 1;
      end loop;

      --  P (I) < P (I + 1): the rightmost J with P (J) > P (I).
      J := N;
      while P.Order (J) <= P.Order (I) loop
         pragma Loop_Invariant (J in I + 2 .. N);
         pragma Loop_Variant (Decreases => J);
         J := J - 1;
      end loop;

      declare
         P0 : constant Perm := P with Ghost;
         Lo : Positive := I + 1;
         Hi : Positive := N;
      begin
         P := Swapped (P, I, J);
         pragma Assert (P.Order (I) > P0.Order (I));
         --  Reverse the tail P (I + 1 .. N), making it non-decreasing.
         while Lo < Hi loop
            pragma Loop_Invariant (Lo in I + 1 .. N and then Hi in I + 1 .. N);
            pragma Loop_Invariant (P.N = N);
            pragma Loop_Invariant (P.Order (I) > P0.Order (I));
            pragma Loop_Invariant (for all K in 1 .. I - 1 => P.Order (K) = P0.Order (K));
            pragma Loop_Variant (Decreases => Hi - Lo);
            P := Swapped (P, Lo, Hi);
            Lo := Lo + 1;
            Hi := Hi - 1;
         end loop;
      end;
      Found := True;
   end Next_Permutation;

   function Count (N : Count_Range) return Factorial_Value is
      Product : Factorial_Value := 1;
   begin
      for I in 1 .. N loop
         pragma Loop_Invariant (Product = Fact (I - 1));
         Product := Product * I;
      end loop;
      return Product;
   end Count;
end Permutations;
