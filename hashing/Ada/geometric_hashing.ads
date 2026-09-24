--  Geometric_Hashing — Ada 2023 educational package for 2-D geometric
--  hashing (Wolfson & Rigoutsos style): offline encoding of a model
--  point set under every ordered basis pair into a quantized (u,v) hash
--  table, and online recognition of a (possibly transformed) scene by
--  voting. Primary source:
--  https://en.wikipedia.org/wiki/Geometric_hashing
--  Sibling packages (README only; do not `with`):
--    Ada-Point-Set-Registration, Ada-RANSAC, Ada-EDT / Ada-Quickhull
--    (ahead) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Geometric_Hashing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on points in a model or scene.
   Max_Points : constant Positive := 24;

   --  Flat entry capacity: ≈ Max_Points*(Max_Points-1)*(Max_Points-2).
   Max_Entries : constant Positive := 12_288;

   --  Default Wikipedia-style quantization bin size.
   Default_Bin_Size : constant Real := 0.25;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Entry_Count is Natural range 0 .. Max_Entries;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Ordered point set (dense indices; length = 'Length).
   type Point_Array is array (Point_Index range <>) of Point;

   --  Educational aliases.
   subtype Model_Points is Point_Array;
   subtype Scene_Points is Point_Array;

   --  Similarity basis frame from an ordered pair (A, B):
   --    origin = midpoint(A,B); x' toward B; y' = 90° CCW;
   --    scale so A ↦ (−1,0) and B ↦ (+1,0) in basis coordinates.
   type Basis is record
      Origin : Point := (X => 0.0, Y => 0.0);
      Ux     : Point := (X => 1.0, Y => 0.0);  -- unit x' axis
      Uy     : Point := (X => 0.0, Y => 1.0);  -- unit y' axis
      Scale  : Real := 1.0;                     -- half |B−A|
      Valid  : Boolean := False;
   end record;

   --  Index pair naming a basis inside a Point_Array.
   type Basis_Pair is record
      I, J : Point_Index := 1;
   end record;

   --  Integer grid key after quantization of (u,v).
   type Hash_Key is record
      U, V : Integer := 0;
   end record;

   --  One hash-table record: quantized coords → (model, basis indices).
   type Table_Entry is record
      Key      : Hash_Key := (U => 0, V => 0);
      Model_Id : Natural := 0;
      Basis_I  : Point_Index := 1;
      Basis_J  : Point_Index := 1;
   end record;

   type Entry_Array is array (Positive range <>) of Table_Entry;

   --  Simple open-list / flat array map (educational; linear lookup).
   type Hash_Table is record
      Count    : Entry_Count := 0;
      Bin_Size : Real := Default_Bin_Size;
      Entries  : Entry_Array (1 .. Max_Entries);
   end record;

   --  Best hypothesis returned by Recognize.
   type Recognition_Result is record
      Found       : Boolean := False;
      Model_Id    : Natural := 0;
      Vote_Count  : Natural := 0;
      Scene_Basis : Basis_Pair := (I => 1, J => 1);
      Model_Basis : Basis_Pair := (I => 1, J => 1);
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when a point set is empty, length > Max_Points, fewer than
   --  3 points for Build_Table / Recognize, Bin_Size ≤ 0, or the flat
   --  entry capacity would be exceeded.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;
   --  Squared Euclidean distance (B − A)·(B − A).

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance ‖B − A‖₂.

   function Same_Key (A, B : Hash_Key) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Basis / quantization
   ---------------------------------------------------------------------------

   function Make_Basis (A, B : Point) return Basis
     with Global => null;
   --  Build the similarity frame. Valid = False if |B−A| < Epsilon.

   function To_Basis_Coords (P : Point; B : Basis) return Point
     with Global => null;
   --  Express P in B's (u,v) coordinates. If not B.Valid, returns (0,0).

   function Quantize
     (UV : Point; Bin_Size : Real := Default_Bin_Size) return Hash_Key
     with Global => null;
   --  Integer bins via rounding: (round(u/bin), round(v/bin)).
   --  Raises Invalid_Argument if Bin_Size ≤ 0.

   function Quantize_Point
     (P        : Point;
      B        : Basis;
      Bin_Size : Real := Default_Bin_Size) return Hash_Key
     with Global => null;
   --  To_Basis_Coords then Quantize.

   ---------------------------------------------------------------------------
   -- Hash table (offline)
   ---------------------------------------------------------------------------

   function Empty_Table
     (Bin_Size : Real := Default_Bin_Size) return Hash_Table
     with Global => null;
   --  Raises Invalid_Argument if Bin_Size ≤ 0.

   function Entry_Length (Table : Hash_Table) return Entry_Count
     with Global => null;

   function Build_Table
     (Model     : Point_Array;
      Model_Id  : Natural := 1;
      Bin_Size  : Real := Default_Bin_Size) return Hash_Table
     with Global => null;
   --  For every ordered basis pair (i,j) with a valid frame, store each
   --  remaining point's quantized (u,v) with (Model_Id, i, j).
   --  Raises Invalid_Argument if Model'Length < 3, > Max_Points, or
   --  Bin_Size ≤ 0, or capacity would overflow.

   function Lookup_Count
     (Table : Hash_Table; Key : Hash_Key) return Natural
     with Global => null;
   --  Number of entries whose key equals Key (linear scan).

   ---------------------------------------------------------------------------
   -- Recognition (online)
   ---------------------------------------------------------------------------

   function Recognize
     (Scene       : Point_Array;
      Table       : Hash_Table;
      Min_Votes   : Natural := 1) return Recognition_Result
     with Global => null;
   --  For every ordered scene basis pair, accumulate votes for matching
   --  (model_id, model_basis) hypotheses via quantized lookups; return
   --  the highest-vote hypothesis with Vote_Count ≥ Min_Votes.
   --  Raises Invalid_Argument if Scene'Length < 3 or > Max_Points, or
   --  Table is empty.

end Geometric_Hashing;
