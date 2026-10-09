--  Pre rejection: misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower.
with Pre_Rng; use Pre_Rng;
with Guess_Number_Higher_Or_Lower; use Guess_Number_Higher_Or_Lower;
procedure Pr_Guess is
   Rej : Natural := 0;
   function Pre_Guess (N, Secret : Number) return Boolean is (Secret <= N);
begin
   for K in 1 .. Sample loop
      if not Pre_Guess (Draw (1, Limit), Draw (1, Limit)) then Rej := Rej + 1; end if;
   end loop;
   Report ("misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower", "Guess_Number",
           "N and Secret uniform over Number (1..Limit)", Rej);
end Pr_Guess;
