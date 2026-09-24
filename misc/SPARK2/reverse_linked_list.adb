pragma SPARK_Mode (On);
package body Reverse_Linked_List is
   function Empty return List is
   begin return (Data => (others => 0), Size => 0); end Empty;
   procedure Append (L : in out List; V : Value) is
   begin if L.Size < Count'Last then L.Size := L.Size + 1; L.Data (L.Size) := V; end if; end Append;
   function Length (L : List) return Count is begin return L.Size; end Length;
   function Element (L : List; P : Position) return Value is begin return L.Data (P); end Element;
   procedure Reverse_List (L : in out List) is Temp : Value;
   begin
      for I in Position loop
         if I <= L.Size / 2 then
            declare J : constant Position := Position (L.Size - I + 1); begin
               Temp := L.Data (I); L.Data (I) := L.Data (J); L.Data (J) := Temp;
            end;
         end if;
      end loop;
   end Reverse_List;
end Reverse_Linked_List;
