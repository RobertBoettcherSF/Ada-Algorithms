pragma SPARK_Mode (On);
package body Remove_Duplicates_From_Sorted_List_II is
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
      Original : constant Values := L.Data;
      Write : Count := 0;
      Previous : Integer := 0;
      Seen : Count := 0;
   begin
      for I in Position loop
         if I <= L.Length then
            if Seen = 0 or else Original (I) /= Previous then
               if Write < Capacity then
                  Write := Write + 1;
                  L.Data (Write) := Original (I);
                  Previous := Original (I);
                  Seen := 1;
               end if;
            elsif Seen < 2 then
               if Write < Capacity then
                  Write := Write + 1;
                  L.Data (Write) := Original (I);
                  Seen := Seen + 1;
               end if;
            end if;
         end if;
      end loop;
      L.Length := Write;
   end Solve;
end Remove_Duplicates_From_Sorted_List_II;
