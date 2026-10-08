pragma Ada_2022;

package body Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown with SPARK_Mode => On is
   function Max_Profit (Input : Input_Array) return Natural is
      Hold : Integer range -100 .. 800 := -Input (Index'First);
      Sold : Integer range -100 .. 800 := -100;
      Rest : Integer range 0 .. 800 := 0;
      New_Hold : Integer range -100 .. 800;
      New_Sold : Integer range -100 .. 800;
      New_Rest : Integer range 0 .. 800;
   begin
      for I in Index range 2 .. Index'Last loop
         if Hold > Rest - Input (I) then
            New_Hold := Hold;
         else
            New_Hold := Rest - Input (I);
         end if;
         New_Sold := Hold + Input (I);
         if Rest > Sold then
            New_Rest := Rest;
         else
            New_Rest := Sold;
         end if;
         Hold := New_Hold;
         Sold := New_Sold;
         Rest := New_Rest;
      end loop;
      if Sold > Rest then
         return Sold;
      else
         return Rest;
      end if;
   end Max_Profit;
end Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown;
