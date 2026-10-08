pragma Ada_2022;
package body New_21_Game_Lite with SPARK_Mode => On is
   function Target_Is_Reachable (Target : Score) return Boolean is
   begin
      return Target <= 10;
   end Target_Is_Reachable;
end New_21_Game_Lite;
