pragma Ada_2022;
package Third_Maximum_Number with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Count is Natural range 0 .. Length;
   subtype Value is Integer range -32 .. 32;
   type Int_Array is array (Index) of Value;
   function Third_Maximum (A : Int_Array) return Value with Global => null;
end Third_Maximum_Number;
