pragma Ada_2022;
package body Point_In_Polygon with SPARK_Mode => On is
   function Contains (Shape : Polygon; Number_Of_Vertices : Count;
                      Query : Point) return Boolean
   is
      Inside : Boolean := False;
      Previous : Index;
      Xi, Yi, Xj, Yj, Qx, Qy : Long_Long_Integer;
   begin
      for I in Index loop
         exit when I > Number_Of_Vertices;
         if I = 1 then
            Previous := Number_Of_Vertices;
         else
            Previous := I - 1;
         end if;
         Xi := Long_Long_Integer (Shape (I).X);
         Yi := Long_Long_Integer (Shape (I).Y);
         Xj := Long_Long_Integer (Shape (Previous).X);
         Yj := Long_Long_Integer (Shape (Previous).Y);
         Qx := Long_Long_Integer (Query.X);
         Qy := Long_Long_Integer (Query.Y);
         if ((Yi > Qy) /= (Yj > Qy))
           and then ((Yj > Yi and then (Qx - Xi) * (Yj - Yi) < (Xj - Xi) * (Qy - Yi))
                     or else (Yj < Yi and then (Qx - Xi) * (Yj - Yi) > (Xj - Xi) * (Qy - Yi)))
         then
            Inside := not Inside;
         end if;
      end loop;
      return Inside;
   end Contains;
end Point_In_Polygon;
