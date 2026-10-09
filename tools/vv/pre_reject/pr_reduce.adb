--  Pre rejection: misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half.
with Pre_Rng; use Pre_Rng;
with Reduce_Array_Size_To_The_Half; use Reduce_Array_Size_To_The_Half;
procedure Pr_Reduce is
   Rej : Natural := 0;
   function Pre_G (Length, Largest_Group : Array_Length) return Boolean is (Largest_Group <= Length);
begin
   for K in 1 .. Sample loop
      if not Pre_G (Draw (0, Array_Length'Last), Draw (0, Array_Length'Last)) then Rej := Rej + 1; end if;
   end loop;
   Report ("misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half", "Groups_To_Remove",
           "Length and Largest_Group uniform over Array_Length", Rej);
end Pr_Reduce;
