--  Min_Conflicts body — N-queens min-conflicts hill-climbing + map sketch.

pragma Ada_2022;

package body Min_Conflicts
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- LCG: Numerical Recipes style (a=1664525, c=1013904223)
   ---------------------------------------------------------------------------

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      State := RNG_State (Seed);
      --  Warm the generator so seed 0 is still usable.
      State := State * 1_664_525 + 1_013_904_223;
   end Seed_RNG;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      Span : constant Natural := Hi - Lo + 1;
   begin
      State := State * 1_664_525 + 1_013_904_223;
      return Lo + Natural (State rem RNG_State (Span));
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Defaults / builders
   ---------------------------------------------------------------------------

   function Default_Parameters
     (Max_Steps : Natural := 1_000;
      Seed      : Natural := 1;
      Restarts  : Natural := 0) return Parameters
   is
   begin
      return (Max_Steps => Max_Steps, Seed => Seed, Restarts => Restarts);
   end Default_Parameters;

   procedure Random_Board
     (B     : out Board;
      N     : Queens_N;
      State : in out RNG_State)
   is
   begin
      for R in 1 .. N loop
         B (R) := Next_Natural (State, 1, N);
      end loop;
   end Random_Board;

   --  Conflicts for placing a queen at (Row, Col) ignoring the current
   --  occupant of Row (used by greedy init and Min_Conflict_Value).
   function Conflicts_At
     (B : Board; Row : Positive; Col : Positive) return Natural
   is
      Count : Natural := 0;
      N     : constant Positive := B'Length;
      C2    : Positive;
      DR    : Natural;
   begin
      for R2 in 1 .. N loop
         if R2 /= Row then
            C2 := B (R2);
            if C2 = Col then
               Count := Count + 1;
            else
               DR := abs (Integer (R2) - Integer (Row));
               if DR = abs (Integer (C2) - Integer (Col)) then
                  Count := Count + 1;
               end if;
            end if;
         end if;
      end loop;
      return Count;
   end Conflicts_At;

   procedure Greedy_Board
     (B     : out Board;
      N     : Queens_N;
      State : in out RNG_State)
   is
      Best_Col  : Positive;
      Best_Conf : Natural;
      Conf      : Natural;
      Tie_Count : Natural;
      Pick      : Natural;
   begin
      --  Placeholder fill so the board is a complete assignment throughout;
      --  only rows 1 .. Row-1 are consulted when placing Row.
      for R in 1 .. N loop
         B (R) := 1;
      end loop;

      for Row in 1 .. N loop
         Best_Conf := Natural'Last;
         Best_Col  := 1;
         Tie_Count := 0;

         for Col in 1 .. N loop
            Conf := 0;
            for R2 in 1 .. Row - 1 loop
               if B (R2) = Col then
                  Conf := Conf + 1;
               elsif abs (Integer (R2) - Integer (Row)) =
                 abs (Integer (B (R2)) - Integer (Col))
               then
                  Conf := Conf + 1;
               end if;
            end loop;

            if Conf < Best_Conf then
               Best_Conf := Conf;
               Best_Col  := Col;
               Tie_Count := 1;
            elsif Conf = Best_Conf then
               Tie_Count := Tie_Count + 1;
               Pick := Next_Natural (State, 1, Tie_Count);
               if Pick = Tie_Count then
                  Best_Col := Col;
               end if;
            end if;
         end loop;

         B (Row) := Best_Col;
      end loop;
   end Greedy_Board;

   ---------------------------------------------------------------------------
   -- Conflict counting
   ---------------------------------------------------------------------------

   function Variable_Conflicts (B : Board; Row : Positive) return Natural is
   begin
      return Conflicts_At (B, Row, B (Row));
   end Variable_Conflicts;

   function Conflict_Count (B : Board) return Natural is
      Total : Natural := 0;
   begin
      for R in B'Range loop
         Total := Total + Variable_Conflicts (B, R);
      end loop;
      return Total / 2;
   end Conflict_Count;

   function Is_Solved (B : Board) return Boolean is
   begin
      return Conflict_Count (B) = 0;
   end Is_Solved;

   ---------------------------------------------------------------------------
   -- Core operators
   ---------------------------------------------------------------------------

   function Min_Conflict_Value
     (B     : Board;
      Row   : Positive;
      State : in out RNG_State) return Column_Index
   is
      N          : constant Positive := B'Length;
      Current    : constant Positive := B (Row);
      Best_Conf  : Natural := Natural'Last;
      Conf       : Natural;
      --  Collect all min-conflict columns, then prefer a non-current
      --  column among ties so plateaus still move (sideways escape).
      Candidates : array (1 .. Max_N) of Positive := [others => 1];
      Count      : Natural := 0;
      Pick       : Natural;
   begin
      for Col in 1 .. N loop
         Conf := Conflicts_At (B, Row, Col);
         if Conf < Best_Conf then
            Best_Conf := Conf;
            Count := 1;
            Candidates (1) := Col;
         elsif Conf = Best_Conf then
            Count := Count + 1;
            Candidates (Count) := Col;
         end if;
      end loop;

      --  Prefer candidates other than Current when available.
      declare
         Alt_Count : Natural := 0;
         Alts      : array (1 .. Max_N) of Positive := [others => 1];
      begin
         for I in 1 .. Count loop
            if Candidates (I) /= Current then
               Alt_Count := Alt_Count + 1;
               Alts (Alt_Count) := Candidates (I);
            end if;
         end loop;
         if Alt_Count > 0 then
            Pick := Next_Natural (State, 1, Alt_Count);
            return Alts (Pick);
         end if;
      end;

      Pick := Next_Natural (State, 1, Count);
      return Candidates (Pick);
   end Min_Conflict_Value;

   function Pick_Conflicted_Variable
     (B     : Board;
      State : in out RNG_State) return Natural
   is
      N      : constant Positive := B'Length;
      Count  : Natural := 0;
      Pick   : Natural;
      Chosen : Natural := 0;
   begin
      for R in 1 .. N loop
         if Variable_Conflicts (B, R) > 0 then
            Count := Count + 1;
            Pick := Next_Natural (State, 1, Count);
            if Pick = Count then
               Chosen := R;
            end if;
         end if;
      end loop;
      return Chosen;
   end Pick_Conflicted_Variable;

   procedure Step
     (B     : in out Board;
      State : in out RNG_State;
      Moved : out Boolean)
   is
      Row : Natural;
   begin
      Row := Pick_Conflicted_Variable (B, State);
      if Row = 0 then
         Moved := False;
         return;
      end if;
      B (Row) := Min_Conflict_Value (B, Row, State);
      Moved := True;
   end Step;

   ---------------------------------------------------------------------------
   -- Solvers
   ---------------------------------------------------------------------------

   procedure Minimize_Conflicts
     (B      : in out Board;
      Params : Parameters;
      Result : out Solve_Result)
   is
      State : RNG_State;
      Moved : Boolean;
      Steps : Natural := 0;
   begin
      Seed_RNG (State, Params.Seed);
      Result :=
        (Solved          => False,
         Steps_Used      => 0,
         Restarts_Used   => 0,
         Final_Conflicts => Conflict_Count (B));

      if Is_Solved (B) then
         Result.Solved := True;
         Result.Final_Conflicts := 0;
         return;
      end if;

      for I in 1 .. Params.Max_Steps loop
         Step (B, State, Moved);
         Steps := Steps + 1;
         if not Moved or else Is_Solved (B) then
            exit;
         end if;
      end loop;

      Result.Steps_Used := Steps;
      Result.Final_Conflicts := Conflict_Count (B);
      Result.Solved := Result.Final_Conflicts = 0;
   end Minimize_Conflicts;

   procedure Solve_N_Queens
     (N      : Queens_N;
      Params : Parameters;
      B      : out Board;
      Result : out Solve_Result)
   is
      State   : RNG_State;
      Moved   : Boolean;
      Steps   : Natural;
      Attempt : Natural;
   begin
      Seed_RNG (State, Params.Seed);
      Result :=
        (Solved          => False,
         Steps_Used      => 0,
         Restarts_Used   => 0,
         Final_Conflicts => 0);

      Attempt := 0;
      loop
         --  Alternate greedy (Minton-style) and uniform random starts so
         --  small-N plateaus are less sticky across restarts.
         if Attempt mod 2 = 0 then
            Greedy_Board (B, N, State);
         else
            Random_Board (B, N, State);
         end if;
         Steps := 0;

         if not Is_Solved (B) then
            for I in 1 .. Params.Max_Steps loop
               Step (B, State, Moved);
               Steps := Steps + 1;
               if not Moved or else Is_Solved (B) then
                  exit;
               end if;
            end loop;
         end if;

         Result.Steps_Used := Result.Steps_Used + Steps;
         Result.Final_Conflicts := Conflict_Count (B);

         if Result.Final_Conflicts = 0 then
            Result.Solved := True;
            Result.Restarts_Used := Attempt;
            return;
         end if;

         exit when Attempt >= Params.Restarts;
         Attempt := Attempt + 1;
         Result.Restarts_Used := Attempt;
      end loop;

      Result.Solved := False;
   end Solve_N_Queens;

   ---------------------------------------------------------------------------
   -- Map coloring sketch
   ---------------------------------------------------------------------------

   procedure Build_Four_Region_Map (CSP : out Map_CSP) is
   begin
      CSP.Num_Regions := 4;
      CSP.Num_Colors  := 3;
      CSP.Num_Edges   := 5;
      CSP.Edges := [others => (1, 1)];
      --  Cycle 1-2-3-4-1 plus chord 1-3.
      CSP.Edges (1) := (1, 2);
      CSP.Edges (2) := (2, 3);
      CSP.Edges (3) := (3, 4);
      CSP.Edges (4) := (4, 1);
      CSP.Edges (5) := (1, 3);
   end Build_Four_Region_Map;

   function Map_Variable_Conflicts
     (CSP : Map_CSP; Colors : Color_Assignment; R : Region_Index)
      return Natural
   is
      Count : Natural := 0;
      E     : Edge;
   begin
      for I in 1 .. CSP.Num_Edges loop
         E := CSP.Edges (I);
         if E.A = R and then Colors (E.B) = Colors (R) then
            Count := Count + 1;
         elsif E.B = R and then Colors (E.A) = Colors (R) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Map_Variable_Conflicts;

   function Map_Conflict_Count
     (CSP : Map_CSP; Colors : Color_Assignment) return Natural
   is
      Count : Natural := 0;
      E     : Edge;
   begin
      for I in 1 .. CSP.Num_Edges loop
         E := CSP.Edges (I);
         if Colors (E.A) = Colors (E.B) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Map_Conflict_Count;

   function Map_Is_Solved
     (CSP : Map_CSP; Colors : Color_Assignment) return Boolean
   is
   begin
      return Map_Conflict_Count (CSP, Colors) = 0;
   end Map_Is_Solved;

   function Map_Min_Conflict_Color
     (CSP    : Map_CSP;
      Colors : Color_Assignment;
      R      : Region_Index;
      State  : in out RNG_State) return Color_Index
   is
      Best_Color : Color_Index := 1;
      Best_Conf  : Natural := Natural'Last;
      Conf       : Natural;
      Tie_Count  : Natural := 0;
      Pick       : Natural;
      Trial      : Color_Assignment (Colors'Range) := Colors;
   begin
      for C in 1 .. CSP.Num_Colors loop
         Trial (R) := C;
         Conf := Map_Variable_Conflicts (CSP, Trial, R);
         if Conf < Best_Conf then
            Best_Conf  := Conf;
            Best_Color := C;
            Tie_Count  := 1;
         elsif Conf = Best_Conf then
            Tie_Count := Tie_Count + 1;
            Pick := Next_Natural (State, 1, Tie_Count);
            if Pick = Tie_Count then
               Best_Color := C;
            end if;
         end if;
      end loop;
      return Best_Color;
   end Map_Min_Conflict_Color;

   function Map_Pick_Conflicted
     (CSP    : Map_CSP;
      Colors : Color_Assignment;
      State  : in out RNG_State) return Natural
   is
      Count  : Natural := 0;
      Pick   : Natural;
      Chosen : Natural := 0;
   begin
      for R in 1 .. CSP.Num_Regions loop
         if Map_Variable_Conflicts (CSP, Colors, R) > 0 then
            Count := Count + 1;
            Pick := Next_Natural (State, 1, Count);
            if Pick = Count then
               Chosen := R;
            end if;
         end if;
      end loop;
      return Chosen;
   end Map_Pick_Conflicted;

   procedure Solve_Map_Coloring
     (CSP    : Map_CSP;
      Params : Parameters;
      Colors : out Color_Assignment;
      Result : out Solve_Result)
   is
      State   : RNG_State;
      Steps   : Natural;
      Attempt : Natural;
      Var     : Natural;
   begin
      if CSP.Num_Regions = 0 or else CSP.Num_Colors = 0 then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Params.Seed);
      Result :=
        (Solved          => False,
         Steps_Used      => 0,
         Restarts_Used   => 0,
         Final_Conflicts => 0);

      Attempt := 0;
      loop
         for R in 1 .. CSP.Num_Regions loop
            Colors (R) := Next_Natural (State, 1, CSP.Num_Colors);
         end loop;
         Steps := 0;

         if not Map_Is_Solved (CSP, Colors) then
            for I in 1 .. Params.Max_Steps loop
               Var := Map_Pick_Conflicted (CSP, Colors, State);
               if Var = 0 then
                  exit;
               end if;
               Colors (Var) :=
                 Map_Min_Conflict_Color (CSP, Colors, Var, State);
               Steps := Steps + 1;
               if Map_Is_Solved (CSP, Colors) then
                  exit;
               end if;
            end loop;
         end if;

         Result.Steps_Used := Result.Steps_Used + Steps;
         Result.Final_Conflicts := Map_Conflict_Count (CSP, Colors);

         if Result.Final_Conflicts = 0 then
            Result.Solved := True;
            Result.Restarts_Used := Attempt;
            return;
         end if;

         exit when Attempt >= Params.Restarts;
         Attempt := Attempt + 1;
         Result.Restarts_Used := Attempt;
      end loop;

      Result.Solved := False;
   end Solve_Map_Coloring;

end Min_Conflicts;
