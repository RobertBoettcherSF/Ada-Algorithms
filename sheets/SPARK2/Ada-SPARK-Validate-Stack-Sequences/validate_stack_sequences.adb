pragma Ada_2022;
package body Validate_Stack_Sequences with SPARK_Mode => On is
   function Valid (Pushed : Sequence; Popped : Sequence; N : Length) return Boolean is
      Work : Sequence := [others => 0];
      Top : Length := 0; Next_Push : Length := 0; Good : Boolean := True;
   begin
      for I in 1 .. N loop
         while Good and then Next_Push < N and then (Top = 0 or else Work (Top) /= Popped (I)) loop
            pragma Loop_Variant (Increases => Next_Push);
            if Top < Capacity then
               Next_Push := Next_Push + 1; Top := Top + 1; Work (Top) := Pushed (Next_Push);
            else Good := False; end if;
         end loop;
         if Good then
            if Top > 0 and then Work (Top) = Popped (I) then Top := Top - 1;
            else Good := False; end if;
         end if;
      end loop;
      return Good;
   end Valid;
end Validate_Stack_Sequences;
