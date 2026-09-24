pragma Ada_2022;

package Histogram_Bin with SPARK_Mode => On is
   Bin_Count : constant := 4;
   subtype Bin_Index is Positive range 1 .. Bin_Count;
   subtype Value is Integer range 0 .. 15;

   function Bin_Of (Item : Value) return Bin_Index with Global => null;
end Histogram_Bin;
