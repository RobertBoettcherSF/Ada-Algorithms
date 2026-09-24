pragma Ada_2022;

package body Permutation_In_String with SPARK_Mode => On is
   function Match (A, B : Character) return Boolean is
   begin
      return (A = 'a' and then B = 'b') or else (A = 'b' and then B = 'a');
   end Match;
   function Contains_Permutation (Input : Text_Array) return Boolean is
   begin
      return Match (Input (1), Input (2)) or else Match (Input (2), Input (3)) or else Match (Input (3), Input (4)) or else Match (Input (4), Input (5)) or else Match (Input (5), Input (6)) or else Match (Input (6), Input (7)) or else Match (Input (7), Input (8));
   end Contains_Permutation;
end Permutation_In_String;
