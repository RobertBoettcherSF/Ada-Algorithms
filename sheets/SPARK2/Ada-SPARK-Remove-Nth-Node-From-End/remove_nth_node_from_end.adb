pragma SPARK_Mode (On);
package body Remove_Nth_Node_From_End is
   function Empty return List is begin return (Data => (others => 0), Size => 0); end Empty;
   procedure Append (L : in out List; V : Value) is
   begin if L.Size < Count'Last then L.Size := L.Size + 1; L.Data (L.Size) := V; end if; end Append;
   function Length (L : List) return Count is begin return L.Size; end Length;
   function Element (L : List; P : Position) return Value is begin return L.Data (P); end Element;
   procedure Remove_Nth (L : in out List; N : Position) is Target : Count;
   begin
      if N <= L.Size then Target := L.Size - N + 1;
         for I in Position loop if I >= Target and then I < L.Size then L.Data (I) := L.Data (I + 1); end if; end loop;
         L.Size := L.Size - 1;
      end if;
   end Remove_Nth;
end Remove_Nth_Node_From_End;
