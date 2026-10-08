pragma SPARK_Mode (On);

package body Softmin is
   function Value (Left, Right : Score) return Score is
      Small : constant Score := (if Left < Right then Left else Right);
      Large : constant Score := (if Left < Right then Right else Left);
   begin
      return Small + (Large - Small) / 4;
   end Value;
end Softmin;
