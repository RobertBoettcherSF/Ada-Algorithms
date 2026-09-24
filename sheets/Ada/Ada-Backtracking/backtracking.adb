--  Backtracking — body: N-Queens, subset sum with pruning, graph colouring.

pragma Ada_2022;

package body Backtracking
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- N-Queens helpers
   ---------------------------------------------------------------------------

   --  True when placing a queen at (Row, Col) does not attack any queen
   --  already placed in rows 1 .. Row − 1 (Placement holds those columns).
   function Safe_To_Place
     (Placement : Queen_Array;
      Row       : Positive;
      Col       : Positive) return Boolean
   is
   begin
      for R in 1 .. Row - 1 loop
         declare
            C : constant Natural := Placement (R);
         begin
            if C = Col
              or else C + (Row - R) = Col
              or else C - (Row - R) = Col
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Safe_To_Place;

   function Attacks (C1, R1, C2, R2 : Integer) return Boolean is
     (C1 = C2
      or else R1 = R2
      or else abs (C1 - C2) = abs (R1 - R2));

   ---------------------------------------------------------------------------
   -- Solve_N_Queens
   ---------------------------------------------------------------------------

   function Solve_N_Queens
     (N         : Positive;
      Placement : out Queen_Array) return Boolean
   is
      Found : Boolean := False;

      procedure Search (Row : Positive) is
      begin
         if Found then
            return;
         end if;
         if Row > N then
            Found := True;
            return;
         end if;
         for Col in 1 .. N loop
            if Safe_To_Place (Placement, Row, Col) then
               Placement (Row) := Col;
               Search (Row + 1);
               if Found then
                  return;
               end if;
               Placement (Row) := 0;
            end if;
         end loop;
      end Search;

   begin
      if N > Max_N then
         raise Invalid_Argument with "N exceeds Max_N";
      end if;
      if Placement'First /= 1 or else Placement'Length /= N then
         raise Invalid_Argument with "Placement bounds must be 1 .. N";
      end if;

      Placement := [others => 0];
      Search (1);
      return Found;
   end Solve_N_Queens;

   ---------------------------------------------------------------------------
   -- Count_N_Queens
   ---------------------------------------------------------------------------

   function Count_N_Queens (N : Positive) return Natural is
      Placement : Queen_Array (1 .. N) := [others => 0];
      Total     : Natural := 0;

      procedure Search (Row : Positive) is
      begin
         if Row > N then
            Total := Total + 1;
            return;
         end if;
         for Col in 1 .. N loop
            if Safe_To_Place (Placement, Row, Col) then
               Placement (Row) := Col;
               Search (Row + 1);
               Placement (Row) := 0;
            end if;
         end loop;
      end Search;

   begin
      if N > Max_N then
         raise Invalid_Argument with "N exceeds Max_N";
      end if;
      Search (1);
      return Total;
   end Count_N_Queens;

   ---------------------------------------------------------------------------
   -- Is_Safe_Placement
   ---------------------------------------------------------------------------

   function Is_Safe_Placement
     (Placement : Queen_Array;
      N         : Positive) return Boolean
   is
      Seen : array (1 .. N) of Boolean := [others => False];
   begin
      if N > Max_N then
         raise Invalid_Argument with "N exceeds Max_N";
      end if;
      if Placement'First /= 1 or else Placement'Last < N then
         raise Invalid_Argument with "Placement bounds too small";
      end if;

      for R in 1 .. N loop
         declare
            C : constant Natural := Placement (R);
         begin
            if C < 1 or else C > N then
               return False;
            end if;
            if Seen (C) then
               return False;
            end if;
            Seen (C) := True;
         end;
      end loop;

      for R1 in 1 .. N - 1 loop
         for R2 in R1 + 1 .. N loop
            if Attacks
                 (Integer (Placement (R1)), R1,
                  Integer (Placement (R2)), R2)
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Safe_Placement;

   ---------------------------------------------------------------------------
   -- Subset sum (backtracking with pruning)
   ---------------------------------------------------------------------------

   function Subset_Sum
     (A      : Element_Array;
      Target : Integer;
      Chosen : out Boolean_Array) return Boolean
   is
      N     : constant Natural := A'Length;
      Found : Boolean := False;
      --  Working choice flags aligned to 1 .. N (A may not start at 1).
      Pick  : Boolean_Array (1 .. N) := [others => False];

      --  Map working index I (1 .. N) to A'First + I − 1.
      function Elem (I : Positive) return Integer is
        (A (A'First + I - 1));

      --  Sum of remaining elements from Index .. N that can still help:
      --  for a given Target residual, we prune with total remaining sum
      --  bounds. Precompute suffix sums of positives and of all values.
      Pos_Suffix : array (1 .. N + 1) of Integer := [others => 0];
      All_Suffix : array (1 .. N + 1) of Integer := [others => 0];
      Neg_Suffix : array (1 .. N + 1) of Integer := [others => 0];
      --  Pos_Suffix (I) = sum of max(0, At(J)) for J in I .. N
      --  Neg_Suffix (I) = sum of min(0, At(J)) for J in I .. N
      --  All_Suffix (I) = sum of At(J) for J in I .. N

      procedure Search (Index : Positive; Partial : Integer) is
         Need : Integer;
      begin
         if Found then
            return;
         end if;

         if Index > N then
            if Partial = Target then
               Found := True;
            end if;
            return;
         end if;

         Need := Target - Partial;

         --  reject: even taking every remaining positive (and avoiding
         --  every remaining negative) cannot reach Need; or taking every
         --  remaining negative (and avoiding positives) overshoots below.
         if Need > Pos_Suffix (Index) then
            return;
         end if;
         if Need < Neg_Suffix (Index) then
            return;
         end if;

         --  Extend: include Elem (Index).
         Pick (Index) := True;
         Search (Index + 1, Partial + Elem (Index));
         if Found then
            return;
         end if;
         Pick (Index) := False;

         --  Extend: exclude Elem (Index).
         Search (Index + 1, Partial);
      end Search;

   begin
      if N > Max_Subset_N then
         raise Invalid_Argument with "subset length exceeds Max_Subset_N";
      end if;
      if Chosen'Length /= N or else Chosen'First /= A'First then
         raise Invalid_Argument with "Chosen bounds must match A";
      end if;

      Chosen := [others => False];

      if N = 0 then
         return Target = 0;
      end if;

      for I in reverse 1 .. N loop
         declare
            V : constant Integer := Elem (I);
         begin
            All_Suffix (I) := All_Suffix (I + 1) + V;
            if V > 0 then
               Pos_Suffix (I) := Pos_Suffix (I + 1) + V;
               Neg_Suffix (I) := Neg_Suffix (I + 1);
            elsif V < 0 then
               Pos_Suffix (I) := Pos_Suffix (I + 1);
               Neg_Suffix (I) := Neg_Suffix (I + 1) + V;
            else
               Pos_Suffix (I) := Pos_Suffix (I + 1);
               Neg_Suffix (I) := Neg_Suffix (I + 1);
            end if;
         end;
      end loop;

      Search (1, 0);

      if Found then
         for I in 1 .. N loop
            Chosen (A'First + I - 1) := Pick (I);
         end loop;
      end if;
      return Found;
   end Subset_Sum;

   function Subset_Sum_Exists
     (A      : Element_Array;
      Target : Integer) return Boolean
   is
      Chosen : Boolean_Array (A'Range);
      Ok     : Boolean;
   begin
      if A'Length > Max_Subset_N then
         raise Invalid_Argument with "subset length exceeds Max_Subset_N";
      end if;
      Ok := Subset_Sum (A, Target, Chosen);
      pragma Unreferenced (Chosen);
      return Ok;
   end Subset_Sum_Exists;

   ---------------------------------------------------------------------------
   -- Graph colouring
   ---------------------------------------------------------------------------

   procedure Check_Graph_Bounds
     (Adj    : Adjacency_Matrix;
      Colors : Color_Array)
   is
      V : constant Natural := Colors'Length;
   begin
      if V = 0 then
         raise Invalid_Argument with "empty graph not supported";
      end if;
      if V > Max_Vertices then
         raise Invalid_Argument with "too many vertices";
      end if;
      if Adj'Length (1) /= V or else Adj'Length (2) /= V then
         raise Invalid_Argument with "Adj must be V×V matching Colors";
      end if;
      if Adj'First (1) /= Colors'First
        or else Adj'First (2) /= Colors'First
      then
         raise Invalid_Argument with "Adj/Colors first indices must match";
      end if;
      if Adj'Last (1) /= Colors'Last
        or else Adj'Last (2) /= Colors'Last
      then
         raise Invalid_Argument with "Adj/Colors last indices must match";
      end if;
   end Check_Graph_Bounds;

   function Colour_Ok
     (Adj    : Adjacency_Matrix;
      Colors : Color_Array;
      Vertex : Positive;
      Col    : Positive) return Boolean
   is
   begin
      for U in Colors'First .. Vertex - 1 loop
         if Adj (Vertex, U) and then Colors (U) = Col then
            return False;
         end if;
      end loop;
      return True;
   end Colour_Ok;

   function Color_Graph
     (Adj      : Adjacency_Matrix;
      K_Colors : Positive;
      Colors   : out Color_Array) return Boolean
   is
      Found : Boolean := False;
      First : constant Positive := Colors'First;
      Last  : constant Natural  := Colors'Last;

      procedure Search (Vertex : Positive) is
      begin
         if Found then
            return;
         end if;
         if Vertex > Last then
            Found := True;
            return;
         end if;
         for Col in 1 .. K_Colors loop
            if Colour_Ok (Adj, Colors, Vertex, Col) then
               Colors (Vertex) := Col;
               Search (Vertex + 1);
               if Found then
                  return;
               end if;
               Colors (Vertex) := 0;
            end if;
         end loop;
      end Search;

   begin
      if K_Colors > Max_Colors then
         raise Invalid_Argument with "K_Colors exceeds Max_Colors";
      end if;
      Check_Graph_Bounds (Adj, Colors);

      Colors := [others => 0];
      Search (First);
      return Found;
   end Color_Graph;

   function Is_Valid_Colouring
     (Adj    : Adjacency_Matrix;
      Colors : Color_Array;
      K      : Positive) return Boolean
   is
   begin
      if K > Max_Colors then
         raise Invalid_Argument with "K exceeds Max_Colors";
      end if;
      Check_Graph_Bounds (Adj, Colors);

      for V in Colors'Range loop
         if Colors (V) < 1 or else Colors (V) > K then
            return False;
         end if;
      end loop;

      for U in Colors'Range loop
         for V in Colors'Range loop
            if U /= V and then Adj (U, V) then
               if Colors (U) = Colors (V) then
                  return False;
               end if;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Colouring;

end Backtracking;
