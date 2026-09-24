pragma Ada_2022;

package body Maximal_Rectangle with SPARK_Mode => On is
   type Heights is array (Column) of Count;

   function Max_Area (M : Matrix; Rows, Columns : Count) return Area is
      H : Heights := [others => 0];
      Best : Area := 0;
      Current_Min : Count;
      Candidate : Area;
   begin
      for R in 1 .. Rows loop
         for C in 1 .. Columns loop
            if M (R, C) = 1 then
               H (C) := H (C) + 1;
            else
               H (C) := 0;
            end if;
         end loop;
         for Left in 1 .. Columns loop
            Current_Min := Count'Last;
            for Right in Left .. Columns loop
               if H (Right) < Current_Min then
                  Current_Min := H (Right);
               end if;
               Candidate := Area (Current_Min) * Area (Right - Left + 1);
               if Candidate > Best then
                  Best := Candidate;
               end if;
            end loop;
         end loop;
      end loop;
      return Best;
   end Max_Area;
end Maximal_Rectangle;
