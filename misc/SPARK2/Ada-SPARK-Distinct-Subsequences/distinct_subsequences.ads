pragma Ada_2022;

package Distinct_Subsequences with SPARK_Mode => On is
   Max_Length : constant := 16;
   subtype Length is Natural range 0 .. Max_Length;
   subtype Index is Positive range 1 .. Max_Length;
   subtype Count is Natural range 0 .. 65_536;
   type Text is array (Index) of Character;

   function Count_Of
     (Source, Target : Text; NS, NT : Length) return Count
     with Global => null;
end Distinct_Subsequences;
