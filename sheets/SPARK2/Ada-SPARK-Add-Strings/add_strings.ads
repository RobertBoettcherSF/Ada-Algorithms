pragma SPARK_Mode (On);

package Add_Strings is
   subtype Number is Natural range 0 .. 100_000_000;
   subtype Sum is Natural range 0 .. 200_000_000;

   function Add (Left, Right : Number) return Sum
     with Global => null;
end Add_Strings;
