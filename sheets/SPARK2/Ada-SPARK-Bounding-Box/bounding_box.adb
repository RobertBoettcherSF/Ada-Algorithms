pragma Ada_2022;
package body Bounding_Box with SPARK_Mode => On is
   function Enclose (Points : Point_Array; Number_Of_Points : Count) return Box is
      Result : Box :=
        (Min_X => Points (1).X, Min_Y => Points (1).Y,
         Max_X => Points (1).X, Max_Y => Points (1).Y);
   begin
      for I in 2 .. Number_Of_Points loop
         if Points (I).X < Result.Min_X then
            Result.Min_X := Points (I).X;
         end if;
         if Points (I).Y < Result.Min_Y then
            Result.Min_Y := Points (I).Y;
         end if;
         if Points (I).X > Result.Max_X then
            Result.Max_X := Points (I).X;
         end if;
         if Points (I).Y > Result.Max_Y then
            Result.Max_Y := Points (I).Y;
         end if;
      end loop;
      return Result;
   end Enclose;
end Bounding_Box;
