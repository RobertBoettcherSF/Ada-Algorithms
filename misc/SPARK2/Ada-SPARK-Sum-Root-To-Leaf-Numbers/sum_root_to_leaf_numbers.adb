pragma Ada_2022;

package body Sum_Root_To_Leaf_Numbers with SPARK_Mode => On is
   function Path (Root, First, Second, Leaf : Digit) return Integer is
   begin
      return Root * 1_000 + First * 100 + Second * 10 + Leaf;
   end Path;

   function Sum_Root_To_Leaf (Input : Tree) return Integer is
   begin
      return Path (Input (1), Input (2), Input (4), Input (8))
        + Path (Input (1), Input (2), Input (4), Input (9))
        + Path (Input (1), Input (2), Input (5), Input (10))
        + Path (Input (1), Input (2), Input (5), Input (11))
        + Path (Input (1), Input (3), Input (6), Input (12))
        + Path (Input (1), Input (3), Input (6), Input (13))
        + Path (Input (1), Input (3), Input (7), Input (14))
        + Path (Input (1), Input (3), Input (7), Input (15));
   end Sum_Root_To_Leaf;
end Sum_Root_To_Leaf_Numbers;
