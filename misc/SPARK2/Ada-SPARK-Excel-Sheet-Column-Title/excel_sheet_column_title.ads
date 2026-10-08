pragma SPARK_Mode (On);

package Excel_Sheet_Column_Title is
   subtype Column_Number is Positive range 1 .. 702;
   subtype Column_Title is String (1 .. 2);

   function Title (Value : Column_Number) return Column_Title
     with Global => null;
end Excel_Sheet_Column_Title;
