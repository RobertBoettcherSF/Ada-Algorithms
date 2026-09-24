--  Algorithm_X body — dense-matrix Knuth Algorithm X with active masks.

pragma Ada_2022;

package body Algorithm_X is

   -----------------------------------------------------------------------
   -- Clear / builders
   -----------------------------------------------------------------------

   procedure Clear (S : out Solver) is
   begin
      S := (others => <>);
   end Clear;

   procedure Activate_All (S : in out Solver) is
   begin
      S.Active_Row := [others => False];
      S.Active_Col := [others => False];
      for R in 1 .. S.Num_Rows loop
         S.Active_Row (R) := True;
      end loop;
      for C in 1 .. S.Num_Columns loop
         S.Active_Col (C) := True;
      end loop;
   end Activate_All;

   procedure Build_From_Matrix
     (S             : out Solver;
      Matrix        : Bool_Matrix;
      Primary_Count : Column_Count := 0)
   is
      Rows : Row_Count;
      Cols : Column_Count;
      Prim : Column_Count;
   begin
      Clear (S);

      if Matrix'Length (1) = 0 and then Matrix'Length (2) = 0 then
         return;
      end if;

      if Matrix'Length (1) > Max_Rows or else Matrix'Length (2) > Max_Columns
      then
         raise Capacity_Exceeded;
      end if;

      if Matrix'First (1) /= 1 or else Matrix'First (2) /= 1 then
         raise Invalid_Argument;
      end if;

      Rows := Row_Count (Matrix'Length (1));
      Cols := Column_Count (Matrix'Length (2));

      if Primary_Count = 0 then
         Prim := Cols;
      else
         Prim := Primary_Count;
      end if;
      if Prim > Cols then
         raise Invalid_Argument;
      end if;

      S.Num_Rows := Rows;
      S.Num_Columns := Cols;
      S.Num_Primary := Prim;

      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            S.Matrix (R, C) := Matrix (Positive (R), Positive (C));
         end loop;
      end loop;

      Activate_All (S);
   end Build_From_Matrix;

   procedure Build_From_Row_Sets
     (S             : out Solver;
      Num_Columns   : Column_Count;
      Row_Sets      : Bool_Matrix;
      Primary_Count : Column_Count := 0)
   is
   begin
      if Row_Sets'Length (2) /= Natural (Num_Columns) then
         raise Invalid_Argument;
      end if;
      Build_From_Matrix (S, Row_Sets, Primary_Count);
   end Build_From_Row_Sets;

   -----------------------------------------------------------------------
   -- Structure helpers
   -----------------------------------------------------------------------

   function Active_Primary_Count (S : Solver) return Natural is
      Count : Natural := 0;
   begin
      for C in 1 .. S.Num_Primary loop
         if S.Active_Col (C) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Active_Primary_Count;

   function Active_Row_Count (S : Solver) return Natural is
      Count : Natural := 0;
   begin
      for R in 1 .. S.Num_Rows loop
         if S.Active_Row (R) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Active_Row_Count;

   function Column_Ones (S : Solver; C : Column_Id) return Natural is
      Count : Natural := 0;
   begin
      if C = 0 or else C > Column_Id (S.Num_Columns) then
         raise Invalid_Argument;
      end if;
      if not S.Active_Col (C) then
         return 0;
      end if;
      for R in 1 .. S.Num_Rows loop
         if S.Active_Row (R) and then S.Matrix (R, C) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Column_Ones;

   function State_Fingerprint (S : Solver) return Natural is
      H : Natural := 0;
   begin
      H := Natural (S.Num_Rows) * 131 + Natural (S.Num_Columns) * 17
        + Natural (S.Num_Primary);
      for R in 1 .. S.Num_Rows loop
         if S.Active_Row (R) then
            H := H + R * 3;
         end if;
      end loop;
      for C in 1 .. S.Num_Columns loop
         if S.Active_Col (C) then
            H := H + C * 5 + 1000;
         end if;
      end loop;
      --  Mix in a few matrix bits so Cover-like edits are visible if any.
      for R in 1 .. S.Num_Rows loop
         for C in 1 .. S.Num_Columns loop
            if S.Matrix (R, C) then
               H := H + R * 37 + C * 41;
            end if;
         end loop;
      end loop;
      return H;
   end State_Fingerprint;

   function Snapshot (S : Solver) return Active_State is
   begin
      return (Rows => S.Active_Row, Cols => S.Active_Col);
   end Snapshot;

   procedure Restore (S : in out Solver; St : Active_State) is
   begin
      S.Active_Row := St.Rows;
      S.Active_Col := St.Cols;
   end Restore;

   -----------------------------------------------------------------------
   -- Knuth primitives
   -----------------------------------------------------------------------

   function Choose_Column (S : Solver) return Column_Id is
      Best   : Column_Id := 0;
      Best_N : Natural := Natural'Last;
      Ones   : Natural;
   begin
      for C in 1 .. S.Num_Primary loop
         if S.Active_Col (C) then
            Ones := Column_Ones (S, C);
            if Ones < Best_N then
               Best_N := Ones;
               Best := C;
            end if;
         end if;
      end loop;
      return Best;
   end Choose_Column;

   procedure Select_Row (S : in out Solver; R : Row_Id) is
   begin
      if R = 0 or else R > Row_Id (S.Num_Rows) then
         raise Invalid_Argument;
      end if;

      --  For each column j covered by R, delete every row with a 1 in j,
      --  then delete column j (Wikipedia Algorithm X step).
      for J in 1 .. S.Num_Columns loop
         if S.Active_Col (J) and then S.Matrix (R, J) then
            for I in 1 .. S.Num_Rows loop
               if S.Active_Row (I) and then S.Matrix (I, J) then
                  S.Active_Row (I) := False;
               end if;
            end loop;
            S.Active_Col (J) := False;
         end if;
      end loop;
   end Select_Row;

   -----------------------------------------------------------------------
   -- Search
   -----------------------------------------------------------------------

   type Partial is record
      Length : Natural := 0;
      Rows   : Row_Id_List := [others => 0];
   end record;

   procedure Search
     (S         : in out Solver;
      Partial_S : in out Partial;
      Solutions : access Solution_Array;
      Count     : in out Natural;
      Cap       : Natural;
      Stop      : in out Boolean;
      Store     : Boolean)
   is
      C   : Column_Id;
      St  : Active_State;
      Sol : Solution;
   begin
      if Stop then
         return;
      end if;

      --  No active primary columns → exact cover found.
      if Active_Primary_Count (S) = 0 then
         if Store and then Count < Cap and then Solutions /= null then
            Sol.Length := Partial_S.Length;
            Sol.Rows := Partial_S.Rows;
            Count := Count + 1;
            Solutions (Count) := Sol;
         else
            Count := Count + 1;
         end if;
         if Count >= Cap then
            Stop := True;
         end if;
         return;
      end if;

      C := Choose_Column (S);
      if C = 0 then
         return;
      end if;

      --  If the chosen column has zero 1s, the loop below is empty → fail.
      for R in 1 .. S.Num_Rows loop
         if S.Active_Row (R) and then S.Matrix (R, C) then
            if Partial_S.Length >= Max_Solution_Length then
               raise Capacity_Exceeded;
            end if;

            St := Snapshot (S);
            Partial_S.Length := Partial_S.Length + 1;
            Partial_S.Rows (Partial_S.Length) := R;

            Select_Row (S, R);
            Search (S, Partial_S, Solutions, Count, Cap, Stop, Store);
            Restore (S, St);

            Partial_S.Length := Partial_S.Length - 1;
            exit when Stop;
         end if;
      end loop;
   end Search;

   procedure Run_Search
     (S         : in out Solver;
      Solutions : access Solution_Array;
      Count     : out Natural;
      Cap       : Natural;
      Store     : Boolean)
   is
      Partial_S : Partial;
      Stop      : Boolean := False;
      Limit     : Natural;
      Root      : constant Active_State := Snapshot (S);
   begin
      if Cap = 0 then
         Count := 0;
         return;
      end if;
      Limit := Cap;
      if Store and then Limit > Max_Solutions then
         Limit := Max_Solutions;
      end if;
      Count := 0;
      Partial_S := (others => <>);
      Search (S, Partial_S, Solutions, Count, Limit, Stop, Store);
      Restore (S, Root);
   end Run_Search;

   procedure Solve
     (S       : in out Solver;
      Found   : out Solution;
      Success : out Boolean)
   is
      Arr   : aliased Solution_Array;
      Count : Natural;
   begin
      Found := (others => <>);
      Run_Search (S, Arr'Access, Count, 1, True);
      if Count >= 1 then
         Found := Arr (1);
         Success := True;
      else
         Success := False;
      end if;
   end Solve;

   procedure Solve_All
     (S         : in out Solver;
      Solutions : out Solution_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions)
   is
      Arr : aliased Solution_Array;
   begin
      Solutions := [others => <>];
      Run_Search (S, Arr'Access, Count, Cap, True);
      for I in 1 .. Count loop
         if I <= Max_Solutions then
            Solutions (I) := Arr (I);
         end if;
      end loop;
   end Solve_All;

   function Count_Solutions
     (S   : in out Solver;
      Cap : Natural := 256) return Natural
   is
      Count : Natural;
   begin
      Run_Search (S, null, Count, Cap, False);
      return Count;
   end Count_Solutions;

   -----------------------------------------------------------------------
   -- N-queens
   -----------------------------------------------------------------------

   function N_Queens_Column_Count (N : Queens_N) return Column_Count is
   begin
      return Column_Count (6 * Natural (N) - 2);
   end N_Queens_Column_Count;

   procedure Build_N_Queens
     (S : out Solver;
      N : Queens_N)
   is
      --  Columns:
      --    1 .. N              : rows (primary)
      --    N+1 .. 2N           : cols (primary)
      --    2N+1 .. 4N-1        : diag r-c+N     (secondary), 2N-1 of them
      --    4N .. 6N-2          : diag r+c-1     (secondary), 2N-1 of them
      Cols   : constant Column_Count := N_Queens_Column_Count (N);
      Prim   : constant Column_Count := Column_Count (2 * Natural (N));
      Rows   : constant Positive := Natural (N) * Natural (N);
      Matrix : Bool_Matrix (1 .. Rows, 1 .. Positive (Cols)) :=
        [others => [others => False]];
      Idx    : Positive;
      D1, D2 : Positive;
   begin
      for R in 1 .. Natural (N) loop
         for C in 1 .. Natural (N) loop
            Idx := (R - 1) * Natural (N) + C;
            Matrix (Idx, R) := True;
            Matrix (Idx, Natural (N) + C) := True;
            D1 := R - C + Natural (N);  -- 1 .. 2N-1
            D2 := R + C - 1;            -- 1 .. 2N-1
            Matrix (Idx, 2 * Natural (N) + D1) := True;
            Matrix (Idx, 4 * Natural (N) - 1 + D2) := True;
         end loop;
      end loop;
      Build_From_Matrix (S, Matrix, Prim);
   end Build_N_Queens;

   function N_Queens_Count
     (N   : Queens_N;
      Cap : Natural := 256) return Natural
   is
      S : Solver;
   begin
      Build_N_Queens (S, N);
      return Count_Solutions (S, Cap);
   end N_Queens_Count;

   procedure N_Queens_Solve
     (N         : Queens_N;
      Solutions : out Solution_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions)
   is
      S : Solver;
   begin
      Build_N_Queens (S, N);
      Solve_All (S, Solutions, Count, Cap);
   end N_Queens_Solve;

   -----------------------------------------------------------------------
   -- Knuth textbook example (Wikipedia Algorithm X matrix)
   -----------------------------------------------------------------------

   procedure Build_Knuth_Example (S : out Solver) is
      --  Universe {1..7}; sets A..F as on Wikipedia Algorithm X:
      --  A={1,4,7}, B={1,4}, C={4,5,7}, D={3,5,6}, E={2,3,6,7}, F={2,7}.
      --  Unique exact cover {B,D,F} → rows 2, 4, 6 (1-based).
      M : constant Bool_Matrix (1 .. 6, 1 .. 7) :=
        [[True,  False, False, True,  False, False, True],   -- A
         [True,  False, False, True,  False, False, False],  -- B
         [False, False, False, True,  True,  False, True],   -- C
         [False, False, True,  False, True,  True,  False],  -- D
         [False, True,  True,  False, False, True,  True],   -- E
         [False, True,  False, False, False, False, True]];  -- F
   begin
      Build_From_Matrix (S, M, 0);
   end Build_Knuth_Example;

   function Knuth_Example_Solution_Count return Natural is
      S : Solver;
   begin
      Build_Knuth_Example (S);
      return Count_Solutions (S, Max_Solutions);
   end Knuth_Example_Solution_Count;

end Algorithm_X;
