pragma SPARK_Mode (On);

package body Palindrome_Linked_List is
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

   function Is_Palindrome (L : List) return Boolean is
      Result : Boolean := True;
      Half : constant Count := L.Size / 2;
   begin
      for I in Position loop
         exit when I > Half;
         if L.Data (I) /= L.Data (L.Size - I + 1) then
            Result := False;
         end if;
      end loop;
      return Result;
   end Is_Palindrome;
end Palindrome_Linked_List;
