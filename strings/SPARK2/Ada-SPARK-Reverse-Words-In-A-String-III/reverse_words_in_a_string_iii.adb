pragma Ada_2022;

package body Reverse_Words_In_A_String_III with SPARK_Mode => On is
   subtype Cursor is Natural range 0 .. 33;

   procedure Reverse_Words (Input : Text; Length : Length_Type;
                            Output : out Text; Output_Length : out Length_Type) is
      Pos : Cursor := 1;
      Start : Cursor;
      Stop : Cursor;
      Temp : Character;
   begin
      Output := Input;
      while Pos <= Length loop
         pragma Loop_Invariant (Pos in 1 .. 33);
         if Output (Index (Pos)) = ' ' then
            Pos := Pos + 1;
         else
            Start := Pos;
            while Pos <= Length and then Output (Index (Pos)) /= ' ' loop
               pragma Loop_Invariant (Pos in 1 .. 33);
               Pos := Pos + 1;
            end loop;
            Stop := Pos - 1;
            while Start < Stop loop
               pragma Loop_Invariant (Start in 1 .. 32 and then Stop in 1 .. 32);
               Temp := Output (Index (Start));
               Output (Index (Start)) := Output (Index (Stop));
               Output (Index (Stop)) := Temp;
               Start := Start + 1;
               Stop := Stop - 1;
            end loop;
         end if;
      end loop;
      Output_Length := Length;
   end Reverse_Words;
end Reverse_Words_In_A_String_III;
