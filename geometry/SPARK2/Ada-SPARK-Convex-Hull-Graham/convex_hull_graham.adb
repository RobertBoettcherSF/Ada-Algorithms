pragma Ada_2022;
package body Convex_Hull_Graham with SPARK_Mode => On is
   function Turn (A, B, C : Point) return Long_Long_Integer is
   begin
      return Long_Long_Integer (B.X - A.X) * Long_Long_Integer (C.Y - A.Y)
        - Long_Long_Integer (B.Y - A.Y) * Long_Long_Integer (C.X - A.X);
   end Turn;

   procedure Scan (Points : in Point_Array; Number_Of_Points : in Count;
                   Hull : out Point_Array; Hull_Count : out Hull_Length)
   is
      Top : Hull_Length := 0;
   begin
      Hull := [others => (X => 0, Y => 0)];
      for I in Index loop
         exit when I > Number_Of_Points;
         for Removal in Index loop
            exit when Top < 2
              or else Turn (Hull (Top - 1), Hull (Top), Points (I)) > 0;
            Top := Top - 1;
         end loop;
         Top := Top + 1;
         Hull (Top) := Points (I);
         pragma Loop_Invariant (Top <= I);
      end loop;
      Hull_Count := Top;
   end Scan;
end Convex_Hull_Graham;
