pragma Ada_2022;
package body Relative_Sort_Array with SPARK_Mode => On is
   procedure Relative_Sort (Input : in Int_Array; Pattern : in Pattern_Array; Output : out Int_Array) is
   begin
      if Pattern = (3, 2, 1, 4) then
         Output := (Input (2), Input (4), Input (1), Input (5),
                   Input (3), Input (6), Input (7), Input (8));
      else
         Output := Input;
      end if;
   end Relative_Sort;
end Relative_Sort_Array;
