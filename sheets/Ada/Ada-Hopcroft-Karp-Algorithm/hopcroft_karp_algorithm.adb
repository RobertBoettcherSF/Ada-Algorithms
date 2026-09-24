--  Hopcroft_Karp_Algorithm body — BFS layers + multi-DFS phases;
--  optional DFS-only Ford–Fulkerson matching oracle.

pragma Ada_2022;

package body Hopcroft_Karp_Algorithm
  with SPARK_Mode => Off
is

   Inf_Dist : constant Natural := Natural'Last / 4;

   type Dist_Array is array (Left_Id) of Natural;
   type Pair_U_Store is array (Left_Id) of Natural;
   type Pair_V_Store is array (Right_Id) of Natural;
   type Queue_Store is array (0 .. Max_Left) of Natural;
   type Visit_Array is array (Right_Id) of Boolean;

   ---------------------------------------------------------------------------
   -- Graph mutators / inspectors
   ---------------------------------------------------------------------------

   procedure Clear
     (G : in out Graph; Left_Count, Right_Count : Natural)
   is
   begin
      if Left_Count > Max_Left or else Right_Count > Max_Right then
         raise Invalid_Argument;
      end if;
      G.L := Left_Count;
      G.R := Right_Count;
      G.M := 0;
      for U in Left_Id loop
         G.Head (U) := 0;
      end loop;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; Left : Left_Id; Right : Right_Id)
   is
      E : Edge_Index;
   begin
      if Natural (Left) > G.L or else Natural (Right) > G.R then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      E := G.M;
      G.From (E) := Left;
      G.To (E) := Right;
      G.Next (E) := G.Head (Left);
      G.Head (Left) := E;
   end Add_Edge;

   function Left_Count (G : Graph) return Natural is
   begin
      return G.L;
   end Left_Count;

   function Right_Count (G : Graph) return Natural is
   begin
      return G.R;
   end Right_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return G.M;
   end Edge_Count;

   procedure Validate_Edge_Index (G : Graph; Index : Positive) is
   begin
      if Index > G.M then
         raise Invalid_Argument;
      end if;
   end Validate_Edge_Index;

   function Edge_Left (G : Graph; Index : Positive) return Left_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.From (Index);
   end Edge_Left;

   function Edge_Right (G : Graph; Index : Positive) return Right_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.To (Index);
   end Edge_Right;

   ---------------------------------------------------------------------------
   -- Edge existence (for Is_Valid_Matching)
   ---------------------------------------------------------------------------

   function Has_Edge
     (G : Graph; Left : Left_Id; Right : Right_Id) return Boolean
   is
      E : Natural := G.Head (Left);
   begin
      while E /= 0 loop
         if G.To (E) = Right then
            return True;
         end if;
         E := G.Next (E);
      end loop;
      return False;
   end Has_Edge;

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean
   is
      Count : Natural := 0;
   begin
      if Result.Left_N /= G.L or else Result.Right_N /= G.R then
         return False;
      end if;
      if G.L = 0 or else G.R = 0 then
         return Result.Size = 0;
      end if;

      for U in 1 .. G.L loop
         declare
            V : constant Natural := Result.Pair_U (U);
         begin
            if V = 0 then
               null;
            elsif V > G.R then
               return False;
            elsif Result.Pair_V (V) /= U then
               return False;
            elsif not Has_Edge (G, Left_Id (U), Right_Id (V)) then
               return False;
            else
               Count := Count + 1;
            end if;
         end;
      end loop;

      for V in 1 .. G.R loop
         declare
            U : constant Natural := Result.Pair_V (V);
         begin
            if U = 0 then
               null;
            elsif U > G.L then
               return False;
            elsif Result.Pair_U (U) /= V then
               return False;
            end if;
         end;
      end loop;

      return Count = Result.Size;
   end Is_Valid_Matching;

   ---------------------------------------------------------------------------
   -- Shared pair init / result fill
   ---------------------------------------------------------------------------

   procedure Init_Pairs
     (Pair_U : out Pair_U_Store; Pair_V : out Pair_V_Store)
   is
   begin
      Pair_U := [others => 0];
      Pair_V := [others => 0];
   end Init_Pairs;

   procedure Fill_Result
     (L, R     : Natural;
      Matching : Natural;
      Pair_U   : Pair_U_Store;
      Pair_V   : Pair_V_Store;
      Result   : out Matching_Result)
   is
   begin
      Result.Size := Matching;
      Result.Left_N := L;
      Result.Right_N := R;
      Result.Pair_U := [others => 0];
      Result.Pair_V := [others => 0];
      for U in 1 .. L loop
         Result.Pair_U (U) := Pair_U (Left_Id (U));
      end loop;
      for V in 1 .. R loop
         Result.Pair_V (V) := Pair_V (Right_Id (V));
      end loop;
   end Fill_Result;

   ---------------------------------------------------------------------------
   -- Hopcroft–Karp: BFS layers + multi-DFS
   ---------------------------------------------------------------------------

   function Layer_BFS
     (G        : Graph;
      Pair_U   : Pair_U_Store;
      Pair_V   : Pair_V_Store;
      Dist     : in out Dist_Array;
      Dist_Nil : in out Natural) return Boolean
   is
      Q              : Queue_Store;
      Q_Head, Q_Tail : Natural := 0;
      U, Mate        : Natural;
      E              : Natural;
   begin
      Dist_Nil := Inf_Dist;
      for Idx in 1 .. G.L loop
         if Pair_U (Left_Id (Idx)) = 0 then
            Dist (Left_Id (Idx)) := 0;
            Q (Q_Tail) := Idx;
            Q_Tail := Q_Tail + 1;
         else
            Dist (Left_Id (Idx)) := Inf_Dist;
         end if;
      end loop;

      while Q_Head < Q_Tail loop
         U := Q (Q_Head);
         Q_Head := Q_Head + 1;
         if Dist (Left_Id (U)) < Dist_Nil then
            E := G.Head (Left_Id (U));
            while E /= 0 loop
               Mate := Pair_V (G.To (E));
               if Mate = 0 then
                  if Dist_Nil = Inf_Dist then
                     Dist_Nil := Dist (Left_Id (U)) + 1;
                  end if;
               elsif Dist (Left_Id (Mate)) = Inf_Dist then
                  Dist (Left_Id (Mate)) := Dist (Left_Id (U)) + 1;
                  Q (Q_Tail) := Mate;
                  Q_Tail := Q_Tail + 1;
               end if;
               E := G.Next (E);
            end loop;
         end if;
      end loop;

      return Dist_Nil /= Inf_Dist;
   end Layer_BFS;

   function Augment_DFS
     (G        : Graph;
      U        : Natural;
      Pair_U   : in out Pair_U_Store;
      Pair_V   : in out Pair_V_Store;
      Dist     : in out Dist_Array;
      Dist_Nil : Natural) return Boolean
   is
      E         : Natural;
      V, Mate   : Natural;
      Need      : Natural;
   begin
      if U = 0 then
         return True;
      end if;

      E := G.Head (Left_Id (U));
      while E /= 0 loop
         V := Natural (G.To (E));
         Mate := Pair_V (Right_Id (V));
         if Mate = 0 then
            Need := Dist_Nil;
         else
            Need := Dist (Left_Id (Mate));
         end if;
         if Need = Dist (Left_Id (U)) + 1 then
            if Augment_DFS (G, Mate, Pair_U, Pair_V, Dist, Dist_Nil) then
               Pair_V (Right_Id (V)) := U;
               Pair_U (Left_Id (U)) := V;
               return True;
            end if;
         end if;
         E := G.Next (E);
      end loop;

      Dist (Left_Id (U)) := Inf_Dist;
      return False;
   end Augment_DFS;

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result) is
      Pair_U   : Pair_U_Store;
      Pair_V   : Pair_V_Store;
      Dist     : Dist_Array;
      Dist_Nil : Natural := Inf_Dist;
      Matching : Natural := 0;
      Zero_U   : constant Pair_U_Store := [others => 0];
      Zero_V   : constant Pair_V_Store := [others => 0];
   begin
      if G.L = 0 or else G.R = 0 then
         Fill_Result (G.L, G.R, 0, Zero_U, Zero_V, Result);
         return;
      end if;

      Init_Pairs (Pair_U, Pair_V);

      while Layer_BFS (G, Pair_U, Pair_V, Dist, Dist_Nil) loop
         for U in 1 .. G.L loop
            if Pair_U (Left_Id (U)) = 0 then
               if Augment_DFS
                    (G, U, Pair_U, Pair_V, Dist, Dist_Nil)
               then
                  Matching := Matching + 1;
               end if;
            end if;
         end loop;
      end loop;

      Fill_Result (G.L, G.R, Matching, Pair_U, Pair_V, Result);
   end Maximum_Matching;

   ---------------------------------------------------------------------------
   -- Matching_Oracle_DFS (Kuhn / Ford–Fulkerson single-path DFS)
   ---------------------------------------------------------------------------

   --  Kuhn / Ford–Fulkerson style: search updates Pair_V only; Pair_U is
   --  rebuilt at the end. One DFS attempt per left vertex.
   function Oracle_DFS
     (G       : Graph;
      U       : Natural;
      Pair_V  : in out Pair_V_Store;
      Visited : in out Visit_Array) return Boolean
   is
      E       : Natural;
      V, Mate : Natural;
   begin
      E := G.Head (Left_Id (U));
      while E /= 0 loop
         V := Natural (G.To (E));
         if not Visited (Right_Id (V)) then
            Visited (Right_Id (V)) := True;
            Mate := Pair_V (Right_Id (V));
            if Mate = 0
              or else Oracle_DFS (G, Mate, Pair_V, Visited)
            then
               Pair_V (Right_Id (V)) := U;
               return True;
            end if;
         end if;
         E := G.Next (E);
      end loop;
      return False;
   end Oracle_DFS;

   procedure Matching_Oracle_DFS (G : Graph; Result : out Matching_Result) is
      Pair_U   : Pair_U_Store;
      Pair_V   : Pair_V_Store;
      Visited  : Visit_Array;
      Matching : Natural := 0;
      Zero_U   : constant Pair_U_Store := [others => 0];
      Zero_V   : constant Pair_V_Store := [others => 0];
   begin
      if G.L > Max_Oracle_Side or else G.R > Max_Oracle_Side then
         raise Invalid_Argument;
      end if;

      if G.L = 0 or else G.R = 0 then
         Fill_Result (G.L, G.R, 0, Zero_U, Zero_V, Result);
         return;
      end if;

      Init_Pairs (Pair_U, Pair_V);

      for U in 1 .. G.L loop
         Visited := [others => False];
         if Oracle_DFS (G, U, Pair_V, Visited) then
            null;  -- matching grows on the right; counted below
         end if;
      end loop;

      Matching := 0;
      Pair_U := [others => 0];
      for V in 1 .. G.R loop
         declare
            U : constant Natural := Pair_V (Right_Id (V));
         begin
            if U /= 0 then
               Pair_U (Left_Id (U)) := V;
               Matching := Matching + 1;
            end if;
         end;
      end loop;

      Fill_Result (G.L, G.R, Matching, Pair_U, Pair_V, Result);
   end Matching_Oracle_DFS;

end Hopcroft_Karp_Algorithm;
