pragma Ada_2022;

package body Fisher_Yates_Shuffle with SPARK_Mode => On is
   procedure Shuffle (Data : in out Item_Array; Choices : Swap_Array) is
      Temporary : Item;
   begin
      for I in reverse Index loop
         Temporary := Data (I);
         Data (I) := Data (Choices (I));
         Data (Choices (I)) := Temporary;
      end loop;
   end Shuffle;
end Fisher_Yates_Shuffle;
