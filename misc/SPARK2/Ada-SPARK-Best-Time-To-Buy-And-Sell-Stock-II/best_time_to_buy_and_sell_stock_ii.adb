pragma Ada_2022;

package body Best_Time_To_Buy_And_Sell_Stock_II with SPARK_Mode => On is
   function Max_Profit (Input : Input_Array) return Natural is
      Profit : Integer range 0 .. 800 := 0;
      Gain : Integer range -100 .. 100;
   begin
      for I in Index range 2 .. Index'Last loop
         Gain := Input (I) - Input (I - 1);
         if Gain > 0 then
            Profit := Profit + Gain;
         end if;
      end loop;
      return Profit;
   end Max_Profit;
end Best_Time_To_Buy_And_Sell_Stock_II;
