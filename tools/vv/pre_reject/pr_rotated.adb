--  Pre rejection: sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array
--  (Find_Minimum, Minimum). Row 1: every element uniform over Value.
--  Row 2: the tests' kind of input (distinct sorted values, rotated by a
--  uniform amount), which must be accepted.
with Pre_Rng; use Pre_Rng;
with Find_Minimum_In_Rotated_Sorted_Array; use Find_Minimum_In_Rotated_Sorted_Array;
procedure Pr_Rotated is
   Rej : Natural := 0;
   function Pre_F (Data : Data_Array) return Boolean is (Is_Rotated_Sorted (Data));
   F_Name : constant String := "sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array";
begin
   for K in 1 .. Sample loop
      declare
         D : Data_Array;
      begin
         for I in Index loop D (I) := Draw (Value'First, Value'Last); end loop;
         if not Pre_F (D) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report (F_Name, "Find_Minimum / Minimum", "every element uniform over Value", Rej);
   Rej := 0;
   for K in 1 .. Sample loop
      declare
         S : Data_Array;
         D : Data_Array;
         V : Integer := Value'First - 1;
         R : constant Natural := Draw (0, Length - 1);
      begin
         --  Distinct increasing values: gaps 1..3 keep 32 values within 0..100.
         for I in Index loop
            V := V + Draw (1, 3); S (I) := V;
         end loop;
         for I in Index loop D (I) := S ((I - 1 + R) mod Length + 1); end loop;
         if not Pre_F (D) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report (F_Name, "Find_Minimum / Minimum", "distinct increasing values (gaps 1..3), rotated uniformly", Rej);
end Pr_Rotated;
