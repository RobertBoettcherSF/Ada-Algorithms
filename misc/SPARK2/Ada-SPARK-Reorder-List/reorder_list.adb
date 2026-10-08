pragma SPARK_Mode (On);

package body Reorder_List is
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

   procedure Reorder (L : in out List) is
      Original : constant Value_Array := L.Data;
      Output : Value_Array := (others => 0);
      Out_Pos : Position := 1;
   begin
      for I in Position loop
         exit when I > L.Size;
         Output (Out_Pos) := Original (I);
         if Out_Pos < Position'Last then
            Out_Pos := Out_Pos + 1;
         end if;
         if I <= L.Size / 2 then
            Output (Out_Pos) := Original (L.Size - I + 1);
            if Out_Pos < Position'Last then
               Out_Pos := Out_Pos + 1;
            end if;
         end if;
      end loop;
      L.Data := Output;
   end Reorder;
end Reorder_List;
