--------------------------------------------------------------------------------
-- Package: Quantum_Artificial_Life                                           --
-- Description: Ada 2023 implementation of Quantum Artificial Life algorithms --
--              inspired by quantum models of biological evolution and        --
--              self-replication (Alvarez-Rodriguez et al.).                  --
--------------------------------------------------------------------------------

package Quantum_Artificial_Life is

   -- Strong typing for algorithm-specific domain concepts
   type Genotype_State is (Alpha, Beta);
   type Phenotype_State is (Low, High);
   type Lifetime_T is range 0 .. 100;
   type Mutation_Parameter_T is digits 5 range 0.0 .. 6.28318; -- Radians for rotation theta

   type Individual_T is record
      Genotype  : Genotype_State;
      Phenotype : Phenotype_State;
      Lifetime  : Lifetime_T;
      Active    : Boolean;
   end record;

   Grid_Size : constant := 5;
   type Coordinate_T is range 1 .. Grid_Size;

   type Cell_Capacity_T is range 0 .. 10;
   type Cell_Index_T is range 1 .. 10;

   type Individual_Array is array (Cell_Index_T) of Individual_T;

   type Cell_T is record
      Count     : Cell_Capacity_T := 0;
      Occupants : Individual_Array;
   end record;

   type Environment_Grid_T is array (Coordinate_T, Coordinate_T) of Cell_T;

   -- Named Exceptions for edge cases and validation failures
   Invalid_Grid_Error : exception;
   Population_Overflow_Error : exception;

   ----------------------------------------------------------------------------
   -- Subprograms implementing variants and core dynamics from Wikipedia     --
   ----------------------------------------------------------------------------

   -- 1. Self-Replication Variant: Simulates quantum cloning of genotype into ancillary state
   procedure Self_Replication (
      Parent    : in  Individual_T;
      Offspring : out Individual_T;
      Success   : out Boolean
   ) with
      Pre  => Parent.Lifetime > 0,
      Post => (if Success then Offspring.Active and Offspring.Lifetime > 0 else not Offspring.Active);

   -- 2. Interaction Variant: Cell-based interaction exhibiting predator-prey dynamics
   procedure Intercept_And_Interact (
      Ind_1 : in out Individual_T;
      Ind_2 : in out Individual_T
   ) with
      Pre  => True; -- Inactive individuals are handled gracefully inside

   -- 3. Mutation Variant: Spontaneous M-operation or self-replication error UM-operation
   procedure Apply_Mutation (
      Ind                  : in out Individual_T;
      Theta                : in     Mutation_Parameter_T;
      Is_Replication_Error : in     Boolean
   ) with
      Pre  => True;

   -- 4. Death & Aging Variant: Decrements lifespan and deactivates expired individuals
   procedure Process_Lifespan (
      Ind : in out Individual_T
   ) with
      Pre  => True;

   -- 5. Environmental Step Variant: Processes aging and cell interactions across the grid
   procedure Step_Environment (
      Grid : in out Environment_Grid_T
   );

   -- Helper validation and aggregation functions
   function Count_Active_Population (Grid : Environment_Grid_T) return Natural;
   function Validate_Environment (Grid : Environment_Grid_T) return Boolean;

end Quantum_Artificial_Life;
