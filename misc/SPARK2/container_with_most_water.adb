pragma SPARK_Mode (On);

package body Container_With_Most_Water is
   function Max_Area (Data : Heights; Length : Length_Type) return Area is
      Best : Area := 0;
      Candidate : Area;
      Width : Natural;
      Low : Height;
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            if J > I then
               Width := J - I;
               if Data (I) < Data (J) then
                  Low := Data (I);
               else
                  Low := Data (J);
               end if;
               Candidate := Area (Width * Low);
               if Candidate > Best then
                  Best := Candidate;
               end if;
            end if;
         end loop;
      end loop;
      return Best;
   end Max_Area;
end Container_With_Most_Water;
