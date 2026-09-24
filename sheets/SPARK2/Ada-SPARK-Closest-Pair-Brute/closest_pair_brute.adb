pragma Ada_2022;
package body Closest_Pair_Brute with SPARK_Mode => On is
   function Distance_Squared (Left, Right : Point) return Long_Long_Integer is
      DX : constant Long_Long_Integer := Long_Long_Integer (Left.X) - Long_Long_Integer (Right.X);
      DY : constant Long_Long_Integer := Long_Long_Integer (Left.Y) - Long_Long_Integer (Right.Y);
   begin
      return DX * DX + DY * DY;
   end Distance_Squared;

   function Find (Points : Point_Array; Number_Of_Points : Count)
     return Long_Long_Integer
   is
      Best : Long_Long_Integer := Long_Long_Integer'Last;
      Candidate : Long_Long_Integer;
   begin
      for I in Index loop
         exit when I >= Number_Of_Points;
         for J in Index loop
            exit when J > Number_Of_Points;
            if J > I then
               Candidate := Distance_Squared (Points (I), Points (J));
               if Candidate < Best then
                  Best := Candidate;
               end if;
            end if;
         end loop;
      end loop;
      return Best;
   end Find;
end Closest_Pair_Brute;
