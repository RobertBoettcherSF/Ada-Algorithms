pragma Ada_2022;

package body Matchsticks_To_Square_Lite with SPARK_Mode => On is
   function Can_Form_Square (Sticks : Stick_List; N : Count) return Boolean is
      Total : Natural := 0;
      Longest : Natural := 0;
   begin
      for I in Index range 1 .. N loop
         Total := Total + Sticks (I);
         if Sticks (I) > Longest then
            Longest := Sticks (I);
         end if;
      end loop;
      return Total mod 4 = 0 and then Longest <= Total / 4;
   end Can_Form_Square;
end Matchsticks_To_Square_Lite;
