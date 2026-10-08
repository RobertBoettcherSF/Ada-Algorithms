pragma Ada_2022;

package Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Price is Integer range 0 .. 100;
   type Input_Array is array (Index) of Price;

   function Max_Profit (Input : Input_Array) return Natural
     with Global => null;
end Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown;
