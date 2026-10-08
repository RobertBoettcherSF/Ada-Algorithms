pragma SPARK_Mode (On);

package body Delete_The_Middle_Node is
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

   procedure Delete_Middle (L : in out List) is
      Middle : Position;
   begin
      case L.Size is
         when 0 => Middle := 1;
         when 1 => Middle := 1;
         when 2 => Middle := 1;
         when 3 => Middle := 2;
         when 4 => Middle := 2;
         when 5 => Middle := 3;
         when 6 => Middle := 3;
         when 7 => Middle := 4;
         when 8 => Middle := 4;
         when 9 => Middle := 5;
         when 10 => Middle := 5;
         when 11 => Middle := 6;
         when 12 => Middle := 6;
         when 13 => Middle := 7;
         when 14 => Middle := 7;
         when 15 => Middle := 8;
         when 16 => Middle := 8;
      end case;
      for I in Position loop
         if I >= Middle and then I < L.Size and then I < Position'Last then
            L.Data (I) := L.Data (I + 1);
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
   end Delete_Middle;
end Delete_The_Middle_Node;
