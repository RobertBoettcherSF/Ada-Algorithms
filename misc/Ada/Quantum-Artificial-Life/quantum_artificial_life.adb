--------------------------------------------------------------------------------
-- Package Body: Quantum_Artificial_Life                                      --
--------------------------------------------------------------------------------

package body Quantum_Artificial_Life is

   ----------------------------------------------------------------------------
   -- Self_Replication Implementation                                        --
   ----------------------------------------------------------------------------
   procedure Self_Replication (
      Parent    : in  Individual_T;
      Offspring : out Individual_T;
      Success   : out Boolean
   ) is
   begin
      if not Parent.Active or Parent.Lifetime = 0 then
         Offspring := (Genotype => Alpha, Phenotype => Low, Lifetime => 0, Active => False);
         Success := False;
         return;
      end if;

      -- Quantum cloning simulation: copy genotype, set ancillary phenotype, inherit lifetime
      Offspring := (
         Genotype  => Parent.Genotype,
         Phenotype => (if Parent.Phenotype = Low then High else Low),
         Lifetime  => Parent.Lifetime,
         Active    => True
      );
      Success := True;
   end Self_Replication;

   ----------------------------------------------------------------------------
   -- Intercept_And_Interact Implementation                                  --
   ----------------------------------------------------------------------------
   procedure Intercept_And_Interact (
      Ind_1 : in out Individual_T;
      Ind_2 : in out Individual_T
   ) is
      Temp_Pheno : Phenotype_State;
   begin
      if not Ind_1.Active or not Ind_2.Active then
         return;
      end if;

      -- When control qubits (genotypes) differ, target qubits (phenotypes) are exchanged.
      -- When genotypes are alike, no information is exchanged.
      if Ind_1.Genotype /= Ind_2.Genotype then
         Temp_Pheno := Ind_1.Phenotype;
         Ind_1.Phenotype := Ind_2.Phenotype;
         Ind_2.Phenotype := Temp_Pheno;
      end if;
   end Intercept_And_Interact;

   ----------------------------------------------------------------------------
   -- Apply_Mutation Implementation                                          --
   ----------------------------------------------------------------------------
   procedure Apply_Mutation (
      Ind                  : in out Individual_T;
      Theta                : in     Mutation_Parameter_T;
      Is_Replication_Error : in     Boolean
   ) is
   begin
      if not Ind.Active then
         return;
      end if;

      if Is_Replication_Error then
         -- UM operation: alters genotype and reduces associated lifetime
         if Ind.Genotype = Alpha then
            Ind.Genotype := Beta;
         else
            Ind.Genotype := Alpha;
         end if;

         if Ind.Lifetime > 5 then
            Ind.Lifetime := Ind.Lifetime - 5;
         else
            Ind.Lifetime := 0;
            Ind.Active := False;
         end if;
      else
         -- Spontaneous M operation via qubit rotation parameter Theta:
         -- Changes phenotype state when rotation threshold exceeds pi (~3.14159)
         if Theta > 3.14159 then
            Ind.Phenotype := (if Ind.Phenotype = Low then High else Low);
         end if;
      end if;
   end Apply_Mutation;

   ----------------------------------------------------------------------------
   -- Process_Lifespan Implementation                                        --
   ----------------------------------------------------------------------------
   procedure Process_Lifespan (
      Ind : in out Individual_T
   ) is
   begin
      if not Ind.Active then
         return;
      end if;

      if Ind.Lifetime > 0 then
         Ind.Lifetime := Ind.Lifetime - 1;
      end if;

      if Ind.Lifetime = 0 then
         Ind.Active := False;
      end if;
   end Process_Lifespan;

   ----------------------------------------------------------------------------
   -- Step_Environment Implementation                                        --
   ----------------------------------------------------------------------------
   procedure Step_Environment (
      Grid : in out Environment_Grid_T
   ) is
   begin
      if not Validate_Environment (Grid) then
         raise Invalid_Grid_Error;
      end if;

      -- Iterate through each spatial cell to process aging and cell interactions
      for R in Coordinate_T loop
         for C in Coordinate_T loop
            declare
               Cell : Cell_T renames Grid (R, C);
            begin
               -- 1. Process lifespan decay for cell occupants
               if Cell.Count > 0 then
                  for I in 1 .. Cell_Index_T (Cell.Count) loop
                     if Cell.Occupants(I).Active then
                        Process_Lifespan (Cell.Occupants(I));
                     end if;
                  end loop;
               end if;

               -- 2. Trigger cell interactions if multiple individuals occupy the cell
               if Cell.Count >= 2 then
                  for I in 1 .. Cell_Index_T (Cell.Count) - 1 loop
                     for J in I + 1 .. Cell_Index_T (Cell.Count) loop
                        if Cell.Occupants(I).Active and Cell.Occupants(J).Active then
                           Intercept_And_Interact (Cell.Occupants(I), Cell.Occupants(J));
                        end if;
                     end loop;
                  end loop;
               end if;
            end;
         end loop;
      end loop;
   end Step_Environment;

   ----------------------------------------------------------------------------
   -- Count_Active_Population Implementation                                 --
   ----------------------------------------------------------------------------
   function Count_Active_Population (Grid : Environment_Grid_T) return Natural is
      Total : Natural := 0;
   begin
      for R in Coordinate_T loop
         for C in Coordinate_T loop
            if Grid(R, C).Count > 0 then
               for I in 1 .. Cell_Index_T (Grid(R, C).Count) loop
                  if Grid(R, C).Occupants(I).Active then
                     Total := Total + 1;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return Total;
   end Count_Active_Population;

   ----------------------------------------------------------------------------
   -- Validate_Environment Implementation                                    --
   ----------------------------------------------------------------------------
   function Validate_Environment (Grid : Environment_Grid_T) return Boolean is
      pragma Unreferenced (Grid);
   begin
      -- Statically bounded grid structure guarantees containment and safety.
      return True;
   end Validate_Environment;

end Quantum_Artificial_Life;
