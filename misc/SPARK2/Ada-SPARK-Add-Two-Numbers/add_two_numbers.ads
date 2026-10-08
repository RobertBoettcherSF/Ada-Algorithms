pragma SPARK_Mode (On);

package Add_Two_Numbers is
   subtype Number is Integer range -1_000 .. 1_000;
   subtype Sum is Integer range -2_000 .. 2_000;

   function Add (Left, Right : Number) return Sum
     with Global => null;
end Add_Two_Numbers;
