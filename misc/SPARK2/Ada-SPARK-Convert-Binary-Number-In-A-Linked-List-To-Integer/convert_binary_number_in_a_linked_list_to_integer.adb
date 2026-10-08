pragma SPARK_Mode (On);

package body Convert_Binary_Number_In_A_Linked_List_To_Integer is
   function Empty return List is
   begin
      return (Data => (others => 0), Size => 0);
   end Empty;

   procedure Append (L : in out List; V : Bit) is
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

   function To_Integer (L : List) return Result is
      R : Result := 0;
   begin
      for I in Position loop
         pragma Loop_Invariant (R <= 2 ** Integer (I - 1) - 1);
         if I <= L.Size and then R <= 32_767 then
            if L.Data (I) = 0 then
               R := 2 * R;
            else
               R := 2 * R + 1;
            end if;
         end if;
      end loop;
      return R;
   end To_Integer;
end Convert_Binary_Number_In_A_Linked_List_To_Integer;
