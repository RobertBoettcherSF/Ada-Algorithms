pragma SPARK_Mode (On);

package Roman_To_Integer is
   subtype Roman_Text is String (1 .. 5);
   subtype Roman_Value is Natural range 0 .. 5_000;

   function Value_Of (Text : Roman_Text) return Roman_Value
     with Global => null;
end Roman_To_Integer;
