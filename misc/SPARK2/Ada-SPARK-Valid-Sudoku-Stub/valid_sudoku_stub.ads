--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Valid-Sudoku implementation; see PROOFS.csv stub
pragma Ada_2022;

package Valid_Sudoku_Stub with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Cell is Natural range 0 .. Side;
   type Board is array (Index, Index) of Cell;

   function Is_Valid (Input : Board) return Boolean
     with Global => null;
end Valid_Sudoku_Stub;
