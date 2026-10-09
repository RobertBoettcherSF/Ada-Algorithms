--  Pre rejection: sorting/SPARK4/Ada-SPARK-Burstsort (Sort, Make).
--  Sort: length uniform 0..Max_N, origin uniform over Positive.
--  Make: string length uniform 0..Max_String_Len, origin uniform over Positive.
with Pre_Rng; use Pre_Rng;
with Burstsort; use Burstsort;
procedure Pr_Burstsort is
   Rej : Natural := 0;
   function Pre_Sort (A : String_Array) return Boolean is (In_Bounds (A));
   function Pre_Make (S : String) return Boolean is (S'Length <= Max_String_Len);
   F_Name : constant String := "sorting/SPARK4/Ada-SPARK-Burstsort";
begin
   for K in 1 .. Sample loop
      declare
         L : constant Natural := Draw (0, Max_N);
         F : constant Positive := Draw (1, (if L = 0 then Positive'Last else Positive'Last - L + 1));
         A : constant String_Array (F .. F + L - 1) := [others => Make ("")];
      begin
         if not Pre_Sort (A) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report (F_Name, "Sort", "length uniform 0..Max_N, origin uniform over Positive", Rej);
   Rej := 0;
   for K in 1 .. Sample loop
      declare
         L : constant Natural := Draw (0, Max_String_Len);
         F : constant Positive := Draw (1, (if L = 0 then Positive'Last else Positive'Last - L + 1));
         S : constant String (F .. F + L - 1) := [others => 'a'];
      begin
         if not Pre_Make (S) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report (F_Name, "Make", "length uniform 0..Max_String_Len, origin uniform over Positive", Rej);
end Pr_Burstsort;
