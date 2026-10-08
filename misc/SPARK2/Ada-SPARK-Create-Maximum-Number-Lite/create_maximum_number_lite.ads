pragma Ada_2022;

package Create_Maximum_Number_Lite with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Digit is Natural range 0 .. 9;
   type Digit_Array is array (Index) of Digit;

   function Maximum_Digit (A, B : Digit_Array; Length : Length_Type) return Digit
     with Global => null;
   function Maximum_Prefix (A, B : Digit_Array; Length : Length_Type) return Digit_Array
     with Global => null;
end Create_Maximum_Number_Lite;
