--  Dancing_Links body — fixed-pool Knuth DLX / Algorithm X.

pragma Ada_2022;

package body Dancing_Links is

   -----------------------------------------------------------------------
   -- Internal helpers
   -----------------------------------------------------------------------

   procedure Init_Root (S : in out Solver) is
   begin
      S.Nodes (Root_Id) :=
        (L => Root_Id, R => Root_Id, U => Root_Id, D => Root_Id,
         Col => Root_Id, Size => 0, Row => 0);
      S.Last_Node := Root_Id;
      S.Num_Columns := 0;
      S.Num_Primary := 0;
      S.Num_Rows := 0;
   end Init_Root;

   procedure Link_Header_Horizontal
     (S : in out Solver;
      C : Node_Id)
   is
      Left : constant Node_Id := S.Nodes (Root_Id).L;
   begin
      S.Nodes (C).L := Left;
      S.Nodes (C).R := Root_Id;
      S.Nodes (Left).R := C;
      S.Nodes (Root_Id).L := C;
   end Link_Header_Horizontal;

   procedure Allocate_Column_Headers
     (S             : in out Solver;
      Num_Columns   : Column_Count;
      Primary_Count : Column_Count)
   is
      Prim : Column_Count;
   begin
      Init_Root (S);
      S.Num_Columns := Num_Columns;
      if Primary_Count = 0 then
         Prim := Num_Columns;
      else
         Prim := Primary_Count;
      end if;
      if Prim > Num_Columns then
         raise Invalid_Argument;
      end if;
      S.Num_Primary := Prim;

      for C in 1 .. Num_Columns loop
         S.Nodes (Node_Id (C)) :=
           (L => Node_Id (C), R => Node_Id (C),
            U => Node_Id (C), D => Node_Id (C),
            Col => Node_Id (C), Size => 0, Row => 0);
         if C <= Prim then
            Link_Header_Horizontal (S, Node_Id (C));
         end if;
      end loop;
      S.Last_Node := Node_Id (Num_Columns);
   end Allocate_Column_Headers;

   function Alloc_Data
     (S   : in out Solver;
      Col : Node_Id;
      Row : Row_Id) return Node_Id
   is
      N : Node_Id;
      Up : Node_Id;
   begin
      if S.Last_Node = Max_Nodes then
         raise Capacity_Exceeded;
      end if;
      S.Last_Node := S.Last_Node + 1;
      N := S.Last_Node;
      Up := S.Nodes (Col).U;
      S.Nodes (N) :=
        (L => N, R => N, U => Up, D => Col,
         Col => Col, Size => 0, Row => Row);
      S.Nodes (Up).D := N;
      S.Nodes (Col).U := N;
      S.Nodes (Col).Size := S.Nodes (Col).Size + 1;
      return N;
   end Alloc_Data;

   procedure Link_Row_Horizontal
     (S     : in out Solver;
      First : Node_Id;
      Next  : Node_Id)
   is
      Left : constant Node_Id := S.Nodes (First).L;
   begin
      S.Nodes (Next).L := Left;
      S.Nodes (Next).R := First;
      S.Nodes (Left).R := Next;
      S.Nodes (First).L := Next;
   end Link_Row_Horizontal;

   procedure Add_Matrix_Row
     (S      : in out Solver;
      Matrix : Bool_Matrix;
      R      : Positive)
   is
      First : Node_Id := 0;
      N     : Node_Id;
      Any   : Boolean := False;
   begin
      if S.Num_Rows = Max_Matrix_Rows then
         raise Capacity_Exceeded;
      end if;
      S.Num_Rows := S.Num_Rows + 1;
      for C in Matrix'Range (2) loop
         if Matrix (R, C) then
            if C > Natural (S.Num_Columns) then
               raise Invalid_Argument;
            end if;
            N := Alloc_Data (S, Node_Id (C), S.Num_Rows);
            if not Any then
               First := N;
               Any := True;
            else
               Link_Row_Horizontal (S, First, N);
            end if;
         end if;
      end loop;
      --  Empty rows are allowed (never selected); they simply add no nodes.
   end Add_Matrix_Row;

   -----------------------------------------------------------------------
   -- Clear / builders
   -----------------------------------------------------------------------

   procedure Clear (S : out Solver) is
   begin
      S := (others => <>);
      Init_Root (S);
   end Clear;

   procedure Build_From_Matrix
     (S             : out Solver;
      Matrix        : Bool_Matrix;
      Primary_Count : Column_Count := 0)
   is
      Cols : Column_Count;
   begin
      if Matrix'Length (1) = 0 and then Matrix'Length (2) = 0 then
         Clear (S);
         return;
      end if;
      if Matrix'Length (2) > Max_Columns then
         raise Capacity_Exceeded;
      end if;
      if Matrix'Length (1) > Max_Matrix_Rows then
         raise Capacity_Exceeded;
      end if;
      if Matrix'First (2) /= 1 then
         raise Invalid_Argument;
      end if;
      Cols := Column_Count (Matrix'Length (2));
      Allocate_Column_Headers (S, Cols, Primary_Count);
      for R in Matrix'Range (1) loop
         Add_Matrix_Row (S, Matrix, R);
      end loop;
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

   function Header_Size (S : Solver; C : Node_Id) return Natural is
   begin
      if C = Root_Id or else C > Node_Id (S.Num_Columns) then
         raise Invalid_Argument;
      end if;
      return S.Nodes (C).Size;
   end Header_Size;

   function Primary_Header_Count (S : Solver) return Natural is
      C     : Node_Id := S.Nodes (Root_Id).R;
      Count : Natural := 0;
   begin
      while C /= Root_Id loop
         Count := Count + 1;
         C := S.Nodes (C).R;
         if Count > Max_Columns then
            return Count;
         end if;
      end loop;
      return Count;
   end Primary_Header_Count;

   function Min_Primary_Size (S : Solver) return Natural is
      C    : Node_Id := S.Nodes (Root_Id).R;
      Best : Natural := Natural'Last;
      Seen : Boolean := False;
   begin
      while C /= Root_Id loop
         Seen := True;
         if S.Nodes (C).Size < Best then
            Best := S.Nodes (C).Size;
         end if;
         C := S.Nodes (C).R;
      end loop;
      if not Seen then
         return 0;
      end if;
      return Best;
   end Min_Primary_Size;

   function Structure_Fingerprint (S : Solver) return Natural is
      type Mod32 is mod 2 ** 32;
      Acc : Mod32 := 0;
      procedure Mix (V : Natural) is
      begin
         Acc := Acc + Mod32 (V);
         Acc := Acc * 131 + 17;
      end Mix;
   begin
      Mix (Natural (S.Num_Columns));
      Mix (Natural (S.Num_Primary));
      Mix (Natural (S.Last_Node));
      Mix (Natural (S.Num_Rows));
      for I in Root_Id .. S.Last_Node loop
         Mix (Natural (S.Nodes (I).L));
         Mix (Natural (S.Nodes (I).R));
         Mix (Natural (S.Nodes (I).U));
         Mix (Natural (S.Nodes (I).D));
         Mix (Natural (S.Nodes (I).Col));
         Mix (S.Nodes (I).Size);
         Mix (Natural (S.Nodes (I).Row));
      end loop;
      return Natural (Acc mod Mod32 (Natural'Last));
   end Structure_Fingerprint;

   -----------------------------------------------------------------------
   -- Cover / Uncover / Choose
   -----------------------------------------------------------------------

   function Choose_Column (S : Solver) return Node_Id is
      C     : Node_Id := S.Nodes (Root_Id).R;
      Best  : Node_Id := Root_Id;
      BestS : Natural := Natural'Last;
   begin
      while C /= Root_Id loop
         if S.Nodes (C).Size < BestS then
            BestS := S.Nodes (C).Size;
            Best := C;
            exit when BestS = 0;
         end if;
         C := S.Nodes (C).R;
      end loop;
      return Best;
   end Choose_Column;

   procedure Cover (S : in out Solver; C : Node_Id) is
      I, J : Node_Id;
   begin
      --  Unlink column header from primary header list (secondary headers
      --  are never in that list; Cover still walks their vertical list).
      S.Nodes (S.Nodes (C).L).R := S.Nodes (C).R;
      S.Nodes (S.Nodes (C).R).L := S.Nodes (C).L;

      I := S.Nodes (C).D;
      while I /= C loop
         J := S.Nodes (I).R;
         while J /= I loop
            S.Nodes (S.Nodes (J).U).D := S.Nodes (J).D;
            S.Nodes (S.Nodes (J).D).U := S.Nodes (J).U;
            S.Nodes (S.Nodes (J).Col).Size :=
              S.Nodes (S.Nodes (J).Col).Size - 1;
            J := S.Nodes (J).R;
         end loop;
         I := S.Nodes (I).D;
      end loop;
   end Cover;

   procedure Uncover (S : in out Solver; C : Node_Id) is
      I, J : Node_Id;
   begin
      I := S.Nodes (C).U;
      while I /= C loop
         J := S.Nodes (I).L;
         while J /= I loop
            S.Nodes (S.Nodes (J).Col).Size :=
              S.Nodes (S.Nodes (J).Col).Size + 1;
            S.Nodes (S.Nodes (J).U).D := J;
            S.Nodes (S.Nodes (J).D).U := J;
            J := S.Nodes (J).L;
         end loop;
         I := S.Nodes (I).U;
      end loop;

      S.Nodes (S.Nodes (C).L).R := C;
      S.Nodes (S.Nodes (C).R).L := C;
   end Uncover;

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
      C, R, J : Node_Id;
      Sol     : Solution;
   begin
      if Stop then
         return;
      end if;

      if S.Nodes (Root_Id).R = Root_Id then
         --  All primary columns covered → solution.
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
      if C = Root_Id then
         return;
      end if;

      Cover (S, C);

      R := S.Nodes (C).D;
      while R /= C loop
         if Partial_S.Length >= Max_Solution_Length then
            raise Capacity_Exceeded;
         end if;
         Partial_S.Length := Partial_S.Length + 1;
         Partial_S.Rows (Partial_S.Length) := S.Nodes (R).Row;

         J := S.Nodes (R).R;
         while J /= R loop
            Cover (S, S.Nodes (J).Col);
            J := S.Nodes (J).R;
         end loop;

         Search (S, Partial_S, Solutions, Count, Cap, Stop, Store);

         J := S.Nodes (R).L;
         while J /= R loop
            Uncover (S, S.Nodes (J).Col);
            J := S.Nodes (J).L;
         end loop;

         Partial_S.Length := Partial_S.Length - 1;

         exit when Stop;
         R := S.Nodes (R).D;
      end loop;

      Uncover (S, C);
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
      --  2N primary + 2*(2N-1) secondary = 6N - 2
      return Column_Count (6 * Natural (N) - 2);
   end N_Queens_Column_Count;

   procedure Build_N_Queens
     (S : out Solver;
      N : Queens_N)
   is
      --  Columns:
      --    1 .. N              : rows (primary)
      --    N+1 .. 2N           : cols (primary)
      --    2N+1 .. 4N-1        : diag r-c+N-1  (secondary), 2N-1 of them
      --    4N .. 6N-2          : diag r+c      (secondary), 2N-1 of them
      Cols    : constant Column_Count := N_Queens_Column_Count (N);
      Prim    : constant Column_Count := Column_Count (2 * Natural (N));
      Rows    : constant Positive := Natural (N) * Natural (N);
      Matrix  : Bool_Matrix (1 .. Rows, 1 .. Positive (Cols)) :=
        [others => [others => False]];
      Idx     : Positive;
      D1, D2  : Positive;
   begin
      for R in 1 .. Natural (N) loop
         for C in 1 .. Natural (N) loop
            Idx := (R - 1) * Natural (N) + C;
            Matrix (Idx, R) := True;                         -- row
            Matrix (Idx, Natural (N) + C) := True;           -- col
            D1 := R - C + Natural (N);                       -- 1 .. 2N-1
            D2 := R + C - 1;                                 -- 1 .. 2N-1
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
   -- Knuth textbook example
   -----------------------------------------------------------------------

   procedure Build_Knuth_Example (S : out Solver) is
      --  Columns A..G; rows as in Knuth / Wikipedia dancing-links article.
      M : constant Bool_Matrix (1 .. 6, 1 .. 7) :=
        [[False, False, True,  False, True,  True,  False],  -- 0: C E F
         [True,  False, False, True,  False, False, True],   -- 1: A D G
         [False, True,  True,  False, False, True,  False],  -- 2: B C F
         [True,  False, False, True,  False, False, False],  -- 3: A D
         [False, True,  False, False, False, False, True],   -- 4: B G
         [False, False, False, True,  True,  False, True]];  -- 5: D E G
   begin
      Build_From_Matrix (S, M, 0);
   end Build_Knuth_Example;

   function Knuth_Example_Solution_Count return Natural is
      S : Solver;
   begin
      Build_Knuth_Example (S);
      return Count_Solutions (S, Max_Solutions);
   end Knuth_Example_Solution_Count;

end Dancing_Links;
