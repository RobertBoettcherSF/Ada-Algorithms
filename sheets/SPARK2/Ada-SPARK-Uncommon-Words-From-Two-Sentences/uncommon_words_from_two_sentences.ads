pragma Ada_2022;

package Uncommon_Words_From_Two_Sentences with SPARK_Mode => On is
   Length : constant := 3;
   subtype Index is Positive range 1 .. Length;
   subtype Word_Code is Integer range 0 .. 15;
   type Word_Array is array (Index) of Word_Code;

   function Has_Left_Only (Left, Right : Word_Array) return Boolean
     with Global => null;
end Uncommon_Words_From_Two_Sentences;
