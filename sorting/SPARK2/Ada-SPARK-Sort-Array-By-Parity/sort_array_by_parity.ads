pragma Ada_2022;
package Sort_Array_By_Parity with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -32 .. 32;
   type Int_Array is array (Index) of Value;
   function By_Parity (A : Int_Array) return Int_Array with Global => null;
end Sort_Array_By_Parity;
