pragma SPARK_Mode (On);

package body Add_Two_Numbers_II is
   procedure Add (Left, Right : Number; Result : out Sum) is
   begin
      Result := Sum (Left + Right);
   end Add;
end Add_Two_Numbers_II;
