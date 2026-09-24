pragma SPARK_Mode (On);

package body Min_Cost_Connect_Cities_Stub is
   type Parent_Array is array (City) of City;

   function Minimum_Cost (Edges : Edge_Array) return Natural is
      Work   : Edge_Array := Edges;
      Parent : Parent_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4);
      Total  : Natural range 0 .. 600 := 0;
      Used   : Natural range 0 .. City_Count := 0;
   begin
      for I in 1 .. Edge_Count - 1 loop
         for J in I + 1 .. Edge_Count loop
            if Work (J).Cost < Work (I).Cost then
               declare
                  Temporary : constant Edge := Work (I);
               begin
                  Work (I) := Work (J);
                  Work (J) := Temporary;
               end;
            end if;
         end loop;
      end loop;
      for I in Work'Range loop
         declare
            Left  : City := Work (I).From;
            Right : City := Work (I).To;
         begin
            for Step in 1 .. City_Count loop
               if Parent (Left) /= Left then
                  Left := Parent (Left);
               end if;
               if Parent (Right) /= Right then
                  Right := Parent (Right);
               end if;
            end loop;
            if Left /= Right and then Used < City_Count - 1 then
               Parent (Left) := Right;
               Used := Used + 1;
               Total := Total + Work (I).Cost;
            end if;
         end;
      end loop;
      return Total;
   end Minimum_Cost;
end Min_Cost_Connect_Cities_Stub;
