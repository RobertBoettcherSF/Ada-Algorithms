pragma Ada_2022;
package Is_Subsequence with SPARK_Mode => On is
   function Check (A, B : String) return Boolean
     with Pre => A'Length <= 1 and B'Length <= 16, Global => null;
end Is_Subsequence;
