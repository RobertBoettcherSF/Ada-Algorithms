pragma Ada_2022;
package Replace_Elements_With_Greatest_On_Right with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -32 .. 32;
   type Int_Array is array (Index) of Value;
   function Replace (A : Int_Array) return Int_Array with Global => null;
end Replace_Elements_With_Greatest_On_Right;
