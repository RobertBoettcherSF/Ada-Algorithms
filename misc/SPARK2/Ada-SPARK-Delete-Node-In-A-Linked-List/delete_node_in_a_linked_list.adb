pragma SPARK_Mode (On);

package body Delete_Node_In_A_Linked_List is
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

   procedure Delete_At (L : in out List; P : Position) is
   begin
      if P <= L.Size then
         for I in Position loop
            exit when I >= L.Size;
            if I >= P then
               L.Data (I) := L.Data (I + 1);
            end if;
         end loop;
         L.Size := L.Size - 1;
      end if;
   end Delete_At;
end Delete_Node_In_A_Linked_List;
