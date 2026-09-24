pragma SPARK_Mode (On);
package Number_Of_Substrings_Containing_All_Three_Characters is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Symbol is Integer range 0 .. 2;
   type Symbol_Array is array (Index) of Symbol;
   type Answer is mod 65;
   function Count (Values : Symbol_Array) return Answer;
end Number_Of_Substrings_Containing_All_Three_Characters;
