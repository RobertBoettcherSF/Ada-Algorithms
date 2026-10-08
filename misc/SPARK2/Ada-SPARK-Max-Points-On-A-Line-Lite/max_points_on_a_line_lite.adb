pragma Ada_2022;
package body Max_Points_On_A_Line_Lite with SPARK_Mode => On is
   function Max_Collinear (A, B, C : Point) return Point_Count is
      Result : Point_Count;
   begin
      if (B.X - A.X) * (C.Y - A.Y)
        = (B.Y - A.Y) * (C.X - A.X)
      then
         Result := 3;
      else
         Result := 2;
      end if;
      pragma Assert (Result in 2 .. 3);
      return Result;
   end Max_Collinear;
end Max_Points_On_A_Line_Lite;
