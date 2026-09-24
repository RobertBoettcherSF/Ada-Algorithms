pragma Ada_2022;
package body Count_Binary_Substrings with SPARK_Mode => On is
   procedure Count_Substrings (Input : Text; Length : Length_Type; Result : out Count_Type) is
      Previous : Character := ' ';
      Previous_Run : Natural range 0 .. 32 := 0;
      Current_Run : Natural range 0 .. 32 := 0;
      Answer : Count_Type := 0;
      Same : Boolean;
   begin
      for I in Index loop
         exit when I > Length;
         Same := Input (I) = Previous;
         if Same then
            Current_Run := Current_Run + 1;
         else
            if Current_Run > 0 then
               if Previous_Run < Current_Run then
                  if Answer <= Count_Type'Last - Count_Type (Previous_Run) then
                     Answer := Answer + Count_Type (Previous_Run);
                  else
                     Answer := Count_Type'Last;
                  end if;
               else
                  if Answer <= Count_Type'Last - Count_Type (Current_Run) then
                     Answer := Answer + Count_Type (Current_Run);
                  else
                     Answer := Count_Type'Last;
                  end if;
               end if;
            end if;
            Previous_Run := Current_Run;
            Current_Run := 1;
            Previous := Input (I);
         end if;
         pragma Loop_Invariant (Current_Run <= I);
         pragma Loop_Invariant (Previous_Run <= I);
      end loop;
      if Previous_Run < Current_Run then
         if Answer <= Count_Type'Last - Count_Type (Previous_Run) then
            Answer := Answer + Count_Type (Previous_Run);
         else
            Answer := Count_Type'Last;
         end if;
      else
         if Answer <= Count_Type'Last - Count_Type (Current_Run) then
            Answer := Answer + Count_Type (Current_Run);
         else
            Answer := Count_Type'Last;
         end if;
      end if;
      Result := Answer;
   end Count_Substrings;
end Count_Binary_Substrings;
