--  Pre rejection: misc/SPARK4/Ada-SPARK-Lemke-Howson (Find_Equilibrium).
--  A bimatrix game: M, N uniform over Strategy_Count, both matrices
--  M x N with the same index ranges, origins uniform over Strategy_Count
--  where they fit; Initial_Drop uniform over Label_Type.
with Pre_Rng; use Pre_Rng;
with Lemke_Howson; use Lemke_Howson;
procedure Pr_Lemke is
   Rej, Rej1 : Natural := 0;
   function Pre_Find (A, B : Payoff_Matrix; D : Label_Type) return Boolean is
     (Same_Shape (A, B) and then D <= A'Last (1) + A'Last (2));
begin
   for K in 1 .. Sample loop
      declare
         M  : constant Strategy_Count := Draw (1, Max_Strategies);
         N  : constant Strategy_Count := Draw (1, Max_Strategies);
         R  : constant Strategy_Count := Draw (1, Max_Strategies - M + 1);
         C  : constant Strategy_Count := Draw (1, Max_Strategies - N + 1);
         D  : constant Label_Type := Draw (1, 2 * Max_Strategies);
         A  : constant Payoff_Matrix (R .. R + M - 1, C .. C + N - 1) := [others => [others => 0]];
         A1 : constant Payoff_Matrix (1 .. M, 1 .. N) := [others => [others => 0]];
      begin
         if not Pre_Find (A, A, D) then Rej := Rej + 1; end if;
         if not Pre_Find (A1, A1, D) then Rej1 := Rej1 + 1; end if;
      end;
   end loop;
   Report ("misc/SPARK4/Ada-SPARK-Lemke-Howson", "Find_Equilibrium",
           "M x N game, origins uniform over Strategy_Count, Initial_Drop uniform over Label_Type", Rej);
   Report ("misc/SPARK4/Ada-SPARK-Lemke-Howson", "Find_Equilibrium",
           "M x N game at origin 1, Initial_Drop uniform over Label_Type", Rej1);
end Pr_Lemke;
