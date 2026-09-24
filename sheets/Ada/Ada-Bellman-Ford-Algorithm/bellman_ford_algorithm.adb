--  Bellman_Ford_Algorithm body — classic |V|−1 relaxations + cycle pass.

pragma Ada_2022;

package body Bellman_Ford_Algorithm
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

   procedure Validate_Source (G : Graph; Source : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (Source) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Source;

   procedure Validate_Arrays
     (N : Natural;
      Dist_First, Dist_Last : Vertex_Id;
      Prev_First, Prev_Last : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Dist_First /= 1
        or else Natural (Dist_Last) < N
        or else Prev_First /= 1
        or else Natural (Prev_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Arrays;

   -------------------------------------------------------------------------
   -- Safe arithmetic (signed distances; Infinity absorbs)
   -------------------------------------------------------------------------

   function Safe_Add
     (A : Distance_Value; W : Weight_Type) return Distance_Value
   is
      B : constant Distance_Value := Distance_Value (W);
   begin
      if A = Infinity then
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

   -------------------------------------------------------------------------
   -- Core Bellman–Ford
   -------------------------------------------------------------------------

   procedure Run_Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
   is
      N     : constant Natural := G.N;
      E_Idx : Natural;
      V     : Vertex_Id;
      W     : Weight_Type;
      Cand  : Distance_Value;
   begin
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (I) := Infinity;
         Prev (I) := 0;
      end loop;
      Dist (Source) := 0;

      if N >= 2 then
         for Pass in 1 .. N - 1 loop
            declare
               Changed : Boolean := False;
            begin
               for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
                  if Dist (U_Id) /= Infinity then
                     E_Idx := G.Head (U_Id);
                     while E_Idx /= 0 loop
                        V := G.To (E_Idx);
                        W := G.Weight (E_Idx);
                        Cand := Safe_Add (Dist (U_Id), W);
                        if Cand < Dist (V) then
                           Dist (V) := Cand;
                           Prev (V) := Natural (U_Id);
                           Changed := True;
                        end if;
                        E_Idx := G.Next (E_Idx);
                     end loop;
                  end if;
               end loop;
               exit when not Changed;
            end;
         end loop;
      end if;

      --  Extra (Nth) pass: further improvement ⇒ negative cycle from Source.
      Status := Success;
      for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (U_Id) /= Infinity then
            E_Idx := G.Head (U_Id);
            while E_Idx /= 0 loop
               V := G.To (E_Idx);
               W := G.Weight (E_Idx);
               Cand := Safe_Add (Dist (U_Id), W);
               if Cand < Dist (V) then
                  Status := Negative_Cycle;
                  return;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end if;
      end loop;
   end Run_Bellman_Ford;

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      Validate_Source (G, Source);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
   end Shortest_Paths;

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      Status : Run_Status;
   begin
      Shortest_Paths (G, Source, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end Shortest_Paths;

   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean
   is
      Dist   : Distance_Array (Vertex_Id);
      Prev   : Prev_Array (Vertex_Id);
      Status : Run_Status;
   begin
      Validate_Source (G, Source);
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
      return Status = Negative_Cycle;
   end Has_Negative_Cycle;

   procedure Affected_By_Negative_Cycle
     (G        : Graph;
      Source   : Vertex_Id;
      Affected : out Flag_Array;
      Found    : out Boolean)
   is
      N      : constant Natural := G.N;
      Dist   : Distance_Array (Vertex_Id);
      Prev   : Prev_Array (Vertex_Id);
      Status : Run_Status;
      E_Idx  : Natural;
      V      : Vertex_Id;
      W      : Weight_Type;
      Cand   : Distance_Value;
      Changed : Boolean;
   begin
      Validate_Source (G, Source);
      if Affected'First /= 1 or else Natural (Affected'Last) < N then
         raise Invalid_Argument;
      end if;

      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         Affected (I) := False;
      end loop;

      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
      Found := Status = Negative_Cycle;
      if not Found then
         return;
      end if;

      --  Seed: vertices whose Dist can still improve on the Nth pass.
      for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (U_Id) /= Infinity then
            E_Idx := G.Head (U_Id);
            while E_Idx /= 0 loop
               V := G.To (E_Idx);
               W := G.Weight (E_Idx);
               Cand := Safe_Add (Dist (U_Id), W);
               if Cand < Dist (V) then
                  Affected (V) := True;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end if;
      end loop;

      --  Propagate: anything reachable from a seeded vertex is −∞-affected.
      loop
         Changed := False;
         for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
            if Affected (U_Id) then
               E_Idx := G.Head (U_Id);
               while E_Idx /= 0 loop
                  V := G.To (E_Idx);
                  if not Affected (V) then
                     Affected (V) := True;
                     Changed := True;
                  end if;
                  E_Idx := G.Next (E_Idx);
               end loop;
            end if;
         end loop;
         exit when not Changed;
      end loop;
   end Affected_By_Negative_Cycle;

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N      : constant Natural := G.N;
      Dist   : Distance_Array (Vertex_Id);
      Prev   : Prev_Array (Vertex_Id);
      Status : Run_Status;
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
      return Dist (Target);
   end Distance;

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

      if Stack_Top = 0
        or else Stack (Stack_Top) /= Source
      then
         Length := 0;
         return False;
      end if;

      Length := Stack_Top;
      for I in 1 .. Stack_Top loop
         Path (I) := Stack (Stack_Top - I + 1);
      end loop;
      return True;
   end Reconstruct_Path;

end Bellman_Ford_Algorithm;
