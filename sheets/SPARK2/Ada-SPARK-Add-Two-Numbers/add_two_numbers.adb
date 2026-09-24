pragma SPARK_Mode (On);

package body Add_Two_Numbers is
   function Add (Left, Right : Number) return Sum is
   begin
      return Sum (Left + Right);
   end Add;
end Add_Two_Numbers;
