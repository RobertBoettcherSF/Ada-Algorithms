pragma Ada_2022;
package Degree_Of_An_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Count is Natural range 0 .. Length;
   subtype Value is Integer range -32 .. 32;
   type Int_Array is array (Index) of Value;
   function Degree (A : Int_Array) return Count with Global => null;
end Degree_Of_An_Array;
