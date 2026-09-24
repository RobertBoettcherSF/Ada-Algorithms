pragma Ada_2022;
package Array_Partition_I with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 1 .. 99;
   type Int_Array is array (Index) of Value;
   procedure Sort (Input : in out Int_Array);
   function Pair_Sum (Input : Int_Array) return Natural;
end Array_Partition_I;
