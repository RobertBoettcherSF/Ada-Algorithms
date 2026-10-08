-- warnsdorff.ads
-- Package specification for the Knight's Tour using Warnsdorff's heuristic.

package Warnsdorff is
   
   -- Define the tie-breaking variants for the algorithm.
   -- Basic: Basic Warnsdorff (first minimum degree found).
   -- Pohl: Squirrel and Cull's rule (tie-break using minimum sum of neighbors' degrees).
   type Strategy_Type is (Basic, Pohl);
   
   -- Unconstrained 2D array for the chessboard.
   -- Values represent the sequence number of the knight's visit (1 to N^2).
   -- 0 indicates an unvisited square.
   type Board_Grid is array (Positive range <>, Positive range <>) of Natural;
   
   -- Exception raised when starting coordinates are outside the board boundaries.
   Invalid_Start_Position : exception;

   -- Core algorithm: Attempts to generate a Knight's Tour.
   -- @param Size: The dimension of the N x N board.
   -- @param Start_X, Start_Y: The initial placement of the Knight.
   -- @param Strategy: The tie-breaking variant to use.
   -- @param Result: The populated board showing the order of visits.
   -- @param Success: True if a complete tour was found, False otherwise (dead end).
   procedure Solve_Tour
     (Size     : in  Positive;
      Start_X  : in  Positive;
      Start_Y  : in  Positive;
      Strategy : in  Strategy_Type;
      Result   : out Board_Grid;
      Success  : out Boolean);

   -- Helper Function: Validates if a completely filled board is a mathematically 
   -- correct Knight's Tour (all moves are exactly L-shaped and sequence is contiguous).
   function Is_Valid_Tour (Grid : Board_Grid; Size : Positive) return Boolean;

end Warnsdorff;
