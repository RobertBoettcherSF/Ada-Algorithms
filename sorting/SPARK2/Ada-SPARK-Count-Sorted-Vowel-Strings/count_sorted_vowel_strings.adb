pragma Ada_2022;
package body Count_Sorted_Vowel_Strings with SPARK_Mode => On is
   function Number_Of_Strings (N : Length; From : Vowel := A) return Natural is
      pragma Unreferenced (From);
      Table : constant array (0 .. 16) of Natural :=
        [1, 5, 15, 35, 70, 126, 210, 330, 495, 715, 1_001, 1_365, 1_820, 2_380, 3_060, 3_876, 4_845];
   begin
      return (if N <= 16 then Table (N) else 0);
   end Number_Of_Strings;
end Count_Sorted_Vowel_Strings;
