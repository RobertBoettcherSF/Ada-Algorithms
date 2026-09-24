--  Transitive_Closure body — Warshall + DFS/BFS reachability.

pragma Ada_2022;

package body Transitive_Closure
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Shared validation
   -------------------------------------------------------------------------

   procedure Validate_Vertex (G : Graph; V : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Closure_Bounds
     (N : Natural; First1, Last1, First2, Last2 : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if First1 /= 1
        or else First2 /= 1
        or else Natural (Last1) < N
        or else Natural (Last2) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Closure_Bounds;

   procedure Validate_Square (M : Bool_Matrix) is
   begin
      if M'First (1) /= 1
        or else M'First (2) /= 1
        or else M'Last (1) /= M'Last (2)
        or else Natural (M'Last (1)) < 1
      then
         raise Invalid_Argument;
      end if;
   end Validate_Square;

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
            G.Adj (I, J) := False;
         end loop;
      end loop;
   end Clear;

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id) is
   begin
      Validate_Vertex (G, From);
      Validate_Vertex (G, To);
      if not G.Adj (From, To) then
         G.Adj (From, To) := True;
         G.E := G.E + 1;
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
      Validate_Vertex (G, From);
      Validate_Vertex (G, To);
      return G.Adj (From, To);
   end Has_Edge;

   procedure Relation_Matrix (G : Graph; M : out Bool_Matrix) is
      N : constant Natural := G.N;
   begin
      Validate_Closure_Bounds
        (N, M'First (1), M'Last (1), M'First (2), M'Last (2));
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            M (I, J) := G.Adj (I, J);
         end loop;
      end loop;
   end Relation_Matrix;

   -------------------------------------------------------------------------
   -- Warshall core on a working matrix slice 1 .. N
   -------------------------------------------------------------------------

   procedure Run_Warshall
     (C         : in out Bool_Matrix;
      N         : Positive;
      Reflexive : Boolean)
   is
   begin
      if Reflexive then
         for V in 1 .. Vertex_Id (N) loop
            C (V, V) := True;
         end loop;
      end if;

      for K in 1 .. Vertex_Id (N) loop
         for I in 1 .. Vertex_Id (N) loop
            if C (I, K) then
               for J in 1 .. Vertex_Id (N) loop
                  if C (K, J) then
                     C (I, J) := True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
   end Run_Warshall;

   procedure Init_From_Adj
     (G : Graph; C : out Bool_Matrix; N : Positive)
   is
   begin
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            C (I, J) := G.Adj (I, J);
         end loop;
      end loop;
   end Init_From_Adj;

   procedure Clear_Closure (C : out Bool_Matrix; N : Positive) is
   begin
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            C (I, J) := False;
         end loop;
      end loop;
   end Clear_Closure;

   -------------------------------------------------------------------------
   -- Public Warshall / Closure_Matrix / matrix Warshall
   -------------------------------------------------------------------------

   procedure Warshall
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
   is
      N : constant Natural := G.N;
   begin
      Validate_Closure_Bounds
        (N, Closure'First (1), Closure'Last (1),
         Closure'First (2), Closure'Last (2));
      Init_From_Adj (G, Closure, N);
      Run_Warshall (Closure, N, Reflexive);
   end Warshall;

   procedure Closure_Matrix
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
   is
   begin
      Warshall (G, Closure, Reflexive);
   end Closure_Matrix;

   procedure Warshall_On_Matrix
     (Relation  : Bool_Matrix;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
   is
      N : Natural;
   begin
      Validate_Square (Relation);
      --  Validate Closure bounds via attributes only (out mode).
      if Closure'First (1) /= 1
        or else Closure'First (2) /= 1
        or else Closure'Last (1) /= Closure'Last (2)
        or else Natural (Closure'Last (1)) < 1
      then
         raise Invalid_Argument;
      end if;
      if Relation'Last (1) /= Closure'Last (1)
        or else Relation'Last (2) /= Closure'Last (2)
      then
         raise Invalid_Argument;
      end if;
      N := Natural (Relation'Last (1));
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            Closure (I, J) := Relation (I, J);
         end loop;
      end loop;
      Run_Warshall (Closure, N, Reflexive);
   end Warshall_On_Matrix;

   -------------------------------------------------------------------------
   -- DFS reachability from every source
   -------------------------------------------------------------------------

   procedure Reachability_DFS
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
   is
      N : constant Natural := G.N;

      procedure Explore (Source, U : Vertex_Id;
                         Seen : in out Bool_Matrix) is
         --  Seen(Source, *) tracks visited for this Source's search.
         --  We overload the Closure row as the visited set once marked.
      begin
         for V in 1 .. Vertex_Id (N) loop
            if G.Adj (U, V) and then not Seen (Source, V) then
               Seen (Source, V) := True;
               Explore (Source, V, Seen);
            end if;
         end loop;
      end Explore;

   begin
      Validate_Closure_Bounds
        (N, Closure'First (1), Closure'Last (1),
         Closure'First (2), Closure'Last (2));
      Clear_Closure (Closure, N);

      for S in 1 .. Vertex_Id (N) loop
         Explore (S, S, Closure);
         if Reflexive then
            Closure (S, S) := True;
         end if;
      end loop;
   end Reachability_DFS;

   -------------------------------------------------------------------------
   -- BFS reachability from every source
   -------------------------------------------------------------------------

   procedure Reachability_BFS
     (G         : Graph;
      Closure   : out Bool_Matrix;
      Reflexive : Boolean := False)
   is
      N : constant Natural := G.N;
      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Head, Tail : Natural;
   begin
      Validate_Closure_Bounds
        (N, Closure'First (1), Closure'Last (1),
         Closure'First (2), Closure'Last (2));
      Clear_Closure (Closure, N);

      for S in 1 .. Vertex_Id (N) loop
         Head := 1;
         Tail := 0;
         --  Seed queue with out-neighbours of S (paths of length ≥ 1).
         for V in 1 .. Vertex_Id (N) loop
            if G.Adj (S, V) then
               if not Closure (S, V) then
                  Closure (S, V) := True;
                  Tail := Tail + 1;
                  Queue (Tail) := V;
               end if;
            end if;
         end loop;

         while Head <= Tail loop
            declare
               U : constant Vertex_Id := Queue (Head);
            begin
               Head := Head + 1;
               for V in 1 .. Vertex_Id (N) loop
                  if G.Adj (U, V) and then not Closure (S, V) then
                     Closure (S, V) := True;
                     Tail := Tail + 1;
                     Queue (Tail) := V;
                  end if;
               end loop;
            end;
         end loop;

         if Reflexive then
            Closure (S, S) := True;
         end if;
      end loop;
   end Reachability_BFS;

   -------------------------------------------------------------------------
   -- Single-pair reachability (DFS)
   -------------------------------------------------------------------------

   function Reaches
     (G         : Graph;
      From, To  : Vertex_Id;
      Reflexive : Boolean := False) return Boolean
   is
      N : constant Natural := G.N;
      Visited : array (Vertex_Id) of Boolean := [others => False];
      Found   : Boolean := False;

      procedure Visit (U : Vertex_Id) is
      begin
         if Found then
            return;
         end if;
         for V in 1 .. Vertex_Id (N) loop
            if G.Adj (U, V) and then not Visited (V) then
               Visited (V) := True;
               if V = To then
                  Found := True;
                  return;
               end if;
               Visit (V);
               if Found then
                  return;
               end if;
            end if;
         end loop;
      end Visit;

   begin
      Validate_Vertex (G, From);
      Validate_Vertex (G, To);
      if Reflexive and then From = To then
         return True;
      end if;
      Visit (From);
      return Found;
   end Reaches;

   -------------------------------------------------------------------------
   -- Transitivity check on a relation matrix
   -------------------------------------------------------------------------

   function Is_Transitive (M : Bool_Matrix; N : Natural) return Boolean is
   begin
      if N = 0
        or else M'First (1) /= 1
        or else M'First (2) /= 1
        or else Natural (M'Last (1)) < N
        or else Natural (M'Last (2)) < N
      then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Vertex_Id (N) loop
         for J in 1 .. Vertex_Id (N) loop
            if M (I, J) then
               for K in 1 .. Vertex_Id (N) loop
                  if M (J, K) and then not M (I, K) then
                     return False;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Transitive;

end Transitive_Closure;
