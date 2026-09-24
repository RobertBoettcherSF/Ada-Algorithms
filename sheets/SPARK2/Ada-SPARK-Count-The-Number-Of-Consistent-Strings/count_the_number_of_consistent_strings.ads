pragma Ada_2022;

package Count_The_Number_Of_Consistent_Strings with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Symbol is Integer range 0 .. 7;
   subtype Count is Natural range 0 .. Length;
   type Input_Array is array (Index) of Symbol;

   function Count_Consistent (Input : Input_Array; Allowed : Symbol) return Count
     with Global => null;
end Count_The_Number_Of_Consistent_Strings;
