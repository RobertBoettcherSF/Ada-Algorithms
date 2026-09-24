with Best_Time_To_Buy_And_Sell_Stock;
procedure Tests is
   Prices : constant Best_Time_To_Buy_And_Sell_Stock.Input_Array := [7, 1, 5, 3, 6, 4, 2, 8];
begin
   pragma Assert (Best_Time_To_Buy_And_Sell_Stock.Max_Profit (Prices) = 7);
end Tests;
