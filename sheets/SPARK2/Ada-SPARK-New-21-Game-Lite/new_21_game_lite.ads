pragma Ada_2022;
package New_21_Game_Lite with SPARK_Mode => On is
   subtype Score is Natural range 0 .. 16;
   function Target_Is_Reachable (Target : Score) return Boolean with Global => null;
end New_21_Game_Lite;
