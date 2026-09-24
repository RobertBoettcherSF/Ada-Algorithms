pragma SPARK_Mode (On);

package body Merge_In_Between_Linked_Lists is
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

   procedure Merge_In_Between (L : in out List; First, Last : Position; V : Value) is
   begin
      for I in Position loop
         if I >= First and then I <= Last then
            L.Data (I) := V;
         end if;
      end loop;
   end Merge_In_Between;
end Merge_In_Between_Linked_Lists;
