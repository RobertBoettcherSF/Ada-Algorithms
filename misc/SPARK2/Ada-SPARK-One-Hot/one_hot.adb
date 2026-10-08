pragma SPARK_Mode (On);

package body One_Hot is
   function Encode (Value : Category) return Vector is
      Result : Vector := (others => False);
   begin
      Result (Value) := True;
      return Result;
   end Encode;
end One_Hot;
