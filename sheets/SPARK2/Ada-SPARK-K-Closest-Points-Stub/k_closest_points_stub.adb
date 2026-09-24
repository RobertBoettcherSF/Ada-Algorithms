pragma Ada_2022;

package body K_Closest_Points_Stub with SPARK_Mode => On is
   function Distance (P : Point) return Distance_Value is
   begin
      return P.X * P.X + P.Y * P.Y;
   end Distance;

   function K_Closest (Points : Point_Array) return Result_Array is
      Work : Point_Array := Points;
      Result : Result_Array;
      Minimum : Point_Index;
      Temporary : Point;
   begin
      for I in Point_Index loop
         Minimum := I;
         for J in Point_Index range I .. Point_Index'Last loop
            if Distance (Work (J)) < Distance (Work (Minimum)) then
               Minimum := J;
            end if;
         end loop;
         Temporary := Work (I);
         Work (I) := Work (Minimum);
         Work (Minimum) := Temporary;
      end loop;
      for I in Result_Index loop
         Result (I) := Work (I);
      end loop;
      return Result;
   end K_Closest;
end K_Closest_Points_Stub;
