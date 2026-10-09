--  Pre rejection: searching/SPARK2/Ada-SPARK-Trigram-Search (Contains).
with Pre_Rng; use Pre_Rng;
with Trigram_Search; use Trigram_Search;
procedure Pr_Trigram is
   Rej : Natural := 0;
   function Pre_Contains (Text : Char_Array) return Boolean is (Text'Length <= Max_Len);
begin
   for K in 1 .. Sample loop
      declare
         L : constant Natural := Draw (0, Max_Len);
         F : constant Positive := Draw (1, (if L = 0 then Positive'Last else Positive'Last - L + 1));
         T : constant Char_Array (F .. F + L - 1) := [others => 'a'];
      begin
         if not Pre_Contains (T) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report ("searching/SPARK2/Ada-SPARK-Trigram-Search", "Contains",
           "text length uniform 0..Max_Len, origin uniform over Positive, A/B/C any Character", Rej);
end Pr_Trigram;
