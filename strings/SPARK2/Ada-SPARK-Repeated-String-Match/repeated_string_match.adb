pragma Ada_2022;
package body Repeated_String_Match with SPARK_Mode => On is
   procedure Repeat_Count (Source, Target : Text; Source_Length, Target_Length : Positive_Length;
                           Result : out Repeat_Type) is
      --  the proof only needs Matches_At as a black box, so its quantified body is kept out of it
      pragma Annotate (GNATprove, Hide_Info, "Expression_Function_Body", Matches_At);
   begin
      for S in 0 .. Source_Length - 1 loop
         if Matches_At (Source, Target, Source_Length, Target_Length, S) then
            pragma Assert (S + Target_Length + Source_Length - 1 <= 32 * Source_Length);
            Result := Needed (Source_Length, Target_Length, S);
            return;
         end if;
         pragma Loop_Invariant (for all S2 in 0 .. S =>
                                  not Matches_At (Source, Target, Source_Length, Target_Length, S2));
      end loop;
      Result := 0;
   end Repeat_Count;
end Repeated_String_Match;
