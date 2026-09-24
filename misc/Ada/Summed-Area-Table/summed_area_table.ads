-- summed_area_table.ads
-- Specification for the Summed Area Table (Integral Image) algorithm.

package Summed_Area_Table is

   -- Use Long_Long_Integer to prevent overflow during sum accumulation
   type Value_Type is new Long_Long_Integer;
   
   -- 2D and 3D Unconstrained Arrays
   type Grid_2D is array (Integer range <>, Integer range <>) of Value_Type;
   type Grid_3D is array (Integer range <>, Integer range <>, Integer range <>) of Value_Type;

   -- Exceptions for error handling
   Invalid_Dimensions : exception;
   Invalid_Coordinates : exception;

   ----------------------------------------------------------------------------
   -- 2D Summed Area Table Variants
   ----------------------------------------------------------------------------
   
   -- Computes standard 2D Summed Area Table in a single pass using the recurrence:
   -- I(x,y) = i(x,y) + I(x-1,y) + I(x,y-1) - I(x-1,y-1)
   procedure Compute_2D_SAT (Input : in Grid_2D; Output : out Grid_2D);

   -- Fast/Cascaded Computation (computes row prefix sums, then column prefix sums)
   -- Excellent for cache locality and easily parallelizable.
   procedure Compute_2D_SAT_Fast (Input : in Grid_2D; Output : out Grid_2D);

   -- Higher Order variant: Computes the SAT of the squared input values.
   -- Used for fast variance and standard deviation queries (e.g., in Haar-features).
   procedure Compute_2D_Squared_SAT (Input : in Grid_2D; Output : out Grid_2D);

   -- Queries the sum of the rectangular area in O(1) time.
   -- Top_Left is (X1, Y1), Bottom_Right is (X2, Y2)
   function Query_2D_Region (SAT : Grid_2D; X1, Y1, X2, Y2 : Integer) return Value_Type;

   ----------------------------------------------------------------------------
   -- 3D Summed Area Table Variants (Multi-dimensional)
   ----------------------------------------------------------------------------
   
   -- Computes the 3D Summed Area Table (Integral Volume)
   procedure Compute_3D_SAT (Input : in Grid_3D; Output : out Grid_3D);

   -- Queries the sum of a cuboid volume in O(1) time using Inclusion-Exclusion
   function Query_3D_Region (SAT : Grid_3D; X1, Y1, Z1, X2, Y2, Z2 : Integer) return Value_Type;

end Summed_Area_Table;
