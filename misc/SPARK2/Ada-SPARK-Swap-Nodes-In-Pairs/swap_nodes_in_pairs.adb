pragma SPARK_Mode (On);
package body Swap_Nodes_In_Pairs is
   function Empty return List is
   begin
      return (Data => (others => 0), Length => 0);
   end Empty;
   procedure Append (L : in out List; Value : Integer) is
   begin
      L.Length := L.Length + 1;
      L.Data (L.Length) := Value;
   end Append;
   function Get (L : List; P : Position) return Integer is
   begin
      return L.Data (P);
   end Get;
   procedure Solve (L : in out List) is
      Temp : Integer;
   begin
      for I in 1 .. Capacity - 1 loop
         if I mod 2 = 1 and then I + 1 <= L.Length then
            Temp := L.Data (I);
            L.Data (I) := L.Data (I + 1);
            L.Data (I + 1) := Temp;
         end if;
      end loop;
   end Solve;
end Swap_Nodes_In_Pairs;
