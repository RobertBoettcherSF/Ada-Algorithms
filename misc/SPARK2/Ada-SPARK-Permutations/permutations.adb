pragma SPARK_Mode (On);

--  Scaffold for the failing test: the old N! table, and a Next_Permutation
--  that always wraps around.
package body Permutations is
   function Identity (N : Length) return Perm is
     ((N => N, Order => [for K in 1 .. N => K], Place => [for K in 1 .. N => K]));

   procedure Next_Permutation (P : in out Perm; Found : out Boolean) is
   begin
      P := Identity (P.N);
      Found := False;
   end Next_Permutation;

   function Count (N : Count_Range) return Factorial_Value is
   begin
      case N is
         when 0 => return 1;
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 6;
         when 4 => return 24;
         when 5 => return 120;
         when 6 => return 720;
         when 7 => return 5_040;
         when 8 => return 40_320;
         when 9 => return 362_880;
         when 10 => return 3_628_800;
         when 11 => return 39_916_800;
         when 12 => return 479_001_600;
      end case;
   end Count;
end Permutations;
