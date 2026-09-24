--  Johnsons_Algorithm body — Bellman–Ford potentials + dense Dijkstra APSP.

pragma Ada_2022;

package body Johnsons_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.E := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
   is
   begin
      if Weight < Integer (Weight_Type'First)
        or else Weight > Integer (Weight_Type'Last)
      then
         raise Invalid_Argument;
      end if;
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.E = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.E := G.E + 1;
      G.To (G.E) := To;
      G.Weight (G.E) := Weight_Type (Weight);
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.E);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Shared validation
   -------------------------------------------------------------------------

   procedure Validate_N (N : Natural) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
   end Validate_N;

   procedure Validate_Dist_Bounds
     (N : Natural;
      D1_First, D1_Last, D2_First, D2_Last : Vertex_Id)
   is
   begin
      Validate_N (N);
      if D1_First /= 1
        or else D2_First /= 1
        or else Natural (D1_Last) < N
        or else Natural (D2_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Dist_Bounds;

   procedure Validate_Prev_Bounds
     (N : Natural;
      P1_First, P1_Last, P2_First, P2_Last : Vertex_Id)
   is
   begin
      if P1_First /= 1
        or else P2_First /= 1
        or else Natural (P1_Last) < N
        or else Natural (P2_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Prev_Bounds;

   -------------------------------------------------------------------------
   -- Safe arithmetic helpers
   -------------------------------------------------------------------------

   function Safe_Add
     (A, B : Distance_Value) return Distance_Value
   is
   begin
      if A = Infinity or else B = Infinity then
         return Infinity;
      end if;
      if B > 0 and then A > Infinity - B then
         return Infinity;
      end if;
      if B < 0 and then A < Distance_Value'First - B then
         return Distance_Value'First;
      end if;
      return A + B;
   end Safe_Add;

   function Safe_Sub
     (A, B : Distance_Value) return Distance_Value
   is
   begin
      if A = Infinity then
         return Infinity;
      end if;
      if B > 0 and then A < Distance_Value'First + B then
         return Distance_Value'First;
      end if;
      if B < 0 and then A > Infinity + B then
         return Infinity;
      end if;
      return A - B;
   end Safe_Sub;

   -------------------------------------------------------------------------
   -- Bellman–Ford potentials from virtual super-source
   -------------------------------------------------------------------------

   function Compute_Potentials
     (G : Graph; H : out Distance_Array) return Boolean
   is
      N       : constant Natural := G.N;
      E_Idx   : Natural;
      V       : Vertex_Id;
      W       : Weight_Type;
      Cand    : Distance_Value;
      Changed : Boolean;
   begin
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         H (I) := 0;
      end loop;

      if N >= 2 then
         for Pass in 1 .. N - 1 loop
            Changed := False;
            for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
               E_Idx := G.Head (U_Id);
               while E_Idx /= 0 loop
                  V := G.To (E_Idx);
                  W := G.Weight (E_Idx);
                  Cand := Safe_Add (H (U_Id), Distance_Value (W));
                  if Cand < H (V) then
                     H (V) := Cand;
                     Changed := True;
                  end if;
                  E_Idx := G.Next (E_Idx);
               end loop;
            end loop;
            exit when not Changed;
         end loop;
      end if;

      --  Extra pass: any further improvement ⇒ negative cycle.
      for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
         E_Idx := G.Head (U_Id);
         while E_Idx /= 0 loop
            V := G.To (E_Idx);
            W := G.Weight (E_Idx);
            Cand := Safe_Add (H (U_Id), Distance_Value (W));
            if Cand < H (V) then
               return True;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      return False;
   end Compute_Potentials;

   -------------------------------------------------------------------------
   -- Dense Dijkstra on reweighted edges w' = w + h(u) − h(v)
   -------------------------------------------------------------------------

   procedure Dense_Dijkstra_Reweighted
     (G      : Graph;
      Source : Vertex_Id;
      H      : Distance_Array;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      N       : constant Natural := G.N;
      Settled : array (1 .. Max_Vertices) of Boolean := [others => False];
      E_Idx   : Natural;
      W_Vert  : Vertex_Id;
      W_Raw   : Weight_Type;
      W_Prime : Distance_Value;
      Alt     : Distance_Value;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
         Settled (Natural (V)) := False;
      end loop;
      Dist (Source) := 0;

      for Step in 1 .. N loop
         declare
            U     : Vertex_Id := Source;
            Best  : Distance_Value := Infinity;
            Found : Boolean := False;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               if not Settled (Natural (V)) and then Dist (V) < Best then
                  Best := Dist (V);
                  U := V;
                  Found := True;
               elsif not Settled (Natural (V))
                 and then Dist (V) = Best
                 and then not Found
               then
                  U := V;
                  Found := True;
               end if;
            end loop;

            if not Found or else Best = Infinity then
               exit;
            end if;

            Settled (Natural (U)) := True;

            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W_Vert := G.To (E_Idx);
               if not Settled (Natural (W_Vert)) then
                  W_Raw := G.Weight (E_Idx);
                  --  w' = w + h(u) − h(v) ≥ 0 when no negative cycle.
                  W_Prime := Safe_Sub
                    (Safe_Add (Distance_Value (W_Raw), H (U)),
                     H (W_Vert));
                  if W_Prime < 0 then
                     W_Prime := 0;
                  end if;
                  Alt := Safe_Add (Dist (U), W_Prime);
                  if Alt < Dist (W_Vert) then
                     Dist (W_Vert) := Alt;
                     Prev (W_Vert) := Natural (U);
                  end if;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end;
      end loop;
   end Dense_Dijkstra_Reweighted;

   -------------------------------------------------------------------------
   -- Fill Dist (and optionally Prev) after potentials are known
   -------------------------------------------------------------------------

   procedure Fill_From_Potentials
     (G         : Graph;
      H         : Distance_Array;
      Dist      : out Dist_Matrix;
      Fill_Prev : Boolean;
      Prev      : out Prev_Matrix)
   is
      N         : constant Natural := G.N;
      Row_Dist  : Distance_Array (1 .. Vertex_Id (N));
      Row_Prev  : Prev_Array (1 .. Vertex_Id (N));
      Recovered : Distance_Value;
   begin
      for S in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dense_Dijkstra_Reweighted (G, S, H, Row_Dist, Row_Prev);
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            if Row_Dist (V) = Infinity then
               Dist (S, V) := Infinity;
            else
               --  d(s,v) = d'(s,v) + h(v) − h(s)
               Recovered := Safe_Sub
                 (Safe_Add (Row_Dist (V), H (V)), H (S));
               Dist (S, V) := Recovered;
            end if;
            if Fill_Prev then
               Prev (S, V) := Row_Prev (V);
            else
               null;
            end if;
         end loop;
      end loop;
      if not Fill_Prev then
         --  Satisfy out-mode: write a single cell of the dummy Prev.
         if Prev'Length (1) > 0 and then Prev'Length (2) > 0 then
            Prev (Prev'First (1), Prev'First (2)) := 0;
         end if;
      end if;
   end Fill_From_Potentials;

   -------------------------------------------------------------------------
   -- Public All_Pairs / Johnson overloads
   -------------------------------------------------------------------------

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
      N   : constant Natural := G.N;
      H   : Distance_Array (Vertex_Id);
      Neg : Boolean;
   begin
      Validate_Dist_Bounds
        (N,
         Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      Validate_Prev_Bounds
        (N,
         Prev'First (1), Prev'Last (1), Prev'First (2), Prev'Last (2));

      Neg := Compute_Potentials (G, H (1 .. Vertex_Id (N)));
      if Neg then
         --  Out-mode must be written; zero a sentinel cell.
         Prev (Prev'First (1), Prev'First (2)) := 0;
         Dist (Dist'First (1), Dist'First (2)) := Infinity;
         Status := Negative_Cycle;
         return;
      end if;

      Fill_From_Potentials (G, H (1 .. Vertex_Id (N)), Dist, True, Prev);
      Status := Success;
   end All_Pairs;

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
   is
      N     : constant Natural := G.N;
      H     : Distance_Array (Vertex_Id);
      Dummy : Prev_Matrix (1 .. 1, 1 .. 1);
      Neg   : Boolean;
   begin
      Validate_Dist_Bounds
        (N,
         Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));

      Neg := Compute_Potentials (G, H (1 .. Vertex_Id (N)));
      if Neg then
         Dist (Dist'First (1), Dist'First (2)) := Infinity;
         Status := Negative_Cycle;
         return;
      end if;

      Fill_From_Potentials (G, H (1 .. Vertex_Id (N)), Dist, False, Dummy);
      Status := Success;
   end All_Pairs;

   procedure Johnson
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
   begin
      All_Pairs (G, Dist, Prev, Status);
   end Johnson;

   procedure Johnson
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
   is
   begin
      All_Pairs (G, Dist, Status);
   end Johnson;

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
   is
      Status : Run_Status;
   begin
      All_Pairs (G, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end All_Pairs;

   procedure Johnson
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
   is
   begin
      All_Pairs (G, Dist, Prev);
   end Johnson;

   function Has_Negative_Cycle (G : Graph) return Boolean is
      H : Distance_Array (Vertex_Id);
   begin
      Validate_N (G.N);
      return Compute_Potentials (G, H (1 .. Vertex_Id (G.N)));
   end Has_Negative_Cycle;

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N        : constant Natural := G.N;
      H        : Distance_Array (Vertex_Id);
      Row_Dist : Distance_Array (Vertex_Id);
      Row_Prev : Prev_Array (Vertex_Id);
      Neg      : Boolean;
   begin
      Validate_N (N);
      if Natural (Source) > N or else Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Neg := Compute_Potentials (G, H (1 .. Vertex_Id (N)));
      if Neg then
         raise Negative_Cycle_Error;
      end if;
      Dense_Dijkstra_Reweighted
        (G, Source, H (1 .. Vertex_Id (N)),
         Row_Dist (1 .. Vertex_Id (N)),
         Row_Prev (1 .. Vertex_Id (N)));
      if Row_Dist (Target) = Infinity then
         return Infinity;
      end if;
      return Safe_Sub
        (Safe_Add (Row_Dist (Target), H (Target)), H (Source));
   end Distance;

   -------------------------------------------------------------------------
   -- Path reconstruction
   -------------------------------------------------------------------------

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Stack     : array (1 .. Max_Vertices + 1) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top : Natural := 0;
      U         : Natural;
      Guard     : Natural := 0;
   begin
      Length := 0;

      if Source not in Prev'Range or else Target not in Prev'Range then
         raise Invalid_Argument;
      end if;
      if Path'First /= 1
        or else Natural (Path'Last) < Natural (Prev'Last)
      then
         raise Invalid_Argument;
      end if;

      if Source = Target then
         if Prev (Source) /= 0 then
            return False;
         end if;
         Path (1) := Source;
         Length := 1;
         return True;
      end if;

      U := Natural (Target);
      while U /= 0 loop
         Guard := Guard + 1;
         if Guard > Max_Vertices + 1 then
            Length := 0;
            return False;
         end if;
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := Vertex_Id (U);
         if Vertex_Id (U) = Source then
            exit;
         end if;
         if U not in Natural (Prev'First) .. Natural (Prev'Last) then
            Length := 0;
            return False;
         end if;
         U := Prev (Vertex_Id (U));
      end loop;

      if Stack_Top = 0 or else Stack (Stack_Top) /= Source then
         Length := 0;
         return False;
      end if;

      Length := Stack_Top;
      for I in 1 .. Stack_Top loop
         Path (I) := Stack (Stack_Top - I + 1);
      end loop;
      return True;
   end Reconstruct_Path;

   function Reconstruct_Path
     (Prev   : Prev_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Row : Prev_Array (Prev'Range (2));
   begin
      if Source not in Prev'Range (1)
        or else Target not in Prev'Range (2)
      then
         raise Invalid_Argument;
      end if;
      for V in Prev'Range (2) loop
         Row (V) := Prev (Source, V);
      end loop;
      return Reconstruct_Path (Row, Source, Target, Path, Length);
   end Reconstruct_Path;

end Johnsons_Algorithm;
