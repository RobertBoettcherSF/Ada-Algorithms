with Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown;
procedure Tests is
   Prices : constant Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown.Input_Array := [1, 2, 3, 0, 2, 1, 4, 0];
begin
   pragma Assert (Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown.Max_Profit (Prices) = 5);
end Tests;
