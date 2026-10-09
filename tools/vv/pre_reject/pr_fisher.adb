--  Pre rejection: misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle. Shuffle has
--  no Pre; its Choices parameter is the predicate subtype Swap_Array
--  (Choices (I) <= I). Measured: how many raw Index arrays (each element
--  uniform over Index) the predicate rejects.
with Pre_Rng; use Pre_Rng;
with Fisher_Yates_Shuffle; use Fisher_Yates_Shuffle;
procedure Pr_Fisher is
   Rej : Natural := 0;
   type Raw is array (Index) of Index;
   function Pred (C : Raw) return Boolean is (for all I in Index => C (I) <= I);
begin
   for K in 1 .. Sample loop
      declare
         C : Raw;
      begin
         for I in Index loop C (I) := Draw (1, Length); end loop;
         if not Pred (C) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report ("misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle", "Shuffle (Swap_Array predicate; no Pre)",
           "each Choices element uniform over Index", Rej);
end Pr_Fisher;
