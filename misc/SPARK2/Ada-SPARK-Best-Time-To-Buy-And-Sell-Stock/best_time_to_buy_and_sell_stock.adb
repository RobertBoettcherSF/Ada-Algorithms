pragma Ada_2022;

package body Best_Time_To_Buy_And_Sell_Stock with SPARK_Mode => On is
   function Max_Profit (Input : Input_Array) return Natural is
      Minimum : Price := Input (Index'First);
      Best : Integer range 0 .. 100 := 0;
      Today : Integer range -100 .. 100;
   begin
      for I in Index range 2 .. Index'Last loop
         Today := Input (I) - Minimum;
         if Today > Best then
            Best := Today;
         end if;
         if Input (I) < Minimum then
            Minimum := Input (I);
         end if;
      end loop;
      return Best;
   end Max_Profit;
end Best_Time_To_Buy_And_Sell_Stock;
