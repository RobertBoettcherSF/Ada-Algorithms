pragma SPARK_Mode (On);

package Excel_Sheet_Column_Number is
   subtype Column_Title is String (1 .. 2);
   subtype Column_Number is Natural range 0 .. 702;

   function Number (Title : Column_Title) return Column_Number
     with Global => null;
end Excel_Sheet_Column_Number;
