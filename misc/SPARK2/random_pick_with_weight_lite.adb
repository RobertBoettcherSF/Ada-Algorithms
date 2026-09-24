pragma Ada_2022;

package body Random_Pick_With_Weight_Lite with SPARK_Mode => On is
   function Pick (Weights : Weight_Array; Draw : Ticket) return Index is
      Remaining : Integer := Integer (Draw);
   begin
      for I in Index loop
         if Remaining <= Integer (Weights (I)) then
            return I;
         end if;
         Remaining := Remaining - Integer (Weights (I));
      end loop;
      return Index'Last;
   end Pick;
end Random_Pick_With_Weight_Lite;
