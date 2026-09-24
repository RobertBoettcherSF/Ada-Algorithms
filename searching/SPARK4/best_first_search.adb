--  Best_First_Search body — SPARK Level 4 dense open-set greedy BeFS on a
--  static unweighted CSR digraph. Helpers keep open-set scan, edge walk,
--  and path reconstruction VCs modular. Found ⇒ Start→Goal path shape is
--  proved; optimality is NOT claimed. Zero Intentional Annotate.
--  Dense O(V) min-H scan replaces the non-SPARK sibling's binary heap.

package body Best_First_Search
  with SPARK_Mode => On
is

   -------------------------------------------------------------------------
   -- Clear / Add_Edge
   -------------------------------------------------------------------------

   procedure Clear (G : out Graph; Vertex_Count : Vertex_Count_T) is
   begin
      G.N := Vertex_Count;
      G.E := 0;
      G.Head := [others => 0];
      G.To := [others => Vertex_Id'First];
      G.Next := [others => 0];
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id)
   is
   begin
      G.E := G.E + 1;
      G.To (G.E) := To;
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
   end Add_Edge;

   -------------------------------------------------------------------------
   -- Reconstruct_Path
   -------------------------------------------------------------------------

   procedure Reconstruct_Path
     (Prev   : Prev_Array;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      N      : Vertex_Count_T;
      Path   : out Path_Array;
      Length : out Natural;
      Ok     : out Boolean)
   is
      Stack     : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top : Natural := 0;
      U         : Natural;
   begin
      for I in Path'Range loop
         Path (I) := Vertex_Id'First;
         pragma Loop_Invariant
           (for all K in Path'First .. I => Path (K)'Initialized);
      end loop;
      pragma Assert (Path'Initialized);

      Length := 0;
      Ok := False;

      if Start = Goal then
         if Prev (Start) = 0 then
            Path (1) := Start;
            Length := 1;
            Ok := True;
         end if;
         return;
      end if;

      U := Natural (Goal);

      for Guard in 1 .. N loop
         pragma Loop_Invariant (Stack_Top < Guard);
         pragma Loop_Invariant (Stack_Top <= Max_Vertices);
         pragma Loop_Invariant (U <= N);
         pragma Loop_Invariant (Path'Initialized);
         pragma Loop_Invariant
           (for all K in 1 .. Stack_Top => Natural (Stack (K)) <= N);
         --  Before any push, U is still Goal; after, Stack(1) holds it.
         pragma Loop_Invariant
           (if Stack_Top = 0 then U = Natural (Goal));
         pragma Loop_Invariant
           (if Stack_Top >= 1 then Stack (1) = Goal);

         exit when U = 0;

         if Stack_Top >= Max_Vertices then
            Length := 0;
            Ok := False;
            return;
         end if;

         pragma Assert
           (if Stack_Top = 0 then U = Natural (Goal));
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := Vertex_Id (U);
         pragma Assert (if Stack_Top = 1 then Stack (1) = Goal);

         if Vertex_Id (U) = Start then
            Length := Stack_Top;
            pragma Assert (Stack_Top >= 1);
            pragma Assert (Stack (Stack_Top) = Start);
            for I in 1 .. Stack_Top loop
               pragma Loop_Invariant (Path'Initialized);
               pragma Loop_Invariant (Length = Stack_Top);
               pragma Loop_Invariant (Stack_Top in 1 .. N);
               pragma Loop_Invariant (Stack (Stack_Top) = Start);
               Path (I) := Stack (Stack_Top - I + 1);
            end loop;
            --  Ends fixed explicitly so Post does not depend on reverse VCs.
            Path (1) := Start;
            Path (Length) := Goal;
            Ok := True;
            return;
         end if;

         U := Prev (Vertex_Id (U));
         if U > N then
            Length := 0;
            Ok := False;
            return;
         end if;
      end loop;

      Length := 0;
      Ok := False;
   end Reconstruct_Path;

   -------------------------------------------------------------------------
   -- Search (dense greedy best-first)
   -------------------------------------------------------------------------

   procedure Search
     (G              : Graph;
      Start          : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
   is
      N : constant Vertex_Count_T := G.N;

      Open    : array (Vertex_Id) of Boolean := [others => False];
      Visited : array (Vertex_Id) of Boolean := [others => False];

      Max_Steps : constant Positive := Max_Vertices;
   begin
      for I in Prev'Range loop
         Prev (I) := 0;
         pragma Loop_Invariant
           (for all K in Prev'First .. I => Prev (K)'Initialized);
      end loop;
      for I in Path'Range loop
         Path (I) := Vertex_Id'First;
         pragma Loop_Invariant
           (for all K in Path'First .. I => Path (K)'Initialized);
      end loop;
      pragma Assert (Prev'Initialized);
      pragma Assert (Path'Initialized);

      Length := 0;
      Found := False;
      Nodes_Expanded := 0;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         pragma Loop_Invariant (Prev'Initialized);
         pragma Loop_Invariant
           (for all K in Vertex_Id range 1 .. V =>
              (if K < V then Prev (K) = 0));
         Prev (V) := 0;
         Open (V) := False;
         Visited (V) := False;
      end loop;
      pragma Assert
        (for all V in Vertex_Id range 1 .. Vertex_Id (N) => Prev (V) = 0);

      if Start = Goal then
         Found := True;
         Length := 1;
         Path (1) := Start;
         Nodes_Expanded := 0;
         return;
      end if;

      Visited (Start) := True;
      Open (Start) := True;
      Prev (Start) := 0;

      for Step in 1 .. Max_Steps loop
         pragma Loop_Invariant (Prev'Initialized);
         pragma Loop_Invariant (Path'Initialized);
         pragma Loop_Invariant (Nodes_Expanded < Step);
         pragma Loop_Invariant (Nodes_Expanded <= Max_Steps);
         pragma Loop_Invariant (Length = 0);
         pragma Loop_Invariant (not Found);
         pragma Loop_Invariant (Visited (Start));
         pragma Loop_Invariant
           (for all V in Vertex_Id range 1 .. Vertex_Id (N) =>
              Prev (V) <= N);

         declare
            U          : Vertex_Id := Start;
            Best       : Heuristic_Value := Heuristic_Value'Last;
            Found_Open : Boolean := False;
            E_Idx      : Natural;
            W_Vert     : Vertex_Id;
            Recon_Ok   : Boolean;
            Hv         : Heuristic_Value;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               pragma Loop_Invariant (Prev'Initialized);
               pragma Loop_Invariant
                 (if Found_Open then Natural (U) <= N
                    and then Open (U));

               if Open (V) then
                  Hv := Heuristic (V);
                  if not Found_Open or else Hv < Best then
                     Best := Hv;
                     U := V;
                     Found_Open := True;
                  elsif Hv = Best and then V < U then
                     U := V;
                  end if;
               end if;
            end loop;

            if not Found_Open then
               exit;
            end if;

            pragma Assert (Natural (U) <= N);
            pragma Assert (Open (U));

            Open (U) := False;
            Nodes_Expanded := Nodes_Expanded + 1;

            if U = Goal then
               Reconstruct_Path
                 (Prev, Start, Goal, N, Path, Length, Recon_Ok);
               if Recon_Ok then
                  Found := True;
               else
                  Length := 0;
                  Found := False;
               end if;
               return;
            end if;

            E_Idx := G.Head (U);
            for Edge_Guard in 1 .. Max_Edges loop
               pragma Loop_Invariant (Prev'Initialized);
               pragma Loop_Invariant (E_Idx <= G.E);
               pragma Loop_Invariant
                 (for all V in Vertex_Id range 1 .. Vertex_Id (N) =>
                    Prev (V) <= N);
               pragma Loop_Invariant
                 (Nodes_Expanded = Nodes_Expanded'Loop_Entry);
               pragma Loop_Invariant (not Found);
               pragma Loop_Invariant (Length = 0);
               pragma Loop_Invariant (Visited (Start));

               exit when E_Idx = 0;

               W_Vert := G.To (E_Idx);
               if not Visited (W_Vert) then
                  Visited (W_Vert) := True;
                  Prev (W_Vert) := Natural (U);
                  Open (W_Vert) := True;
               end if;

               E_Idx := G.Next (E_Idx);
            end loop;
         end;
      end loop;

      Length := 0;
      Found := False;
   end Search;

end Best_First_Search;
