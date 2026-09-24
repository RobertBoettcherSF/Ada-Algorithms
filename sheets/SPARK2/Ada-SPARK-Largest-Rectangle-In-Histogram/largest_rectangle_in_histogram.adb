pragma Ada_2022;

package body Largest_Rectangle_In_Histogram with SPARK_Mode => On is
   function Max_Area (H : Heights; Length : Length_Type) return Area is
      Best : Area := 0;
      Current_Min : Height;
      Candidate : Area;
   begin
      for Left in 1 .. Length loop
         Current_Min := Height'Last;
         for Right in Left .. Length loop
            if H (Left) < Current_Min then
               Current_Min := H (Left);
            end if;
            if H (Right) < Current_Min then
               Current_Min := H (Right);
            end if;
            Candidate := Area (Current_Min) * Area (Right - Left + 1);
            if Candidate > Best then
               Best := Candidate;
            end if;
         end loop;
      end loop;
      return Best;
   end Max_Area;
end Largest_Rectangle_In_Histogram;
