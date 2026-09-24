--  Tabu_Search — Ada 2023 educational package for Wikipedia
--  "Tabu search" (Glover 1986/1989): metaheuristic local search that
--  accepts the best admissible neighbor each iteration (possibly
--  worsening) while forbidding recent reverse moves via a short-term
--  tabu list; aspiration may override tabu when a move improves the
--  global best. Primary source:
--  https://en.wikipedia.org/wiki/Tabu_search
--  Siblings: Ada-Simulated-Annealing / Ada-Random-Search (README links).

pragma Ada_2022;

package Tabu_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Max_Iterations : hard iteration budget
   --  Tenure         : how many iterations an attribute stays tabu
   --  Max_Tabu       : circular attribute buffer capacity
   --  Use_Aspiration : allow tabu move if it beats global best
   type Config is record
      Max_Iterations : Positive := 500;
      Tenure         : Positive := 7;
      Max_Tabu       : Positive := 64;
      Use_Aspiration : Boolean  := True;
   end record;

   type Result is record
      Best_Cost         : Real    := 0.0;
      Final_Cost        : Real    := 0.0;
      Iters             : Natural := 0;
      Moves_Accepted    : Natural := 0;
      Aspiration_Count  : Natural := 0;
      Tabu_Reject_Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Short-term tabu list (circular attribute memory with tenure)
   ---------------------------------------------------------------------------

   Max_Tabu_Cap : constant Positive := 256;

   type Tabu_Entry is record
      Attr   : Natural := 0;
      Expiry : Natural := 0;  -- exclusive: active while Clock < Expiry
      Active : Boolean := False;
   end record;

   type Tabu_Buffer is array (Positive range <>) of Tabu_Entry;

   --  Capacity is fixed at elaboration; Clock advances with search iters.
   type Tabu_List (Capacity : Positive) is record
      Buf   : Tabu_Buffer (1 .. Capacity) := [others => <>];
      Next  : Positive := 1;  -- next write slot (circular)
      Count : Natural  := 0;
      Clock : Natural  := 0;
   end record;

   procedure Clear (L : in out Tabu_List)
     with Global => null;
   --  Deactivate all entries; reset Next/Count; leave Clock unchanged
   --  unless Reset_Clock is used.

   procedure Reset_Clock (L : in out Tabu_List; Clock : Natural := 0)
     with Global => null;

   procedure Set_Clock (L : in out Tabu_List; Clock : Natural)
     with Global => null;
   --  Set current iteration clock (expiry comparisons use Clock < Expiry).

   procedure Push
     (L      : in out Tabu_List;
      Attr   : Natural;
      Tenure : Positive)
     with Global => null;
   --  Record Attr as tabu until Clock + Tenure. Overwrites oldest slot
   --  when full (circular FIFO).

   function Contains (L : Tabu_List; Attr : Natural) return Boolean
     with Global => null;
   --  True iff some active entry has Attr and Clock < Expiry.

   function Is_Admissible
     (L              : Tabu_List;
      Attr           : Natural;
      Candidate_Cost : Real;
      Best_Cost      : Real;
      Use_Aspiration : Boolean) return Boolean
     with Global => null;
   --  Not tabu, or (Use_Aspiration and Candidate_Cost < Best_Cost).

   function Active_Count (L : Tabu_List) return Natural
     with Global => null;
   --  Number of currently unexpired active entries.

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Bit-string demos: OneMax (minimize zeros) / Hamming to target
   ---------------------------------------------------------------------------

   Max_Bits : constant := 32;
   subtype Bit_Count is Positive range 1 .. Max_Bits;
   type Bit_String is array (Positive range <>) of Boolean;

   type Bit_Result is record
      Best_Bits         : Bit_String (1 .. Max_Bits) := [others => False];
      N                 : Bit_Count := 1;
      Best_Cost         : Real    := 0.0;
      Final_Cost        : Real    := 0.0;
      Iters             : Natural := 0;
      Moves_Accepted    : Natural := 0;
      Aspiration_Count  : Natural := 0;
      Tabu_Reject_Count : Natural := 0;
   end record;

   function Hamming_Distance (A, B : Bit_String) return Natural
     with Pre => A'Length = B'Length, Global => null;

   function Zero_Count (Bits : Bit_String) return Natural
     with Global => null;
   --  Number of False bits (OneMax cost when minimizing).

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   --  Attribute for a bit flip is the 1-based bit index.
   function Minimize_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
     with Pre => Start'Length = Target'Length
            and then Start'Length >= 1
            and then Start'Length <= Max_Bits,
          Global => null;
   --  Single-bit-flip neighborhood; tabu attribute = flipped index.
   --  Cost = Hamming distance to Target. Aspiration on global best.

   function Minimize_OneMax
     (Start : Bit_String;
      Cfg   : Config) return Bit_Result
     with Pre => Start'Length >= 1 and then Start'Length <= Max_Bits,
          Global => null;
   --  OneMax as minimize zeros (target = all True).

   ---------------------------------------------------------------------------
   -- Small TSP / permutation with 2-opt neighborhood (n ≤ 12)
   ---------------------------------------------------------------------------

   Max_Cities : constant := 12;
   subtype City_Count is Positive range 2 .. Max_Cities;
   type City_Index is range 1 .. Max_Cities;
   type Tour is array (City_Index range <>) of City_Index;
   type Dist_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type TSP_Result is record
      Best_Tour         : Tour (1 .. Max_Cities) := [others => 1];
      N                 : City_Count := 2;
      Best_Length       : Non_Negative := 0.0;
      Final_Length      : Non_Negative := 0.0;
      Iters             : Natural := 0;
      Moves_Accepted    : Natural := 0;
      Aspiration_Count  : Natural := 0;
      Tabu_Reject_Count : Natural := 0;
   end record;

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative
     with Pre => T'First = D'First (1)
            and then T'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2),
          Global => null;

   function Apply_2Opt
     (T : Tour; I, J : City_Index) return Tour
     with Pre => I in T'Range
            and then J in T'Range
            and then I < J,
          Global => null;
   --  Reverse the segment T(I+1 .. J) (classic 2-opt on positions).

   function Encode_2Opt_Attr (I, J : City_Index) return Natural
     with Global => null;
   --  Pack (I,J) into a single Natural attribute: I * (Max_Cities+1) + J.

   function Minimize_TSP
     (D     : Dist_Matrix;
      Start : Tour;
      Cfg   : Config) return TSP_Result
     with Pre => Start'First = D'First (1)
            and then Start'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then Start'Length >= 2
            and then Start'Length <= Max_Cities,
          Global => null;
   --  Exhaustive best-admissible 2-opt each iteration; tabu on (I,J).

   ---------------------------------------------------------------------------
   -- Tiny number-partitioning demo (n ≤ 16)
   ---------------------------------------------------------------------------

   Max_Parts : constant := 16;
   subtype Part_Count is Positive range 1 .. Max_Parts;
   type Weights is array (Positive range <>) of Non_Negative;
   type Assignment is array (Positive range <>) of Boolean;
   --  True → set A, False → set B; cost = |sum(A) − sum(B)|.

   type Partition_Result is record
      Best_Assign       : Assignment (1 .. Max_Parts) := [others => False];
      N                 : Part_Count := 1;
      Best_Cost         : Non_Negative := 0.0;
      Final_Cost        : Non_Negative := 0.0;
      Iters             : Natural := 0;
      Moves_Accepted    : Natural := 0;
      Aspiration_Count  : Natural := 0;
      Tabu_Reject_Count : Natural := 0;
   end record;

   function Partition_Cost
     (W : Weights; A : Assignment) return Non_Negative
     with Pre => W'Length = A'Length, Global => null;

   function Minimize_Partition
     (W     : Weights;
      Start : Assignment;
      Cfg   : Config) return Partition_Result
     with Pre => W'Length = Start'Length
            and then W'Length >= 1
            and then W'Length <= Max_Parts,
          Global => null;
   --  Flip one item's set membership; tabu attribute = item index.

   ---------------------------------------------------------------------------
   -- Convenience: pack Bit / TSP / Partition results into Result
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result
     with Global => null;
   function To_Result (R : TSP_Result) return Result
     with Global => null;
   function To_Result (R : Partition_Result) return Result
     with Global => null;

end Tabu_Search;
