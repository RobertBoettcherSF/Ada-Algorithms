pragma SPARK_Mode (On);

--  Scaffold for the failing test: the old count table (12! / 2 with a
--  repeated pair, else 12!) and a Next_Permutation that never moves.
package body Permutations_II is
   function Start (Items : List) return Arrangement is
     ((N => Items'Last, Items => Items, Order => [for K in 1 .. Items'Last => K],
       Place => [for K in 1 .. Items'Last => K]));

   procedure Next_Permutation (A : in out Arrangement; Found : out Boolean) is
   begin
      Found := A.N < 0;
   end Next_Permutation;

   function Count_Distinct (Items : Small_List) return Factorial_Value is
      Full : constant array (0 .. 12) of Factorial_Value :=
        [1, 1, 2, 6, 24, 120, 720, 5_040, 40_320, 362_880, 3_628_800, 39_916_800, 479_001_600];
   begin
      if Items'Last >= 2 and then Items (1) = Items (2) then
         return Full (Items'Last) / 2;
      end if;
      return Full (Items'Last);
   end Count_Distinct;
end Permutations_II;
