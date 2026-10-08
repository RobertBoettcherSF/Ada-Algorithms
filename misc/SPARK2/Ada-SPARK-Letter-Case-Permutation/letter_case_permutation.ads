pragma Ada_2022;

package Letter_Case_Permutation with SPARK_Mode => On is
   subtype Letter_Count is Natural range 0 .. 12;
   function Count_Permutations (Letters : Letter_Count) return Natural with Global => null;
end Letter_Case_Permutation;
