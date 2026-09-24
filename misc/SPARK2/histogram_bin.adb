pragma Ada_2022;

package body Histogram_Bin with SPARK_Mode => On is
   function Bin_Of (Item : Value) return Bin_Index is
   begin
      return Bin_Index (Item / 4 + 1);
   end Bin_Of;
end Histogram_Bin;
