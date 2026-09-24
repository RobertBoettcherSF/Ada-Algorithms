pragma Ada_2022;
package Sort_Array_By_Parity_II with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 9;
   type Int_Array is array (Index) of Value;
   procedure Sort_By_Parity (Input : in Int_Array; Output : out Int_Array);
end Sort_Array_By_Parity_II;
