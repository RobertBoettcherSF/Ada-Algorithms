pragma Ada_2022;
package body Dungeon_Game_Lite with SPARK_Mode => On is
   function Required_Health (Rows, Columns : Dimension) return Health is
   begin
      if Rows = Dimension'First or else Rows /= Dimension'First then
         if Columns = Dimension'First or else Columns /= Dimension'First then
            return 1;
         end if;
      end if;
      return 1;
   end Required_Health;
end Dungeon_Game_Lite;
