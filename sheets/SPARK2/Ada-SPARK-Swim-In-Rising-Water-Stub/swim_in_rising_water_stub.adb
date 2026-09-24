pragma SPARK_Mode (On);

package body Swim_In_Rising_Water_Stub is
   function Maximum (Left, Right : Water_Level) return Water_Level is
   begin
      if Left > Right then
         return Left;
      else
         return Right;
      end if;
   end Maximum;

   function Minimum (Left, Right : Water_Level) return Water_Level is
   begin
      if Left < Right then
         return Left;
      else
         return Right;
      end if;
   end Minimum;

   function Minimum_Time (Heights : Grid) return Water_Level is
      Across : constant Water_Level := Maximum (Heights (1, 1), Heights (1, 2));
      Down   : constant Water_Level := Maximum (Heights (1, 1), Heights (2, 1));
   begin
      return Maximum (Heights (2, 2), Minimum (Across, Down));
   end Minimum_Time;
end Swim_In_Rising_Water_Stub;
