--  Uniform_Cost_Search body — SPARK Level 4 Graph-Search UCS on a static
--  CSR digraph. Helpers keep safe add, unsettled-set scan, edge relax,
--  and path reconstruction VCs modular. Found ⇒ Dist(Target) < Infinity
--  and a Source→Target path shape are proved; full optimality is left to
--  tests. Zero Intentional Annotate. Non-negative weights ⇒ settle once
--  (explored set; no reopen). Equivalent to dense Dijkstra point-to-point.

package body Uniform_Cost_Search
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
      G.Weight := [others => 0];
      G.Next := [others => 0];
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Weight_Type)
   is
   begin
      G.E := G.E + 1;
      G.To (G.E) := To;
      G.Weight (G.E) := Weight;
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
   end Add_Edge;

   -------------------------------------------------------------------------
   -- Safe distance arithmetic (never wraps past Infinity)
   -------------------------------------------------------------------------

   function Safe_Add
     (A : Distance_Value; W : Weight_Type) return Distance_Value
   with
     Global => null,
     Post   =>
       Safe_Add'Result <= Infinity
       and then (if A < Infinity - Distance_Value (W) then
                   Safe_Add'Result = A + Distance_Value (W)
                 else
                   Safe_Add'Result = Infinity)
   is
      Wd : constant Distance_Value := Distance_Value (W);
   begin
      if A >= Infinity - Wd then
         return Infinity;
      end if;
      return A + Wd;
   end Safe_Add;

   -------------------------------------------------------------------------
   -- Reconstruct_Path
   -------------------------------------------------------------------------

   procedure Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
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

      if Source = Target then
         if Prev (Source) = 0 then
            Path (1) := Source;
            Length := 1;
            Ok := True;
         end if;
         return;
      end if;

      U := Natural (Target);

      for Guard in 1 .. N loop
         pragma Loop_Invariant (Stack_Top < Guard);
         pragma Loop_Invariant (Stack_Top <= Max_Vertices);
         pragma Loop_Invariant (U <= N);
         pragma Loop_Invariant (Path'Initialized);
         pragma Loop_Invariant
           (for all K in 1 .. Stack_Top => Natural (Stack (K)) <= N);
         --  Before any push, U is still Target; after, Stack(1) holds it.
         pragma Loop_Invariant
           (if Stack_Top = 0 then U = Natural (Target));
         pragma Loop_Invariant
           (if Stack_Top >= 1 then Stack (1) = Target);

         exit when U = 0;

         if Stack_Top >= Max_Vertices then
            Length := 0;
            Ok := False;
            return;
         end if;

         pragma Assert
           (if Stack_Top = 0 then U = Natural (Target));
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := Vertex_Id (U);
         pragma Assert (if Stack_Top = 1 then Stack (1) = Target);

         if Vertex_Id (U) = Source then
            Length := Stack_Top;
            pragma Assert (Stack_Top >= 1);
            pragma Assert (Stack (Stack_Top) = Source);
            for I in 1 .. Stack_Top loop
               pragma Loop_Invariant (Path'Initialized);
               pragma Loop_Invariant (Length = Stack_Top);
               pragma Loop_Invariant (Stack_Top in 1 .. N);
               pragma Loop_Invariant (Stack (Stack_Top) = Source);
               Path (I) := Stack (Stack_Top - I + 1);
            end loop;
            --  Ends fixed explicitly so Post does not depend on reverse VCs.
            Path (1) := Source;
            Path (Length) := Target;
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
   -- Search (Graph-Search UCS ≡ dense Dijkstra)
   -------------------------------------------------------------------------

   procedure Search
     (G      : Graph;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Path   : out Path_Array;
      Length : out Natural;
      Found  : out Boolean)
   is
      N : constant Vertex_Count_T := G.N;

      Settled : array (Vertex_Id) of Boolean := [others => False];

      Max_Steps : constant Positive := Max_Vertices;
   begin
      for I in Dist'Range loop
         Dist (I) := Infinity;
         pragma Loop_Invariant
           (for all K in Dist'First .. I => Dist (K)'Initialized);
      end loop;
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
      pragma Assert (Dist'Initialized);
      pragma Assert (Prev'Initialized);
      pragma Assert (Path'Initialized);

      Length := 0;
      Found := False;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         pragma Loop_Invariant (Dist'Initialized);
         pragma Loop_Invariant (Prev'Initialized);
         pragma Loop_Invariant
           (for all K in Vertex_Id range 1 .. V =>
              (if K < V then Prev (K) = 0));
         Dist (V) := Infinity;
         Prev (V) := 0;
         Settled (V) := False;
      end loop;
      Dist (Source) := 0;
      pragma Assert
        (for all V in Vertex_Id range 1 .. Vertex_Id (N) => Prev (V) = 0);

      if Source = Target then
         Found := True;
         Length := 1;
         Path (1) := Source;
         return;
      end if;

      for Step in 1 .. Max_Steps loop
         pragma Loop_Invariant (Dist'Initialized);
         pragma Loop_Invariant (Prev'Initialized);
         pragma Loop_Invariant (Path'Initialized);
         pragma Loop_Invariant (Dist (Source) = 0);
         pragma Loop_Invariant (Length = 0);
         pragma Loop_Invariant (not Found);
         pragma Loop_Invariant
           (for all V in Vertex_Id range 1 .. Vertex_Id (N) =>
              Prev (V) <= N);

         declare
            U          : Vertex_Id := Source;
            Best       : Distance_Value := Infinity;
            Found_Open : Boolean := False;
            E_Idx      : Natural;
            W_Vert     : Vertex_Id;
            Alt        : Distance_Value;
            Recon_Ok   : Boolean;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               pragma Loop_Invariant (Dist'Initialized);
               pragma Loop_Invariant (Prev'Initialized);
               pragma Loop_Invariant (Dist (Source) = 0);
               pragma Loop_Invariant
                 (if Found_Open then Natural (U) <= N
                    and then Dist (U) < Infinity
                    and then Dist (U) = Best);

               if not Settled (V) and then Dist (V) < Infinity then
                  if not Found_Open or else Dist (V) < Best then
                     Best := Dist (V);
                     U := V;
                     Found_Open := True;
                  elsif Dist (V) = Best and then V < U then
                     U := V;
                  end if;
               end if;
            end loop;

            if not Found_Open then
               exit;
            end if;

            pragma Assert (Natural (U) <= N);
            pragma Assert (Dist (U) < Infinity);
            pragma Assert (Dist (U) = Best);

            Settled (U) := True;

            if U = Target then
               Reconstruct_Path
                 (Prev, Source, Target, N, Path, Length, Recon_Ok);
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
               pragma Loop_Invariant (Dist'Initialized);
               pragma Loop_Invariant (Prev'Initialized);
               pragma Loop_Invariant (Dist (Source) = 0);
               pragma Loop_Invariant (E_Idx <= G.E);
               pragma Loop_Invariant
                 (for all V in Vertex_Id range 1 .. Vertex_Id (N) =>
                    Prev (V) <= N);
               pragma Loop_Invariant (not Found);
               pragma Loop_Invariant (Length = 0);

               exit when E_Idx = 0;

               W_Vert := G.To (E_Idx);
               if not Settled (W_Vert) then
                  Alt := Safe_Add (Dist (U), G.Weight (E_Idx));
                  if Alt < Dist (W_Vert) then
                     Dist (W_Vert) := Alt;
                     Prev (W_Vert) := Natural (U);
                  end if;
               end if;

               E_Idx := G.Next (E_Idx);
            end loop;
         end;
      end loop;

      Length := 0;
      Found := False;
   end Search;

end Uniform_Cost_Search;
