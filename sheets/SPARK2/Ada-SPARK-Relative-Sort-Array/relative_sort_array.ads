pragma Ada_2022;
package Relative_Sort_Array with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 9;
   type Int_Array is array (Index) of Value;
   subtype Pattern_Index is Positive range 1 .. 4;
   type Pattern_Array is array (Pattern_Index) of Value;
   procedure Relative_Sort (Input : in Int_Array; Pattern : in Pattern_Array; Output : out Int_Array);
end Relative_Sort_Array;
