pragma Ada_2022;
package body Paint_House_Lite with SPARK_Mode => On is
   function Minimum (Red, Green, Blue : Cost) return Cost is
   begin
      if Red <= Green and Red <= Blue then
         return Red;
      elsif Green <= Blue then
         return Green;
      else
         return Blue;
      end if;
   end Minimum;
end Paint_House_Lite;
