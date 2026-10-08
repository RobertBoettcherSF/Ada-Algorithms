pragma SPARK_Mode (On);
package body Rotate_List is
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
   procedure Solve (L : in out List; K : Count) is
      Original : constant Values := L.Data;
   begin
      if L.Length in Position then
         declare
            Shift : constant Count := K mod L.Length;
         begin
            for I in Position loop
            if I <= L.Length then
               if I > Shift then
                  L.Data (I) := Original (I - Shift);
               elsif Shift > 0 then
                  L.Data (I) := Original (L.Length - Shift + I);
               end if;
            end if;
            end loop;
         end;
      end if;
   end Solve;
end Rotate_List;
