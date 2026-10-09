--  Pre rejection: misc/SPARK4/Ada-SPARK-Heaps-Algorithm (Count, Generate).
--  N uniform within the documented limit 1 .. Max_N.
with Pre_Rng; use Pre_Rng;
with Heaps_Algorithm; use Heaps_Algorithm;
procedure Pr_Heaps is
   Rej : Natural := 0;
   function Pre_N (N : Positive) return Boolean is (N <= Max_N);
begin
   for K in 1 .. Sample loop
      if not Pre_N (Draw (1, Max_N)) then Rej := Rej + 1; end if;
   end loop;
   Report ("misc/SPARK4/Ada-SPARK-Heaps-Algorithm", "Count / Generate",
           "N uniform 1..Max_N (documented limit)", Rej);
end Pr_Heaps;
