pragma SPARK_Mode (On);

package Missing_Ranges_Stub is
   subtype Index is Natural range 0 .. 15;
   type Presence is array (Index) of Boolean;
   subtype Count is Natural range 0 .. 16;

   function Count_Missing (Present : Presence) return Count
     with Global => null;
end Missing_Ranges_Stub;
