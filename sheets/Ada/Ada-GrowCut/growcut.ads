package GrowCut is
   -- Types for the Cellular Automata grid
   type Label_Type is (Background, Foreground, Unknown);
   
   type Cell is record
      Label    : Label_Type;
      Strength : Float; -- 0.0 to 1.0
   end record;

   -- We use a 2D array for the grid
   type Grid_Type is array (Integer range <>, Integer range <>) of Cell;

   -- Custom Exceptions
   Invalid_Grid_Size : exception;
   Invalid_Strength  : exception;

   -- Core Algorithm Variants
   -- Synchronous: All cells update based on the state at the start of the tick.
   procedure Run_Synchronous_Iteration (Grid : in out Grid_Type);

   -- Asynchronous: Cells update sequentially, using the most current neighbor state.
   procedure Run_Asynchronous_Iteration (Grid : in out Grid_Type);

   -- Helper function to calculate similarity (simplified for demonstration: 1.0 - abs(diff))
   function Calculate_Similarity (Pixel_1_Val : Float; Pixel_2_Val : Float) return Float;
   
end GrowCut;
