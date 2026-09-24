--  Floyd_Warshall_Algorithm body — dense O(N³) all-pairs shortest paths
--  with optional Next/Prev path reconstruction and negative-cycle probe.

pragma Ada_2022;

package body Floyd_Warshall_Algorithm
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
      for I in Vertex_Id loop
         for J in Vertex_Id loop
            G.Weight (I, J) := Infinity;
            G.Present (I, J) := False;
         end loop;
      end loop;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
   is
      W : Distance_Value;
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
      W := Distance_Value (Weight);
      if not G.Present (From, To) then
         if G.E = Max_Edges then
            raise Invalid_Argument;
         end if;
         G.Present (From, To) := True;
         G.Weight (From, To) := W;
         G.E := G.E + 1;
      elsif W < G.Weight (From, To) then
         G.Weight (From, To) := W;
      end if;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return G.E;
   end Edge_Count;

   function Has_Edge (G : Graph; From, To : Vertex_Id) return Boolean is
   begin
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      return G.Present (From, To);
   end Has_Edge;

   function Edge_Weight
     (G : Graph; From, To : Vertex_Id) return Distance_Value
   is
   begin
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.Present (From, To) then
         return G.Weight (From, To);
      end if;
      return Infinity;
   end Edge_Weight;

   -------------------------------------------------------------------------
   -- Shared validation
   -------------------------------------------------------------------------

   procedure Validate_N (N : Natural) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
   end Validate_N;

   procedure Validate_Square
     (N : Natural;
      R1_First, R1_Last, R2_First, R2_Last : Vertex_Id)
   is
   begin
      Validate_N (N);
      if R1_First /= 1
        or else R2_First /= 1
        or else Natural (R1_Last) < N
        or else Natural (R2_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Square;

   -------------------------------------------------------------------------
   -- Safe distance arithmetic (Infinity absorbs; avoid overflow)
   -------------------------------------------------------------------------

   function Safe_Add (A, B : Distance_Value) return Distance_Value is
   begin
      if A = Infinity or else B = Infinity then
         return Infinity;
      end if;
      --  Guard against overflow when both are large-magnitude.
      if A > 0 and then B > Infinity - A then
         return Infinity;
      end if;
      if A < 0 and then B < Distance_Value'First - A then
         --  Underflow toward very negative — clamp to First for safety;
         --  negative-cycle checks still see Dist(v,v) < 0.
         return Distance_Value'First;
      end if;
      return A + B;
   end Safe_Add;

   function Min_Dist (A, B : Distance_Value) return Distance_Value is
   begin
      if A <= B then
         return A;
      end if;
      return B;
   end Min_Dist;

   -------------------------------------------------------------------------
   -- Dist / Next / Prev initialisation
   -------------------------------------------------------------------------

   procedure Init_Dist (Dist : out Dist_Matrix; N : Natural) is
   begin
      Validate_Square
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      --  Write every component (Dist is `out`); algorithm uses 1 .. N.
      for I in Dist'Range (1) loop
         for J in Dist'Range (2) loop
            Dist (I, J) := Infinity;
         end loop;
      end loop;
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (I, I) := 0;
      end loop;
   end Init_Dist;

   procedure Put_Edge
     (Dist : in out Dist_Matrix; From, To : Vertex_Id; Weight : Integer)
   is
      W : Distance_Value;
   begin
      if Weight < Integer (Weight_Type'First)
        or else Weight > Integer (Weight_Type'Last)
      then
         raise Invalid_Argument;
      end if;
      if From not in Dist'Range (1) or else To not in Dist'Range (2) then
         raise Invalid_Argument;
      end if;
      W := Distance_Value (Weight);
      Dist (From, To) := Min_Dist (Dist (From, To), W);
   end Put_Edge;

   procedure Init_Dist (G : Graph; Dist : out Dist_Matrix) is
      N : constant Natural := G.N;
   begin
      Init_Dist (Dist, N);
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         for J in Vertex_Id range 1 .. Vertex_Id (N) loop
            if G.Present (I, J) then
               Dist (I, J) := Min_Dist (Dist (I, J), G.Weight (I, J));
            end if;
         end loop;
      end loop;
   end Init_Dist;

   procedure Init_Next_From_Dist
     (Dist : Dist_Matrix; Next : out Next_Matrix; N : Natural)
   is
   begin
      Validate_Square
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      Validate_Square
        (N, Next'First (1), Next'Last (1), Next'First (2), Next'Last (2));
      for I in Next'Range (1) loop
         for J in Next'Range (2) loop
            Next (I, J) := 0;
         end loop;
      end loop;
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         for J in Vertex_Id range 1 .. Vertex_Id (N) loop
            if I = J then
               Next (I, J) := Natural (I);
            elsif Dist (I, J) /= Infinity then
               Next (I, J) := Natural (J);
            else
               Next (I, J) := 0;
            end if;
         end loop;
      end loop;
   end Init_Next_From_Dist;

   procedure Init_Prev_From_Dist
     (Dist : Dist_Matrix; Prev : out Prev_Matrix; N : Natural)
   is
   begin
      Validate_Square
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      Validate_Square
        (N, Prev'First (1), Prev'Last (1), Prev'First (2), Prev'Last (2));
      for I in Prev'Range (1) loop
         for J in Prev'Range (2) loop
            Prev (I, J) := 0;
         end loop;
      end loop;
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         for J in Vertex_Id range 1 .. Vertex_Id (N) loop
            if I = J then
               Prev (I, J) := 0;
            elsif Dist (I, J) /= Infinity then
               Prev (I, J) := Natural (I);
            else
               Prev (I, J) := 0;
            end if;
         end loop;
      end loop;
   end Init_Prev_From_Dist;

   -------------------------------------------------------------------------
   -- Core triple loop
   -------------------------------------------------------------------------

   procedure Run_Core
     (Dist      : in out Dist_Matrix;
      N         : Natural;
      Use_Next  : Boolean;
      Next      : in out Next_Matrix;
      Use_Prev  : Boolean;
      Prev      : in out Prev_Matrix;
      Status    : out Run_Status)
   is
      Cand : Distance_Value;
      Neg  : Boolean := False;
   begin
      Validate_Square
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      if Use_Next then
         Validate_Square
           (N, Next'First (1), Next'Last (1),
            Next'First (2), Next'Last (2));
      end if;
      if Use_Prev then
         Validate_Square
           (N, Prev'First (1), Prev'Last (1),
            Prev'First (2), Prev'Last (2));
      end if;

      for K in Vertex_Id range 1 .. Vertex_Id (N) loop
         for I in Vertex_Id range 1 .. Vertex_Id (N) loop
            if Dist (I, K) /= Infinity then
               for J in Vertex_Id range 1 .. Vertex_Id (N) loop
                  if Dist (K, J) /= Infinity then
                     Cand := Safe_Add (Dist (I, K), Dist (K, J));
                     if Cand < Dist (I, J) then
                        Dist (I, J) := Cand;
                        if Use_Next then
                           Next (I, J) := Next (I, K);
                        end if;
                        if Use_Prev then
                           Prev (I, J) := Prev (K, J);
                        end if;
                     end if;
                  end if;
               end loop;
            end if;
            --  Early negative-cycle probe on the diagonal (avoids extreme
            --  underflow from repeated improvements around a cycle).
            if Dist (I, I) < 0 then
               Neg := True;
            end if;
         end loop;
      end loop;

      if not Neg then
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            if Dist (V, V) < 0 then
               Neg := True;
               exit;
            end if;
         end loop;
      end if;

      if Neg then
         Status := Negative_Cycle;
      else
         Status := Success;
      end if;
   end Run_Core;

   --  Dummy matrices for overloads that do not use Next/Prev.
   Dummy_Next : Next_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
   Dummy_Prev : Prev_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];

   procedure Run_Dist_Only
     (Dist : in out Dist_Matrix; N : Natural; Status : out Run_Status)
   is
      Local_Next : Next_Matrix (1 .. 1, 1 .. 1) := Dummy_Next;
      Local_Prev : Prev_Matrix (1 .. 1, 1 .. 1) := Dummy_Prev;
   begin
      Run_Core
        (Dist, N,
         False, Local_Next,
         False, Local_Prev,
         Status);
   end Run_Dist_Only;

   -------------------------------------------------------------------------
   -- Public All_Pairs / Floyd_Warshall from Graph
   -------------------------------------------------------------------------

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      Init_Dist (G, Dist);
      Run_Dist_Only (Dist, N, Status);
   end All_Pairs;

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Status : out Run_Status)
   is
      N          : constant Natural := G.N;
      Local_Prev : Prev_Matrix (1 .. 1, 1 .. 1) := Dummy_Prev;
   begin
      Init_Dist (G, Dist);
      Init_Next_From_Dist (Dist, Next, N);
      Run_Core
        (Dist, N, True, Next, False, Local_Prev, Status);
   end All_Pairs;

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
      N          : constant Natural := G.N;
      Local_Next : Next_Matrix (1 .. 1, 1 .. 1) := Dummy_Next;
   begin
      Init_Dist (G, Dist);
      Init_Prev_From_Dist (Dist, Prev, N);
      Run_Core
        (Dist, N, False, Local_Next, True, Prev, Status);
   end All_Pairs;

   procedure All_Pairs
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      Init_Dist (G, Dist);
      Init_Next_From_Dist (Dist, Next, N);
      Init_Prev_From_Dist (Dist, Prev, N);
      Run_Core (Dist, N, True, Next, True, Prev, Status);
   end All_Pairs;

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
   is
   begin
      All_Pairs (G, Dist, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Next   : out Next_Matrix;
      Status : out Run_Status)
   is
   begin
      All_Pairs (G, Dist, Next, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
   begin
      All_Pairs (G, Dist, Prev, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      N      : Natural;
      Status : out Run_Status)
   is
   begin
      Run_Dist_Only (Dist, N, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      Next   : in out Next_Matrix;
      N      : Natural;
      Status : out Run_Status)
   is
      Local_Prev : Prev_Matrix (1 .. 1, 1 .. 1) := Dummy_Prev;
   begin
      Run_Core (Dist, N, True, Next, False, Local_Prev, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      Prev   : in out Prev_Matrix;
      N      : Natural;
      Status : out Run_Status)
   is
      Local_Next : Next_Matrix (1 .. 1, 1 .. 1) := Dummy_Next;
   begin
      Run_Core (Dist, N, False, Local_Next, True, Prev, Status);
   end Floyd_Warshall;

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Next : out Next_Matrix)
   is
      St : Run_Status;
   begin
      All_Pairs (G, Dist, Next, St);
      if St = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end All_Pairs;

   procedure All_Pairs
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
   is
      St : Run_Status;
   begin
      All_Pairs (G, Dist, Prev, St);
      if St = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end All_Pairs;

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Next : out Next_Matrix)
   is
   begin
      All_Pairs (G, Dist, Next);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
   is
   begin
      All_Pairs (G, Dist, Prev);
   end Floyd_Warshall;

   -------------------------------------------------------------------------
   -- Queries
   -------------------------------------------------------------------------

   function Has_Negative_Cycle (G : Graph) return Boolean is
      N    : constant Natural := G.N;
      Dist : Dist_Matrix (1 .. Vertex_Id (Max_Vertices),
                          1 .. Vertex_Id (Max_Vertices));
      St   : Run_Status;
   begin
      Validate_N (N);
      --  Oversized Dist is fine: Validate requires Last >= N.
      All_Pairs (G, Dist, St);
      return St = Negative_Cycle;
   end Has_Negative_Cycle;

   function Has_Negative_Cycle
     (Dist : Dist_Matrix; N : Natural) return Boolean
   is
   begin
      Validate_Square
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (V, V) < 0 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Negative_Cycle;

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N    : constant Natural := G.N;
      Dist : Dist_Matrix (1 .. Vertex_Id (Max_Vertices),
                          1 .. Vertex_Id (Max_Vertices));
      St   : Run_Status;
   begin
      Validate_N (N);
      if Natural (Source) > N or else Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      All_Pairs (G, Dist, St);
      if St = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
      return Dist (Source, Target);
   end Distance;

   -------------------------------------------------------------------------
   -- Path reconstruction
   -------------------------------------------------------------------------

   function Reconstruct_Path
     (Next   : Next_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      U     : Natural;
      Guard : Natural := 0;
   begin
      Length := 0;

      if Source not in Next'Range (1)
        or else Target not in Next'Range (2)
      then
         raise Invalid_Argument;
      end if;
      if Path'First /= 1
        or else Natural (Path'Last) < Natural (Next'Last (1))
      then
         raise Invalid_Argument;
      end if;

      if Source = Target then
         if Next (Source, Source) = 0 then
            return False;
         end if;
         Path (1) := Source;
         Length := 1;
         return True;
      end if;

      if Next (Source, Target) = 0 then
         return False;
      end if;

      U := Natural (Source);
      while U /= Natural (Target) loop
         Guard := Guard + 1;
         if Guard > Max_Vertices + 1 then
            Length := 0;
            return False;
         end if;
         if Length >= Natural (Path'Last) then
            Length := 0;
            return False;
         end if;
         Length := Length + 1;
         Path (Length) := Vertex_Id (U);
         if U not in Natural (Next'First (1)) .. Natural (Next'Last (1)) then
            Length := 0;
            return False;
         end if;
         U := Next (Vertex_Id (U), Target);
         if U = 0 then
            Length := 0;
            return False;
         end if;
      end loop;
      if Length >= Natural (Path'Last) then
         Length := 0;
         return False;
      end if;
      Length := Length + 1;
      Path (Length) := Target;
      return True;
   end Reconstruct_Path;

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

end Floyd_Warshall_Algorithm;
