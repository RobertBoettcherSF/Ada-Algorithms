--  Longest_Path_Problem body — DAG DP + exact bitset DFS.

pragma Ada_2022;

with Interfaces;

package body Longest_Path_Problem
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
      if Weight < 0 then
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

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id) is
   begin
      Add_Edge (G, From, To, 1);
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

   procedure Validate_Vertex (G : Graph; V : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Path_Bounds
     (N : Natural; Path_First, Path_Last : Positive)
   is
   begin
      if Path_First /= 1 or else Path_Last < N then
         raise Invalid_Argument;
      end if;
   end Validate_Path_Bounds;

   procedure Validate_Exact_N (N : Natural) is
   begin
      Validate_N (N);
      if N > Max_Exact_Vertices then
         raise Invalid_Argument;
      end if;
   end Validate_Exact_N;

   -------------------------------------------------------------------------
   -- Kahn topological order (also cycle detection)
   -------------------------------------------------------------------------

   function Topo_Order
     (G     : Graph;
      Order : out Path_Array) return Boolean
   is
      N      : constant Natural := G.N;
      In_Deg : array (Vertex_Id) of Natural := [others => 0];
      Queue  : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Q_Head : Natural := 1;
      Q_Tail : Natural := 0;
      Count  : Natural := 0;
      E_Idx  : Natural;
      W      : Vertex_Id;
      U      : Vertex_Id;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         E_Idx := G.Head (V);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            In_Deg (W) := In_Deg (W) + 1;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if In_Deg (V) = 0 then
            Q_Tail := Q_Tail + 1;
            Queue (Q_Tail) := V;
         end if;
      end loop;

      while Q_Head <= Q_Tail loop
         U := Queue (Q_Head);
         Q_Head := Q_Head + 1;
         Count := Count + 1;
         Order (Count) := U;

         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            In_Deg (W) := In_Deg (W) - 1;
            if In_Deg (W) = 0 then
               Q_Tail := Q_Tail + 1;
               Queue (Q_Tail) := W;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      return Count = N;
   end Topo_Order;

   function Is_Acyclic (G : Graph) return Boolean is
      Order : Path_Array (1 .. Max_Vertices);
   begin
      if G.N = 0 then
         return True;
      end if;
      return Topo_Order (G, Order);
   end Is_Acyclic;

   -------------------------------------------------------------------------
   -- Safe weight addition (cap at Infinity)
   -------------------------------------------------------------------------

   function Safe_Add
     (A : Distance_Value; W : Weight_Type) return Distance_Value
   is
      Wd : constant Distance_Value := Distance_Value (W);
   begin
      if A >= Infinity - Wd then
         return Infinity;
      end if;
      return A + Wd;
   end Safe_Add;

   -------------------------------------------------------------------------
   -- DAG global longest path
   -------------------------------------------------------------------------

   procedure DAG_Longest_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value;
      Status : out Run_Status)
   is
      N      : constant Natural := G.N;
      Order  : Path_Array (1 .. Max_Vertices);
      Dist   : array (Vertex_Id) of Distance_Value := [others => 0];
      Prev   : array (Vertex_Id) of Natural := [others => 0];
      Best_V : Vertex_Id := 1;
      Best_D : Distance_Value := 0;
      U, W   : Vertex_Id;
      E_Idx  : Natural;
      Alt    : Distance_Value;
      Stack  : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Top    : Natural;
      Cur    : Natural;
   begin
      Validate_N (N);
      Validate_Path_Bounds (N, Path'First, Path'Last);

      Length := 0;
      Weight := 0;
      Status := Cycle_Detected;

      if not Topo_Order (G, Order) then
         return;
      end if;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := 0;
         Prev (V) := 0;
      end loop;

      for I in 1 .. N loop
         U := Order (I);
         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            Alt := Safe_Add (Dist (U), G.Weight (E_Idx));
            if Alt > Dist (W) then
               Dist (W) := Alt;
               Prev (W) := Natural (U);
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      Best_V := 1;
      Best_D := Dist (1);
      for V in Vertex_Id range 2 .. Vertex_Id (N) loop
         if Dist (V) > Best_D then
            Best_D := Dist (V);
            Best_V := V;
         end if;
      end loop;

      Top := 0;
      Cur := Natural (Best_V);
      while Cur /= 0 loop
         Top := Top + 1;
         if Top > N then
            Length := 0;
            Weight := 0;
            Status := Cycle_Detected;
            return;
         end if;
         Stack (Top) := Vertex_Id (Cur);
         Cur := Prev (Vertex_Id (Cur));
      end loop;

      Length := Top;
      Weight := Best_D;
      for I in 1 .. Top loop
         Path (I) := Stack (Top - I + 1);
      end loop;
      Status := Success;
   end DAG_Longest_Path;

   procedure DAG_Longest_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
   is
      Status : Run_Status;
   begin
      DAG_Longest_Path (G, Path, Length, Weight, Status);
      if Status = Cycle_Detected then
         raise Cycle_Error;
      end if;
   end DAG_Longest_Path;

   procedure DAG_Longest_From
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
   is
      N     : constant Natural := G.N;
      Order : Path_Array (1 .. Max_Vertices);
      U, W  : Vertex_Id;
      E_Idx : Natural;
      Alt   : Distance_Value;
      Reach : array (Vertex_Id) of Boolean := [others => False];
   begin
      Validate_Vertex (G, Source);
      if Dist'First /= 1
        or else Natural (Dist'Last) < N
        or else Prev'First /= 1
        or else Natural (Prev'Last) < N
      then
         raise Invalid_Argument;
      end if;

      Status := Cycle_Detected;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
      end loop;

      if not Topo_Order (G, Order) then
         return;
      end if;

      Dist (Source) := 0;
      Reach (Source) := True;

      for I in 1 .. N loop
         U := Order (I);
         if Reach (U) then
            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W := G.To (E_Idx);
               Alt := Safe_Add (Dist (U), G.Weight (E_Idx));
               if not Reach (W) or else Alt > Dist (W) then
                  Dist (W) := Alt;
                  Prev (W) := Natural (U);
                  Reach (W) := True;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end if;
      end loop;

      Status := Success;
   end DAG_Longest_From;

   function DAG_Longest_Weight (G : Graph) return Distance_Value is
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Wgt    : Distance_Value;
   begin
      DAG_Longest_Path (G, Path, Length, Wgt);
      return Wgt;
   end DAG_Longest_Weight;

   -------------------------------------------------------------------------
   -- Exact simple-path DFS (bitset)
   -------------------------------------------------------------------------

   subtype Mask_Type is Interfaces.Unsigned_32;

   function Bit (V : Vertex_Id) return Mask_Type is
   begin
      return Interfaces.Shift_Left (1, Natural (V) - 1);
   end Bit;

   function Is_Set (M : Mask_Type; V : Vertex_Id) return Boolean is
      use type Interfaces.Unsigned_32;
   begin
      return (M and Bit (V)) /= 0;
   end Is_Set;

   procedure Exact_Search
     (G              : Graph;
      Restrict_Start : Boolean;
      Start_Vertex   : Vertex_Id;
      Restrict_End   : Boolean;
      End_Vertex     : Vertex_Id;
      Out_Path       : out Path_Array;
      Out_Length     : out Natural;
      Out_Weight     : out Distance_Value;
      Out_Found      : out Boolean)
   is
      use type Interfaces.Unsigned_32;

      N : constant Natural := G.N;

      Cur_Path : array (1 .. Max_Exact_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Cur_Len  : Natural := 0;
      Cur_W    : Distance_Value := 0;

      Best_Path : array (1 .. Max_Exact_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Best_Len  : Natural := 0;
      Best_W    : Distance_Value := 0;
      Have_Best : Boolean := False;

      procedure Record_Best is
         Better : Boolean;
      begin
         if Restrict_End then
            if Cur_Len = 0
              or else Cur_Path (Cur_Len) /= End_Vertex
            then
               return;
            end if;
         end if;

         if not Have_Best then
            Better := True;
         elsif Cur_W > Best_W then
            Better := True;
         elsif Cur_W < Best_W then
            Better := False;
         elsif Cur_Len > Best_Len then
            Better := True;
         elsif Cur_Len < Best_Len then
            Better := False;
         else
            Better := False;
            for I in 1 .. Cur_Len loop
               if Cur_Path (I) < Best_Path (I) then
                  Better := True;
                  exit;
               elsif Cur_Path (I) > Best_Path (I) then
                  exit;
               end if;
            end loop;
         end if;

         if Better then
            Have_Best := True;
            Best_W := Cur_W;
            Best_Len := Cur_Len;
            for I in 1 .. Cur_Len loop
               Best_Path (I) := Cur_Path (I);
            end loop;
         end if;
      end Record_Best;

      procedure DFS (U : Vertex_Id; Mask : Mask_Type) is
         E_Idx : Natural;
         W     : Vertex_Id;
         Cw    : Weight_Type;
      begin
         Record_Best;

         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if not Is_Set (Mask, W) then
               Cw := G.Weight (E_Idx);
               Cur_Len := Cur_Len + 1;
               Cur_Path (Cur_Len) := W;
               Cur_W := Safe_Add (Cur_W, Cw);
               DFS (W, Mask or Bit (W));
               Cur_W := Cur_W - Distance_Value (Cw);
               Cur_Len := Cur_Len - 1;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end DFS;

      S_First, S_Last : Vertex_Id;
   begin
      Out_Found := False;
      Out_Length := 0;
      Out_Weight := 0;

      if Restrict_Start then
         S_First := Start_Vertex;
         S_Last  := Start_Vertex;
      else
         S_First := 1;
         S_Last  := Vertex_Id (N);
      end if;

      for S in S_First .. S_Last loop
         Cur_Len := 1;
         Cur_Path (1) := S;
         Cur_W := 0;
         DFS (S, Bit (S));
      end loop;

      if Have_Best then
         Out_Found := True;
         Out_Length := Best_Len;
         Out_Weight := Best_W;
         for I in 1 .. Best_Len loop
            Out_Path (I) := Best_Path (I);
         end loop;
      end if;
   end Exact_Search;

   procedure Exact_Simple_Path
     (G      : Graph;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
   is
      Found : Boolean;
   begin
      Validate_Exact_N (G.N);
      Validate_Path_Bounds (G.N, Path'First, Path'Last);
      Exact_Search
        (G, False, 1, False, 1, Path, Length, Weight, Found);
      pragma Unreferenced (Found);
   end Exact_Simple_Path;

   procedure Exact_Simple_Path
     (G              : Graph;
      Source, Target : Vertex_Id;
      Path           : out Path_Array;
      Length         : out Natural;
      Weight         : out Distance_Value;
      Found          : out Boolean)
   is
   begin
      Validate_Exact_N (G.N);
      Validate_Vertex (G, Source);
      Validate_Vertex (G, Target);
      Validate_Path_Bounds (G.N, Path'First, Path'Last);
      Exact_Search
        (G, True, Source, True, Target, Path, Length, Weight, Found);
   end Exact_Simple_Path;

   procedure Exact_Simple_Path_From
     (G      : Graph;
      Source : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural;
      Weight : out Distance_Value)
   is
      Found : Boolean;
   begin
      Validate_Exact_N (G.N);
      Validate_Vertex (G, Source);
      Validate_Path_Bounds (G.N, Path'First, Path'Last);
      Exact_Search
        (G, True, Source, False, Source, Path, Length, Weight, Found);
      pragma Unreferenced (Found);
   end Exact_Simple_Path_From;

   -------------------------------------------------------------------------
   -- Reconstruct_Path
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

end Longest_Path_Problem;
