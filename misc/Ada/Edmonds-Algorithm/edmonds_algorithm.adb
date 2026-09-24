--  Edmonds_Algorithm body — Chu–Liu/Edmonds recursive contraction
--  with fixed educational scratch levels (no dynamic heap).

pragma Ada_2022;

package body Edmonds_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Scratch workspace for recursive contraction (one level per reduction)
   -------------------------------------------------------------------------

   Max_Depth : constant Positive := Max_Vertices;

   type Nat_Arr is array (1 .. Max_Vertices) of Natural;
   type Int_Arr is array (1 .. Max_Vertices) of Integer;
   type Bool_Arr is array (1 .. Max_Vertices) of Boolean;
   type Color_Arr is array (1 .. Max_Vertices) of Natural;

   type Work_U_Arr is array (1 .. Max_Edges) of Natural;
   type Work_V_Arr is array (1 .. Max_Edges) of Natural;
   type Work_W_Arr is array (1 .. Max_Edges) of Integer;
   type Work_O_Arr is array (1 .. Max_Edges) of Natural;

   type Level_State is record
      N         : Natural := 0;
      Root      : Natural := 0;
      M         : Natural := 0;
      U         : Work_U_Arr := [others => 0];
      V         : Work_V_Arr := [others => 0];
      W         : Work_W_Arr := [others => 0];
      Orig      : Work_O_Arr := [others => 0];
      --  Min incoming selection
      Min_W     : Int_Arr := [others => 0];
      Min_U     : Nat_Arr := [others => 0];
      Min_Orig  : Nat_Arr := [others => 0];
      Has_In    : Bool_Arr := [others => False];
      --  Cycle / remap
      Color     : Color_Arr := [others => 0];
      In_Cycle  : Bool_Arr := [others => False];
      Map       : Nat_Arr := [others => 0];
      Cycle_Nodes : Nat_Arr := [others => 0];
      Cycle_Len : Natural := 0;
   end record;

   type Level_Array is array (0 .. Max_Depth) of Level_State;
   Levels : Level_Array;

   --  Selected original edge indices (1 .. M_input) accumulated on success
   Selected     : array (1 .. Max_Vertices) of Natural := [others => 0];
   Selected_Len : Natural := 0;

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.M := 0;
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
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      G.Edges (G.M) :=
        (From => From, To => To, Weight => Weight_Type (Weight));
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.M);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Validation
   -------------------------------------------------------------------------

   procedure Validate_Root_And_Buffer
     (G : Graph; Root : Vertex_Id; Tree_Edges : Edge_List)
   is
      Need : Natural;
   begin
      if G.N = 0 or else Natural (Root) > G.N then
         raise Invalid_Argument;
      end if;
      if Tree_Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      Need := (if G.N = 0 then 0 else G.N - 1);
      if Tree_Edges'Last < Need then
         raise Invalid_Argument;
      end if;
   end Validate_Root_And_Buffer;

   -------------------------------------------------------------------------
   -- Core recursive Chu–Liu / Edmonds on Levels (Depth)
   -------------------------------------------------------------------------

   procedure Solve_Level (Depth : Natural; OK : out Boolean) is
      L      : Level_State renames Levels (Depth);
      Parent : Nat_Arr;
      Cycle_Found : Boolean := False;
      Entry_V : Natural;
      N2, Root2, VC : Natural;
      U2, V2 : Natural;
      W2 : Integer;
      --  Temporary new-edge accumulation into next level
      procedure Add_Cand
        (U, V : Natural; W : Integer; Oi : Natural; Dest : in out Level_State)
      is
         J : Natural;
         Found : Boolean := False;
      begin
         if U = V then
            return;
         end if;
         for K in 1 .. Dest.M loop
            if Dest.U (K) = U and then Dest.V (K) = V then
               Found := True;
               if W < Dest.W (K)
                 or else (W = Dest.W (K) and then Oi < Dest.Orig (K))
               then
                  Dest.W (K) := W;
                  Dest.Orig (K) := Oi;
               end if;
               exit;
            end if;
         end loop;
         if not Found then
            if Dest.M >= Max_Edges then
               --  Educational overflow during contraction
               raise Invalid_Argument;
            end if;
            Dest.M := Dest.M + 1;
            J := Dest.M;
            Dest.U (J) := U;
            Dest.V (J) := V;
            Dest.W (J) := W;
            Dest.Orig (J) := Oi;
         end if;
      end Add_Cand;

   begin
      --  Filter: drop self-loops and edges into Root (in place compact)
      declare
         Wrt : Natural := 0;
      begin
         for I in 1 .. L.M loop
            if L.U (I) /= L.V (I) and then L.V (I) /= L.Root then
               Wrt := Wrt + 1;
               L.U (Wrt) := L.U (I);
               L.V (Wrt) := L.V (I);
               L.W (Wrt) := L.W (I);
               L.Orig (Wrt) := L.Orig (I);
            end if;
         end loop;
         L.M := Wrt;
      end;

      if L.N <= 1 then
         OK := True;
         return;
      end if;

      --  Phase 1: cheapest incoming edge per non-root vertex
      for V in 1 .. L.N loop
         L.Has_In (V) := False;
         L.Min_U (V) := 0;
         L.Min_Orig (V) := 0;
         L.Min_W (V) := 0;
         Parent (V) := 0;
      end loop;

      for I in 1 .. L.M loop
         declare
            V : constant Natural := L.V (I);
            U : constant Natural := L.U (I);
            W : constant Integer := L.W (I);
         begin
            if V /= L.Root then
               if not L.Has_In (V)
                 or else W < L.Min_W (V)
                 or else (W = L.Min_W (V) and then L.Orig (I) < L.Min_Orig (V))
               then
                  L.Has_In (V) := True;
                  L.Min_W (V) := W;
                  L.Min_U (V) := U;
                  L.Min_Orig (V) := L.Orig (I);
               end if;
            end if;
         end;
      end loop;

      for V in 1 .. L.N loop
         if V /= L.Root then
            if not L.Has_In (V) then
               OK := False;
               return;
            end if;
            Parent (V) := L.Min_U (V);
         end if;
      end loop;

      --  Phase 2: find one cycle in the Parent functional graph
      for V in 1 .. L.N loop
         L.Color (V) := 0;
         L.In_Cycle (V) := False;
      end loop;
      L.Cycle_Len := 0;
      Cycle_Found := False;

      for S in 1 .. L.N loop
         exit when Cycle_Found;
         if S /= L.Root and then L.Color (S) = 0 then
            declare
               V : Natural := S;
               Stack : Nat_Arr := [others => 0];
               Sp : Natural := 0;
               Hit : Natural;
            begin
               while V /= L.Root and then V /= 0 and then L.Color (V) = 0 loop
                  L.Color (V) := 1;
                  Sp := Sp + 1;
                  Stack (Sp) := V;
                  V := Parent (V);
               end loop;
               if V /= L.Root and then V /= 0 and then L.Color (V) = 1 then
                  --  Collect cycle ending at V
                  Hit := 0;
                  for K in reverse 1 .. Sp loop
                     Hit := Hit + 1;
                     L.Cycle_Nodes (Hit) := Stack (K);
                     exit when Stack (K) = V;
                  end loop;
                  --  Reverse to forward cycle order
                  declare
                     Tmp : Nat_Arr := L.Cycle_Nodes;
                  begin
                     for K in 1 .. Hit loop
                        L.Cycle_Nodes (K) := Tmp (Hit - K + 1);
                     end loop;
                  end;
                  L.Cycle_Len := Hit;
                  for K in 1 .. Hit loop
                     L.In_Cycle (L.Cycle_Nodes (K)) := True;
                  end loop;
                  Cycle_Found := True;
               else
                  for K in 1 .. Sp loop
                     L.Color (Stack (K)) := 2;
                  end loop;
               end if;
            end;
         end if;
      end loop;

      if not Cycle_Found then
         --  Acyclic selection: record original edge indices
         for V in 1 .. L.N loop
            if V /= L.Root then
               Selected_Len := Selected_Len + 1;
               Selected (Selected_Len) := L.Min_Orig (V);
            end if;
         end loop;
         OK := True;
         return;
      end if;

      --  Phase 3: contract cycle into supernode; recurse
      if Depth >= Max_Depth then
         raise Invalid_Argument;
      end if;

      --  Remap vertices: cycle → one id VC; others get fresh ids
      N2 := 0;
      VC := 0;
      for V in 1 .. L.N loop
         if L.In_Cycle (V) then
            if VC = 0 then
               N2 := N2 + 1;
               VC := N2;
            end if;
            L.Map (V) := VC;
         else
            N2 := N2 + 1;
            L.Map (V) := N2;
         end if;
      end loop;
      Root2 := L.Map (L.Root);

      declare
         Next : Level_State renames Levels (Depth + 1);
      begin
         Next.N := N2;
         Next.Root := Root2;
         Next.M := 0;

         for I in 1 .. L.M loop
            declare
               U : constant Natural := L.U (I);
               V : constant Natural := L.V (I);
               W : constant Integer := L.W (I);
               Oi : constant Natural := L.Orig (I);
               U_In : constant Boolean := L.In_Cycle (U);
               V_In : constant Boolean := L.In_Cycle (V);
            begin
               if U_In and then V_In then
                  null;  -- internal cycle edge discarded
               elsif (not U_In) and then V_In then
                  --  Entering cycle: adjust weight
                  W2 := W - L.Min_W (V);
                  U2 := L.Map (U);
                  V2 := VC;
                  Add_Cand (U2, V2, W2, Oi, Next);
               elsif U_In and then (not V_In) then
                  U2 := VC;
                  V2 := L.Map (V);
                  Add_Cand (U2, V2, W, Oi, Next);
               else
                  U2 := L.Map (U);
                  V2 := L.Map (V);
                  Add_Cand (U2, V2, W, Oi, Next);
               end if;
            end;
         end loop;

         Solve_Level (Depth + 1, OK);
         if not OK then
            return;
         end if;
      end;

      --  Expand: find which cycle node is the entry point
      Entry_V := 0;
      for K in 1 .. Selected_Len loop
         declare
            Oi : constant Natural := Selected (K);
         begin
            --  Look up original endpoints among this level's filtered edges
            --  and among Min_Orig cycle edges' sources — use graph via Orig
            --  stored on edges at this level: scan L edges for Orig = Oi
            for I in 1 .. L.M loop
               if L.Orig (I) = Oi then
                  if L.In_Cycle (L.V (I)) and then not L.In_Cycle (L.U (I)) then
                     Entry_V := L.V (I);
                  end if;
                  exit;
               end if;
            end loop;
            --  Also: Orig may refer to an edge not in L.M if it was filtered;
            --  but contracted incoming edges keep Orig of an edge present in L
            exit when Entry_V /= 0;
         end;
      end loop;

      --  Fallback: match Orig against min-incoming bookkeeping by scanning
      --  all edges that enter the cycle with that Orig from input at this level
      if Entry_V = 0 then
         for K in 1 .. Selected_Len loop
            declare
               Oi : constant Natural := Selected (K);
            begin
               for I in 1 .. L.M loop
                  if L.Orig (I) = Oi
                    and then L.In_Cycle (L.V (I))
                    and then not L.In_Cycle (L.U (I))
                  then
                     Entry_V := L.V (I);
                     exit;
                  end if;
               end loop;
               exit when Entry_V /= 0;
            end;
         end loop;
      end if;

      if Entry_V = 0 then
         --  Should not happen for a well-formed contraction
         OK := False;
         return;
      end if;

      --  Add all cycle π-edges except the one whose head is Entry_V
      for K in 1 .. L.Cycle_Len loop
         declare
            V : constant Natural := L.Cycle_Nodes (K);
         begin
            if V /= Entry_V then
               Selected_Len := Selected_Len + 1;
               Selected (Selected_Len) := L.Min_Orig (V);
            end if;
         end;
      end loop;

      OK := True;
   end Solve_Level;

   -------------------------------------------------------------------------
   -- Drive Solve from a Graph
   -------------------------------------------------------------------------

   procedure Run_Edmonds
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
   is
      OK  : Boolean;
      Sum : Weight_Sum;
      Seen : array (1 .. Max_Edges) of Boolean := [others => False];
      Out_N : Natural := 0;
      Oi : Natural;
   begin
      Validate_Root_And_Buffer (G, Root, Tree_Edges);

      Levels (0).N := G.N;
      Levels (0).Root := Natural (Root);
      Levels (0).M := Natural (G.M);
      for I in 1 .. Natural (G.M) loop
         Levels (0).U (I) := Natural (G.Edges (I).From);
         Levels (0).V (I) := Natural (G.Edges (I).To);
         Levels (0).W (I) := Integer (G.Edges (I).Weight);
         Levels (0).Orig (I) := I;
      end loop;

      Selected_Len := 0;
      Solve_Level (0, OK);

      if not OK then
         Tree_Count := 0;
         Total_Weight := 0;
         Status := Impossible;
         return;
      end if;

      --  Deduplicate selected original indices and emit edges
      Sum := 0;
      Out_N := 0;
      for K in 1 .. Selected_Len loop
         Oi := Selected (K);
         if Oi >= 1 and then Oi <= Natural (G.M) and then not Seen (Oi) then
            Seen (Oi) := True;
            Out_N := Out_N + 1;
            Tree_Edges (Out_N) := G.Edges (Oi);
            Sum := Sum + Weight_Sum (G.Edges (Oi).Weight);
         end if;
      end loop;

      if Out_N /= G.N - 1 then
         --  Defensive: malformed reconstruction ⇒ treat as impossible
         Tree_Count := 0;
         Total_Weight := 0;
         Status := Impossible;
         return;
      end if;

      Tree_Count := Out_N;
      Total_Weight := Sum;
      Status := Success;
   end Run_Edmonds;

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
   is
   begin
      Run_Edmonds (G, Root, Tree_Edges, Tree_Count, Total_Weight, Status);
   end Minimum_Arborescence;

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      St : Run_Status;
   begin
      Run_Edmonds (G, Root, Tree_Edges, Tree_Count, Total_Weight, St);
      if St = Impossible then
         raise Impossible_Arborescence;
      end if;
   end Minimum_Arborescence;

   procedure Edmonds
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
   is
   begin
      Run_Edmonds (G, Root, Tree_Edges, Tree_Count, Total_Weight, Status);
   end Edmonds;

   -------------------------------------------------------------------------
   -- Brute-force oracle (N ≤ 8)
   -------------------------------------------------------------------------

   procedure Brute_Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status)
   is
      N : constant Natural := G.N;
      R : constant Natural := Natural (Root);

      subtype V_Range is Natural range 1 .. Brute_Max_Vertices;

      type In_List is array (1 .. Max_Edges) of Natural;
      Incoming : array (V_Range) of In_List := [others => [others => 0]];
      In_Count : array (V_Range) of Natural := [others => 0];

      Nonroot : array (1 .. Brute_Max_Vertices) of Natural := [others => 0];
      NR : Natural := 0;

      Choice : array (1 .. Brute_Max_Vertices) of Natural := [others => 0];
      --  Choice(I) = index into Incoming(Nonroot(I))

      Best_Sum : Weight_Sum := 0;
      Have_Best : Boolean := False;
      Best_Edges : array (1 .. Brute_Max_Vertices) of Natural := [others => 0];

      function Forms_Arborescence return Boolean is
         Indeg : array (1 .. Brute_Max_Vertices) of Natural := [others => 0];
         Par   : array (1 .. Brute_Max_Vertices) of Natural := [others => 0];
         V, U, Oi, Steps : Natural;
      begin
         for I in 1 .. NR loop
            V := Nonroot (I);
            Oi := Incoming (V)(Choice (I));
            U := Natural (G.Edges (Oi).From);
            Indeg (V) := Indeg (V) + 1;
            Par (V) := U;
         end loop;
         if Indeg (R) /= 0 then
            return False;
         end if;
         for V in 1 .. N loop
            if V /= R and then Indeg (V) /= 1 then
               return False;
            end if;
         end loop;
         for V in 1 .. N loop
            if V /= R then
               declare
                  Seen : array (1 .. Brute_Max_Vertices) of Boolean :=
                    [others => False];
               begin
                  U := V;
                  Steps := 0;
                  while U /= R loop
                     if Seen (U) or else Par (U) = 0 then
                        return False;
                     end if;
                     Seen (U) := True;
                     U := Par (U);
                     Steps := Steps + 1;
                     if Steps > N then
                        return False;
                     end if;
                  end loop;
               end;
            end if;
         end loop;
         return True;
      end Forms_Arborescence;

      procedure Recurse (Pos : Natural) is
         V : Natural;
         Oi : Natural;
         Sum : Weight_Sum;
      begin
         if Pos > NR then
            if Forms_Arborescence then
               Sum := 0;
               for I in 1 .. NR loop
                  V := Nonroot (I);
                  Oi := Incoming (V)(Choice (I));
                  Sum := Sum + Weight_Sum (G.Edges (Oi).Weight);
               end loop;
               if not Have_Best or else Sum < Best_Sum then
                  Have_Best := True;
                  Best_Sum := Sum;
                  for I in 1 .. NR loop
                     Best_Edges (I) := Incoming (Nonroot (I))(Choice (I));
                  end loop;
               end if;
            end if;
            return;
         end if;
         V := Nonroot (Pos);
         for J in 1 .. In_Count (V) loop
            Choice (Pos) := J;
            Recurse (Pos + 1);
         end loop;
      end Recurse;

   begin
      Validate_Root_And_Buffer (G, Root, Tree_Edges);
      if N > Brute_Max_Vertices then
         raise Invalid_Argument;
      end if;

      for V in 1 .. N loop
         if V /= R then
            NR := NR + 1;
            Nonroot (NR) := V;
         end if;
      end loop;

      for I in 1 .. Natural (G.M) loop
         declare
            U : constant Natural := Natural (G.Edges (I).From);
            V : constant Natural := Natural (G.Edges (I).To);
         begin
            pragma Unreferenced (U);
            if V /= R and then Natural (G.Edges (I).From) /= V then
               In_Count (V) := In_Count (V) + 1;
               Incoming (V)(In_Count (V)) := I;
            end if;
         end;
      end loop;

      for I in 1 .. NR loop
         if In_Count (Nonroot (I)) = 0 then
            Tree_Count := 0;
            Total_Weight := 0;
            Status := Impossible;
            return;
         end if;
      end loop;

      if N = 1 then
         Tree_Count := 0;
         Total_Weight := 0;
         Status := Success;
         return;
      end if;

      Recurse (1);

      if not Have_Best then
         Tree_Count := 0;
         Total_Weight := 0;
         Status := Impossible;
         return;
      end if;

      Tree_Count := NR;
      Total_Weight := Best_Sum;
      for I in 1 .. NR loop
         Tree_Edges (I) := G.Edges (Best_Edges (I));
      end loop;
      Status := Success;
   end Brute_Minimum_Arborescence;

end Edmonds_Algorithm;
