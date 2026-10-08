pragma Ada_2022;

package Sudoku_Solver_Lite with SPARK_Mode => On is
   Board_Size : constant := 4;
   subtype Position is Positive range 1 .. Board_Size;
   subtype Digit is Positive range 1 .. Board_Size;
   type Grid is array (Position, Position) of Digit;
   function Is_Valid (G : Grid) return Boolean with Global => null;
end Sudoku_Solver_Lite;
