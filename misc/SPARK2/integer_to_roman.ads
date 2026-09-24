pragma SPARK_Mode (On);

package Integer_To_Roman is
   subtype Input is Positive range 1 .. 10;
   subtype Roman_Code is String (1 .. 5);

   function To_Roman (Value : Input) return Roman_Code
     with Global => null;
end Integer_To_Roman;
