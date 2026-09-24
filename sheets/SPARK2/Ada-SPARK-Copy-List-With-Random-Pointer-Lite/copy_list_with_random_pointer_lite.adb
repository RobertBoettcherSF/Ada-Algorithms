pragma SPARK_Mode (On);

package body Copy_List_With_Random_Pointer_Lite is
   function Empty return List is
   begin
      return (Data => (others => 0), Random => (others => 0), Size => 0);
   end Empty;

   procedure Append (L : in out List; V : Value) is
   begin
      if L.Size < Count'Last then
         L.Size := L.Size + 1;
         L.Data (L.Size) := V;
         L.Random (L.Size) := 0;
      end if;
   end Append;

   procedure Set_Random (L : in out List; P : Position; Target : Link_Index) is
   begin
      L.Random (P) := Target;
   end Set_Random;

   function Length (L : List) return Count is
   begin
      return L.Size;
   end Length;

   function Element (L : List; P : Position) return Value is
   begin
      return L.Data (P);
   end Element;

   function Random_Of (L : List; P : Position) return Link_Index is
   begin
      return L.Random (P);
   end Random_Of;

   function Copy_List (L : List) return List is
   begin
      return L;
   end Copy_List;
end Copy_List_With_Random_Pointer_Lite;
