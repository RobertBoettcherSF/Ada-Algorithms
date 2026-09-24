pragma Ada_2022;
package Count_Sorted_Vowel_Strings with SPARK_Mode => On is
   subtype Length is Natural range 0 .. 16;
   subtype Count is Natural range 0 .. 10_000;
   function Number_Of_Strings (N : Length) return Count with Global => null;
end Count_Sorted_Vowel_Strings;
