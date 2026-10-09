--  Pre rejection: sorting/SPARK4/Ada-SPARK-Timsort (Sort). Generator: length uniform in
--  0 .. Max_N; origin uniform over the index type where the array fits.
with Pre_Rng; use Pre_Rng;
with Timsort; use Timsort;
procedure pr_timsort is
   Rej : Natural := 0;
   --  Copy of the Pre of Sort.
   function Pre_Sort (A : Element_Array) return Boolean is (In_Bounds (A));
begin
   for K in 1 .. Sample loop
      declare
         L  : constant Natural := Draw (0, Max_N);
         Base : constant Positive := Positive'Last;
         F  : constant Positive := Draw (1, (if L = 0 then Base else Base - L + 1));
         A  : constant Element_Array (F .. F + L - 1) := [others => 0];
      begin
         if not Pre_Sort (A) then
            Rej := Rej + 1;
         end if;
      end;
   end loop;
   Report ("sorting/SPARK4/Ada-SPARK-Timsort", "Sort",
           "length uniform 0..Max_N, origin uniform over the index type", Rej);
end pr_timsort;
