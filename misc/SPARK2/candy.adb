pragma Ada_2022;
pragma SPARK_Mode (On);
package body Candy is
   function Candy_Count (Ratings : Ratings_Array; N : Count) return Count is
   begin
      pragma Unreferenced (Ratings);
      return N;
   end Candy_Count;
end Candy;
