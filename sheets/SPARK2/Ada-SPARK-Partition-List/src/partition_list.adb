pragma SPARK_Mode (On);
package body Partition_List is
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
   procedure Solve (L : in out List; Pivot : Integer) is
      Original : constant Values := L.Data;
      Write : Count := 0;
   begin
      for I in Position loop
         if I <= L.Length and then Original (I) < Pivot then
            if Write < Capacity then
               Write := Write + 1;
               L.Data (Write) := Original (I);
            end if;
         end if;
      end loop;
      for I in Position loop
         if I <= L.Length and then Original (I) >= Pivot then
            if Write < Capacity then
               Write := Write + 1;
               L.Data (Write) := Original (I);
            end if;
         end if;
      end loop;
   end Solve;
end Partition_List;
