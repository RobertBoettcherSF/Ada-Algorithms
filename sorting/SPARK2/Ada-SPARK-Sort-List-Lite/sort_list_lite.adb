pragma SPARK_Mode (On);
package body Sort_List_Lite is
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
      Smallest : Position;
   begin
      for I in 1 .. Capacity - 1 loop
         if I < L.Length then
            Smallest := I;
            for J in Position loop
               if J > I and then J <= L.Length and then L.Data (J) < L.Data (Smallest) then
                  Smallest := J;
               end if;
            end loop;
            Temp := L.Data (I);
            L.Data (I) := L.Data (Smallest);
            L.Data (Smallest) := Temp;
         end if;
      end loop;
   end Solve;
end Sort_List_Lite;
