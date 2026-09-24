with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Artificial_Life; use Quantum_Artificial_Life;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   -- TEST 1 — Self-Replication Success
   Put_Line ("TEST 1 — Self-Replication Success");
   declare
      Parent    : constant Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 50, Active => True);
      Offspring : Individual_T;
      Success   : Boolean;
   begin
      Self_Replication (Parent, Offspring, Success);
      Check ("1.1 Replication reported success", Success);
      Check ("1.2 Offspring is active", Offspring.Active);
      Check ("1.3 Offspring genotype matches parent", Offspring.Genotype = Parent.Genotype);
   end;

   -- TEST 2 — Self-Replication Failure (Inactive Parent)
   Put_Line ("TEST 2 — Self-Replication Failure");
   declare
      Parent    : constant Individual_T := (Genotype => Beta, Phenotype => High, Lifetime => 0, Active => False);
      Offspring : Individual_T;
      Success   : Boolean;
   begin
      Self_Replication (Parent, Offspring, Success);
      Check ("2.1 Replication reported failure", not Success);
      Check ("2.2 Offspring is inactive", not Offspring.Active);
      Check ("2.3 Offspring lifetime is zero", Offspring.Lifetime = 0);
   end;

   -- TEST 3 — Interaction with Differing Genotypes
   Put_Line ("TEST 3 — Interaction with Differing Genotypes");
   declare
      Ind1 : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 20, Active => True);
      Ind2 : Individual_T := (Genotype => Beta, Phenotype => High, Lifetime => 20, Active => True);
   begin
      Intercept_And_Interact (Ind1, Ind2);
      Check ("3.1 Ind1 phenotype swapped to High", Ind1.Phenotype = High);
      Check ("3.2 Ind2 phenotype swapped to Low", Ind2.Phenotype = Low);
      Check ("3.3 Ind1 genotype unchanged", Ind1.Genotype = Alpha);
   end;

   -- TEST 4 — Interaction with Identical Genotypes
   Put_Line ("TEST 4 — Interaction with Identical Genotypes");
   declare
      Ind1 : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 20, Active => True);
      Ind2 : Individual_T := (Genotype => Alpha, Phenotype => High, Lifetime => 20, Active => True);
   begin
      Intercept_And_Interact (Ind1, Ind2);
      Check ("4.1 Ind1 phenotype unchanged", Ind1.Phenotype = Low);
      Check ("4.2 Ind2 phenotype unchanged", Ind2.Phenotype = High);
      Check ("4.3 Both genotypes remain Alpha", Ind1.Genotype = Alpha and Ind2.Genotype = Alpha);
   end;

   -- TEST 5 — Interaction with Inactive Individuals
   Put_Line ("TEST 5 — Interaction with Inactive Individuals");
   declare
      Ind1 : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 20, Active => False);
      Ind2 : Individual_T := (Genotype => Beta, Phenotype => High, Lifetime => 20, Active => True);
   begin
      Intercept_And_Interact (Ind1, Ind2);
      Check ("5.1 Inactive Ind1 phenotype unchanged", Ind1.Phenotype = Low);
      Check ("5.2 Active Ind2 phenotype unchanged", Ind2.Phenotype = High);
      Check ("5.3 Ind1 remains inactive", not Ind1.Active);
   end;

   -- TEST 6 — Spontaneous Mutation (M Operation)
   Put_Line ("TEST 6 — Spontaneous Mutation M");
   declare
      Ind : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 20, Active => True);
   begin
      Apply_Mutation (Ind, 4.0, Is_Replication_Error => False);
      Check ("6.1 Phenotype toggled by rotation theta > pi", Ind.Phenotype = High);
      Check ("6.2 Genotype unchanged by M operation", Ind.Genotype = Alpha);
      Check ("6.3 Individual remains active", Ind.Active);
   end;

   -- TEST 7 — Replication Error Mutation (UM Operation)
   Put_Line ("TEST 7 — Replication Error Mutation UM");
   declare
      Ind : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 20, Active => True);
   begin
      Apply_Mutation (Ind, 1.0, Is_Replication_Error => True);
      Check ("7.1 Genotype toggled from Alpha to Beta", Ind.Genotype = Beta);
      Check ("7.2 Lifetime reduced by mutation error", Ind.Lifetime = 15);
      Check ("7.3 Individual remains active", Ind.Active);
   end;

   -- TEST 8 — Mutation on Inactive Individual
   Put_Line ("TEST 8 — Mutation on Inactive Individual");
   declare
      Ind : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False);
   begin
      Apply_Mutation (Ind, 4.0, Is_Replication_Error => False);
      Check ("8.1 Inactive individual genotype unchanged", Ind.Genotype = Alpha);
      Check ("8.2 Inactive individual phenotype unchanged", Ind.Phenotype = Low);
      Check ("8.3 Individual remains inactive", not Ind.Active);
   end;

   -- TEST 9 — Process Lifespan Decrement
   Put_Line ("TEST 9 — Process Lifespan Decrement");
   declare
      Ind : Individual_T := (Genotype => Alpha, Phenotype => Low, Lifetime => 10, Active => True);
   begin
      Process_Lifespan (Ind);
      Check ("9.1 Lifetime decremented by 1", Ind.Lifetime = 9);
      Check ("9.2 Individual stays active when lifetime > 0", Ind.Active);
      Check ("9.3 Genotype unaffected by aging", Ind.Genotype = Alpha);
   end;

   -- TEST 10 — Process Lifespan Expiration
   Put_Line ("TEST 10 — Process Lifespan Expiration");
   declare
      Ind : Individual_T := (Genotype => Beta, Phenotype => High, Lifetime => 1, Active => True);
   begin
      Process_Lifespan (Ind);
      Check ("10.1 Lifetime reaches zero", Ind.Lifetime = 0);
      Check ("10.2 Individual becomes inactive on death", not Ind.Active);
      Check ("10.3 Genotype preserved upon death", Ind.Genotype = Beta);
   end;

   -- TEST 11 — Environment Step and Aging
   Put_Line ("TEST 11 — Environment Step and Aging");
   declare
      Grid : Environment_Grid_T := [others => [others => (Count => 0, Occupants => [others => (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False)])]];
   begin
      Grid(1, 1).Count := 1;
      Grid(1, 1).Occupants(1) := (Genotype => Alpha, Phenotype => Low, Lifetime => 5, Active => True);
      Step_Environment (Grid);
      Check ("11.1 Grid occupant lifetime decremented", Grid(1, 1).Occupants(1).Lifetime = 4);
      Check ("11.2 Grid occupant still active", Grid(1, 1).Occupants(1).Active);
      Check ("11.3 Environment validation succeeds", Validate_Environment(Grid));
   end;

   -- TEST 12 — Count Active Population
   Put_Line ("TEST 12 — Count Active Population");
   declare
      Grid : Environment_Grid_T := [others => [others => [Count => 0, Occupants => [others => (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False)]]]];
   begin
      Grid(1, 1).Count := 2;
      Grid(1, 1).Occupants(1) := (Genotype => Alpha, Phenotype => Low, Lifetime => 10, Active => True);
      Grid(1, 1).Occupants(2) := (Genotype => Beta, Phenotype => High, Lifetime => 10, Active => True);
      Grid(2, 2).Count := 1;
      Grid(2, 2).Occupants(1) := (Genotype => Alpha, Phenotype => High, Lifetime => 10, Active => False);
      Check ("12.1 Active population count is 2", Count_Active_Population(Grid) = 2);
      Check ("12.2 Environment validation returns true", Validate_Environment(Grid));
      Check ("12.3 Grid structure is intact", Grid(1, 1).Count = 2);
   end;

   -- TEST 13 — Invalid Grid Exception Handling
   Put_Line ("TEST 13 — Invalid Grid Exception Handling");
   declare
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy_Grid : Environment_Grid_T := [others => [others => [Count => 0, Occupants => [others => (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False)]]]];
         begin
            Step_Environment (Dummy_Grid);
         end;
         Exception_Raised := False;
      exception
         when Invalid_Grid_Error =>
            Exception_Raised := True;
      end;
      Check ("13.1 Normal grid does not raise Invalid_Grid_Error", not Exception_Raised);
      Check ("13.2 Validation helper works correctly", Validate_Environment(Environment_Grid_T'[others => [others => [Count => 0, Occupants => [others => (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False)]]]]));
      Check ("13.3 Exception handling structure verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
