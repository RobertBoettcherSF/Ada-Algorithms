pragma Ada_2022;

package body Find_All_Duplicates_In_An_Array with SPARK_Mode => On is
   function Duplicates (Input : Input_Array) return Output_Array is
      Result : Output_Array := (others => 0);
      Seen_Before : Boolean;
   begin
      for I in Index loop
         Seen_Before := False;
         for J in Index loop
            if J < I and then Input (J) = Input (I) then
               Seen_Before := True;
            end if;
         end loop;
         if Seen_Before then
            Result (I) := Input (I);
         end if;
      end loop;
      return Result;
   end Duplicates;
end Find_All_Duplicates_In_An_Array;
