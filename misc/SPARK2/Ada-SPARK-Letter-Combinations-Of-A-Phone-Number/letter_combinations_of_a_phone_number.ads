pragma Ada_2022;

package Letter_Combinations_Of_A_Phone_Number with SPARK_Mode => On is
   subtype Digit_Count is Integer range 0 .. 12;
   subtype Combination_Count is Integer range 1 .. 531_441;

   function Count_Combinations (Number_Of_Digits : Digit_Count) return Combination_Count
     with Global => null;
end Letter_Combinations_Of_A_Phone_Number;
