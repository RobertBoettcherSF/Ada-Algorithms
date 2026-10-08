pragma Ada_2022;

package body Majority_Element_II with SPARK_Mode => On is
   function Find (Input : Input_Array) return Result_Array is
      Result : Result_Array := [others => 0];
      Used : Boolean := False;
      Count : Natural;
   begin
      for Candidate in Index loop
         Count := 0;
         for Position in Index loop
            if Input (Position) = Input (Candidate) then
               Count := Count + 1;
            end if;
         end loop;
         if Count > Length / 3 and then (not Used or else Result (1) /= Input (Candidate)) then
            if not Used then
               Result (1) := Input (Candidate);
               Used := True;
            else
               Result (2) := Input (Candidate);
            end if;
         end if;
      end loop;
      return Result;
   end Find;
end Majority_Element_II;
