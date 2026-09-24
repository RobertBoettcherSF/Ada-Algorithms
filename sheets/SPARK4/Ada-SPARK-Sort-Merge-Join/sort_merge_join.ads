--  Sort_Merge_Join — Ada/SPARK Level 4 educational package for the classic
--  inner sort-merge join on two relations already sorted by Integer key.
--  Emits matching pairs and supports many-to-many Cartesian expansion on
--  equal keys. Optional Unique_Key_Join when Left keys are strictly unique
--  (one-to-many / one-to-one; no left-run backtracking).
--
--  SPARK port of Ada-Sort-Merge-Join: hard Max_N / Max_Out bounds, no
--  exceptions, no Ada.Containers / Unbounded_String. Row is an educational
--  stand-in (Key, Payload : Integer). Non-SPARK sibling uses Unbounded_String
--  Data, Vectors for output, Auto_Sort via Generic_Array_Sort, and raises
--  Unsorted_Relation_Error / Non_Unique_Key_Error. This port requires
--  1-based pre-sorted inputs (Is_Sorted_By_Key), a static Joined_Relation
--  buffer of capacity Max_Out, and a product-capacity Pre so Level 4 can
--  discharge Last ≤ Max_Out without a Success flag. Full matching /
--  multiset correctness is verified by tests rather than claimed as a
--  Level-4 postcondition (nondecreasing Result Left.Key is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Sort-merge_join

package Sort_Merge_Join
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Maximum rows per input relation. Sibling is unbounded (Vectors).
   Max_N : constant Positive := 32;

   --  Maximum joined output rows (caps Cartesian expansion).
   --  Callers must satisfy |Left| · |Right| ≤ Max_Out (safe upper bound
   --  on the join size). Tests use small data within this cap.
   Max_Out : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Row is record
      Key     : Integer;
      Payload : Integer;
   end record;

   --  Live indices are 1 .. N with N ≤ Max_N. Empty relations use Last = 0.
   type Relation is array (Positive range <>) of Row;

   type Joined_Row is record
      Left  : Row;
      Right : Row;
   end record;

   type Joined_Relation is array (Positive range <>) of Joined_Row;

   ---------------------------------------------------------------------------
   -- Shape / sortedness / uniqueness guards (expression functions)
   ---------------------------------------------------------------------------

   function In_Bounds_Rel (R : Relation) return Boolean is
     (R'First = 1 and then R'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard for 1-based input relations up to Max_N.

   function In_Bounds_Out (R : Joined_Relation) return Boolean is
     (R'First = 1 and then R'Last >= Max_Out)
   with Global => null;
   --  Output buffer must provide at least Max_Out slots (1-based).

   function Is_Sorted_By_Key (R : Relation) return Boolean is
     (for all I in R'First .. R'Last - 1 => R (I).Key <= R (I + 1).Key)
   with
     Global => null,
     Pre    => In_Bounds_Rel (R);
   --  True iff R is adjacent-nondecreasing on Key (empty / singleton
   --  vacuous).

   function Keys_Unique (R : Relation) return Boolean is
     (for all I in R'First .. R'Last - 1 => R (I).Key < R (I + 1).Key)
   with
     Global => null,
     Pre    => In_Bounds_Rel (R);
   --  True iff Keys are strictly increasing (hence unique). Implies
   --  Is_Sorted_By_Key.

   function Result_Keys_Nondecreasing
     (Result : Joined_Relation;
      Last   : Natural) return Boolean
   is
     (Last <= Result'Last
      and then
        (Last <= 1
         or else
           (for all I in 1 .. Last - 1 =>
              Result (I).Left.Key <= Result (I + 1).Left.Key)))
   with
     Global => null,
     Pre    => Result'First = 1 and then Last <= Result'Last;
   --  True iff Result (1 .. Last) is adjacent-nondecreasing on Left.Key.

   function Product_Fits (Left, Right : Relation) return Boolean is
     (Natural (Left'Last) * Natural (Right'Last) <= Max_Out)
   with
     Global => null,
     Pre    => In_Bounds_Rel (Left) and then In_Bounds_Rel (Right);
   --  Safe capacity guard: |L|·|R| upper-bounds any inner-join size
   --  (including full Cartesian on a single shared key).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic sort-merge join / Wikipedia)
   ---------------------------------------------------------------------------
   --  Preconditions: both relations 1-based, length ≤ Max_N, sorted by Key,
   --  output buffer ≥ Max_Out, and |L|·|R| ≤ Max_Out.
   --  Two cursors I, J advance over Left / Right:
   --    if Left(I).Key < Right(J).Key then I := I + 1
   --    elsif Left(I).Key > Right(J).Key then J := J + 1
   --    else  -- equal keys: locate runs [I0..I1], [J0..J1] and emit the
   --          Cartesian product Left(I0..I1) × Right(J0..J1), then advance
   --          both cursors past those runs.
   --  Loop invariant: Result (1 .. OI) is nondecreasing on Left.Key and
   --  OI ≤ |L|·|R| ≤ Max_Out.
   --  Unique_Key_Join: Left keys strictly unique — for each match emit
   --  Left(I) against the Right run without a left-run nested loop, then
   --  advance I (and J past the Right run). Output size ≤ |Right|.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Join
   ---------------------------------------------------------------------------

   procedure Inner_Join
     (Left, Right : Relation;
      Result      : out Joined_Relation;
      Last        : out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds_Rel (Left)
       and then In_Bounds_Rel (Right)
       and then Result'First = 1
       and then Result'Last >= Max_Out
       and then Is_Sorted_By_Key (Left)
       and then Is_Sorted_By_Key (Right)
       and then Product_Fits (Left, Right),
     Post   =>
       Last <= Max_Out
       and then Last <= Result'Last
       and then Result_Keys_Nondecreasing (Result, Last);
   --  Classic many-to-many inner sort-merge join. Writes matching pairs
   --  into Result (1 .. Last). Remaining Result slots are zeroed.
   --  Post proves Last ≤ Max_Out and nondecreasing Left.Key order;
   --  matching correctness is checked by the test suite.

   procedure Unique_Key_Join
     (Left, Right : Relation;
      Result      : out Joined_Relation;
      Last        : out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds_Rel (Left)
       and then In_Bounds_Rel (Right)
       and then Result'First = 1
       and then Result'Last >= Max_Out
       and then Keys_Unique (Left)
       and then Is_Sorted_By_Key (Right)
       and then Right'Last <= Max_Out,
     Post   =>
       Last <= Max_Out
       and then Last <= Result'Last
       and then Result_Keys_Nondecreasing (Result, Last);
   --  Optimized one-to-many / one-to-one variant: Left keys must be
   --  strictly unique (Keys_Unique). No left-run Cartesian nesting.
   --  Output size ≤ |Right| (each Right row matches at most one Left).

end Sort_Merge_Join;
