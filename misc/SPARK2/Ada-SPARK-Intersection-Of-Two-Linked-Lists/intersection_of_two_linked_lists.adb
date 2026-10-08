pragma SPARK_Mode (On);

package body Intersection_Of_Two_Linked_Lists is
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

   function Common_Suffix_Length (Left, Right : List) return Count is
      Matched : Count := 0;
   begin
      while Matched < Left.Size and then Matched < Right.Size loop
         pragma Loop_Variant (Increases => Matched);
         exit when Left.Data (Left.Size - Matched) /=
                   Right.Data (Right.Size - Matched);
         Matched := Matched + 1;
      end loop;
      return Matched;
   end Common_Suffix_Length;
end Intersection_Of_Two_Linked_Lists;
