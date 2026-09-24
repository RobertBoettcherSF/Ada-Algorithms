--  Schensted row insertion / RSK insertion tableau (Ada 2022 educational package)
--  See: https://en.wikipedia.org/wiki/Schensted_algorithm

package Schensted is

   pragma Pure;

   Max_N : constant Positive := 64;
   --  Maximum sequence length and maximum tableau dimension.

   type Word is array (Positive range <>) of Positive;
   --  A sequence (typically a permutation of 1 .. n).

   type Tableau is private;
   --  A Young tableau stored by rows with explicit lengths.

   Invalid_Argument : exception;
   --  Raised for empty/oversized words, non-positive entries, or
   --  non-permutations when uniqueness of 1 .. n is required.

   -----------------------------------------------------------------------
   --  Construction / insertion
   -----------------------------------------------------------------------

   function Empty_Tableau return Tableau;
   --  The empty Young tableau (zero boxes).

   function Insert (T : Tableau; X : Positive) return Tableau;
   --  Schensted row-insert X into T (strict bumping: leftmost entry > X).
   --  Raises Invalid_Argument if X = 0 conceptually never (Positive) or
   --  if the result would exceed Max_N boxes in a row/column.

   function Insert_Word (W : Word) return Tableau;
   --  Insert each element of W in order; return the insertion tableau P.
   --  Requires W'Length in 1 .. Max_N and that W is a permutation of
   --  1 .. W'Length (distinct positives filling 1 .. n). Raises
   --  Invalid_Argument otherwise.

   procedure Insert_Word_RSK
     (W : Word; P : out Tableau; Q : out Tableau);
   --  Full RSK on a permutation: insertion tableau P and recording
   --  tableau Q (step numbers where new boxes appear). Same validation
   --  as Insert_Word.

   -----------------------------------------------------------------------
   --  Queries
   -----------------------------------------------------------------------

   function Num_Rows (T : Tableau) return Natural;
   function Num_Boxes (T : Tableau) return Natural;
   function Row_Length (T : Tableau; R : Positive) return Natural;
   --  Length of row R (1-based). Returns 0 if R exceeds Num_Rows (T).

   function Element (T : Tableau; R, C : Positive) return Positive;
   --  Entry at row R, column C (1-based). Raises Invalid_Argument if
   --  the position is outside the shape of T.

   function First_Row_Length (T : Tableau) return Natural;
   --  Length of the first row (0 if empty). By Schensted's theorem this
   --  equals the length of a longest increasing subsequence of the word
   --  that produced T via Insert_Word.

   function LIS_Length (W : Word) return Natural;
   --  Length of a longest increasing subsequence of W, computed as
   --  First_Row_Length (Insert_Word (W)).

   function Is_Valid_Tableau (T : Tableau) return Boolean;
   --  True iff rows and columns are strictly increasing and the shape
   --  is a partition (weakly decreasing row lengths).

   function Shape_Equal (A, B : Tableau) return Boolean;
   --  True iff A and B have the same partition shape (ignore entries).

   function Equal (A, B : Tableau) return Boolean;
   --  Entrywise equality including shape.

   function Image (T : Tableau) return String;
   --  Multi-line debug representation of T (rows top to bottom).

private

   type Row_Data is array (1 .. Max_N) of Positive;
   type Rows_Data is array (1 .. Max_N) of Row_Data;
   type Lengths_Data is array (1 .. Max_N) of Natural;

   type Tableau is record
      Data     : Rows_Data    := [others => [others => 1]];
      Lengths  : Lengths_Data := [others => 0];
      Row_Count : Natural     := 0;
   end record;

end Schensted;
