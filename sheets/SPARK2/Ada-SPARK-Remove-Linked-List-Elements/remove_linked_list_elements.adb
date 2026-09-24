pragma SPARK_Mode (On);

package body Remove_Linked_List_Elements is
   function Empty return List is
   begin
      return (Data => (others => 0), Size => 0);
   end Empty;

   procedure Append (L : in out List; V : Value) is
   begin
      if L.Size < Count'Last then
         L.Size := L.Size + 1;
         L.Data (L.Size) := V;
      end if;
   end Append;

   function Length (L : List) return Count is
   begin
      return L.Size;
   end Length;

   function Element (L : List; P : Position) return Value is
   begin
      return L.Data (P);
   end Element;

   procedure Remove_First (L : in out List; V : Value) is
      Found : Boolean := False;
      Where : Count := 0;
   begin
      if L.Size > 0 then
         for I in Position loop
            if I <= L.Size and then not Found and then L.Data (I) = V then
               Found := True;
               Where := I;
            end if;
         end loop;
         if Found then
            for J in Position loop
               if J < L.Size and then J < Position'Last and then J >= Where then
                  L.Data (J) := L.Data (J + 1);
               end if;
            end loop;
            case L.Size is
               when 0 => L.Size := 0;
               when 1 => L.Size := 0;
               when 2 => L.Size := 1;
               when 3 => L.Size := 2;
               when 4 => L.Size := 3;
               when 5 => L.Size := 4;
               when 6 => L.Size := 5;
               when 7 => L.Size := 6;
               when 8 => L.Size := 7;
               when 9 => L.Size := 8;
               when 10 => L.Size := 9;
               when 11 => L.Size := 10;
               when 12 => L.Size := 11;
               when 13 => L.Size := 12;
               when 14 => L.Size := 13;
               when 15 => L.Size := 14;
               when 16 => L.Size := 15;
            end case;
         end if;
      end if;
   end Remove_First;
end Remove_Linked_List_Elements;
