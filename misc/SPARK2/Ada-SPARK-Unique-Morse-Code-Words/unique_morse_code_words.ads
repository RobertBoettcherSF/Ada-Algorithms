pragma Ada_2022;

package Unique_Morse_Code_Words with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Code is Integer range 0 .. 1023;
   type Code_Array is array (Index) of Code;

   function All_Unique (Codes : Code_Array) return Boolean
     with Global => null;
end Unique_Morse_Code_Words;
