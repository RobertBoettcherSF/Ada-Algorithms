pragma Ada_2022;
package body Repeated_String_Match with SPARK_Mode => On is
   subtype Cursor is Natural range 0 .. 33;
   procedure Repeat_Count (Source, Target : Text; Source_Length, Target_Length : Length_Type;
                           Result : out Repeat_Type) is
      Buffer : Text := (others => ' ');
      Built : Cursor := 0;
      Repetitions : Repeat_Type := 0;
      Found : Boolean := False;
      Match : Boolean;
   begin
      if Source_Length = 0 then
         Result := 0;
      else
         for R in Index loop
            exit when Found;
            if Built <= 32 - Source_Length then
               for I in Index loop
                  exit when I > Source_Length;
                  Buffer (Index (Built + I)) := Source (I);
               end loop;
               Built := Built + Source_Length;
               if Repetitions < Repeat_Type'Last then
                  Repetitions := Repetitions + 1;
               end if;
               if Built >= Target_Length then
                  Match := True;
                  for J in Index loop
                     exit when J > Target_Length;
                     if Buffer (J) /= Target (J) then
                        Match := False;
                     end if;
                  end loop;
                  if Match then
                     Found := True;
                  end if;
               end if;
            end if;
            pragma Loop_Invariant (Built <= 32);
            pragma Loop_Invariant (Repetitions <= 32);
         end loop;
         if Found then
            Result := Repetitions;
         else
            Result := 0;
         end if;
      end if;
   end Repeat_Count;
end Repeated_String_Match;
