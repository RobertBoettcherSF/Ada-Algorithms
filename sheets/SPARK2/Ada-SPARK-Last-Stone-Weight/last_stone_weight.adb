pragma SPARK_Mode (On);

package body Last_Stone_Weight is
   function Difference (Left, Right : Weight) return Weight
     with Pre => Left >= Right
   is
   begin
      return Left - Right;
   end Difference;

   function Final_Weight (Stones : Stone_Array) return Weight is
      Work : Stone_Array := Stones;
      Best : Weight := 0;
   begin
      for Round in 1 .. Stone_Count - 1 loop
         declare
            First  : Positive := 1;
            Second : Positive := 1;
         begin
            for I in 2 .. Stone_Count loop
               if Work (I) > Work (First) then
                  Second := First;
                  First := I;
               elsif I /= First and then (Second = First or else Work (I) > Work (Second)) then
                  Second := I;
               end if;
            end loop;
            if Work (First) = 0 then
               null;
            elsif Work (Second) = 0 then
               null;
            else
               if Work (First) >= Work (Second) then
                  Work (First) := Difference (Work (First), Work (Second));
               else
                  Work (First) := Difference (Work (Second), Work (First));
               end if;
               Work (Second) := 0;
            end if;
         end;
      end loop;
      for I in Work'Range loop
         if Work (I) > Best then
            Best := Work (I);
         end if;
      end loop;
      return Best;
   end Final_Weight;
end Last_Stone_Weight;
