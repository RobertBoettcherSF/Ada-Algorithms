pragma SPARK_Mode (On);
package body Merge_Two_Sorted_Lists is
   function Empty return List is begin return (Data => (others => 0), Size => 0); end Empty;
   procedure Append (L : in out List; V : Value) is
   begin if L.Size < Count'Last then L.Size := L.Size + 1; L.Data (L.Size) := V; end if; end Append;
   function Length (L : List) return Count is begin return L.Size; end Length;
   function Element (L : List; P : Position) return Value is begin return L.Data (P); end Element;
   function Merge (A, B : List) return List is
      R : List := Empty; I : Cursor := 1; J : Cursor := 1;
   begin
      for Step in 1 .. 16 loop
         pragma Loop_Invariant (I in Cursor and then J in Cursor);
         exit when I > A.Size and then J > B.Size;
         if I <= A.Size and then J <= B.Size then
            if A.Data (I) <= B.Data (J) then Append (R, A.Data (I)); if I < Cursor'Last then I := I + 1; end if;
            else Append (R, B.Data (J)); if J < Cursor'Last then J := J + 1; end if; end if;
         elsif I <= A.Size then Append (R, A.Data (I)); if I < Cursor'Last then I := I + 1; end if;
         else Append (R, B.Data (J)); if J < Cursor'Last then J := J + 1; end if; end if;
      end loop; return R;
   end Merge;
end Merge_Two_Sorted_Lists;
