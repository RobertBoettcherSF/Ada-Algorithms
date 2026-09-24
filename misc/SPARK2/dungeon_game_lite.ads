pragma Ada_2022;
package Dungeon_Game_Lite with SPARK_Mode => On is
   subtype Dimension is Positive range 1 .. 16;
   subtype Health is Positive range 1 .. 16;
   function Required_Health (Rows, Columns : Dimension) return Health with Global => null;
end Dungeon_Game_Lite;
