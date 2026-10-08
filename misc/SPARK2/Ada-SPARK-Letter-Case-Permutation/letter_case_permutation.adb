pragma Ada_2022;

package body Letter_Case_Permutation with SPARK_Mode => On is
   function Count_Permutations (Letters : Letter_Count) return Natural is
      Powers : constant array (Letter_Count) of Natural :=
        (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096);
   begin
      return Powers (Letters);
   end Count_Permutations;
end Letter_Case_Permutation;
