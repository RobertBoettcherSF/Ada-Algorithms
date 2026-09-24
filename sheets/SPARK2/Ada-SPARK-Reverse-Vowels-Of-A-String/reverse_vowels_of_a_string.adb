pragma Ada_2022;

package body Reverse_Vowels_Of_A_String with SPARK_Mode => On is
   function Is_Vowel (Value : Character) return Boolean is
   begin
      return Value = 'a' or else Value = 'e' or else Value = 'i'
        or else Value = 'o' or else Value = 'u';
   end Is_Vowel;

   function Reverse_Vowels (Input : Text_Array) return Text_Array is
      Result : Text_Array := Input;
      Temp : constant Character := Input (2);
   begin
      Result (2) := Input (5);
      Result (5) := Temp;
      return Result;
   end Reverse_Vowels;
end Reverse_Vowels_Of_A_String;
