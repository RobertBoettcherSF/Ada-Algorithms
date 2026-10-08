pragma Ada_2022;
package body Line_Intersection with SPARK_Mode => On is
   function Orientation (A, B, C : Point) return Long_Long_Integer is
   begin
      return Long_Long_Integer (B.X - A.X) * Long_Long_Integer (C.Y - A.Y)
        - Long_Long_Integer (B.Y - A.Y) * Long_Long_Integer (C.X - A.X);
   end Orientation;

   function On_Segment (A, B, P : Point) return Boolean is
   begin
      return P.X >= Integer'Min (A.X, B.X)
        and then P.X <= Integer'Max (A.X, B.X)
        and then P.Y >= Integer'Min (A.Y, B.Y)
        and then P.Y <= Integer'Max (A.Y, B.Y);
   end On_Segment;

   function Intersects (A, B, C, D : Point) return Boolean is
      O1 : constant Long_Long_Integer := Orientation (A, B, C);
      O2 : constant Long_Long_Integer := Orientation (A, B, D);
      O3 : constant Long_Long_Integer := Orientation (C, D, A);
      O4 : constant Long_Long_Integer := Orientation (C, D, B);
   begin
      if ((O1 > 0 and then O2 < 0) or else (O1 < 0 and then O2 > 0))
        and then ((O3 > 0 and then O4 < 0)
                  or else (O3 < 0 and then O4 > 0))
      then
         return True;
      elsif O1 = 0 and then On_Segment (A, B, C) then
         return True;
      elsif O2 = 0 and then On_Segment (A, B, D) then
         return True;
      elsif O3 = 0 and then On_Segment (C, D, A) then
         return True;
      else
         return O4 = 0 and then On_Segment (C, D, B);
      end if;
   end Intersects;
end Line_Intersection;
