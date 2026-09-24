--  Standalone test suite for MaxCliqueDyn (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with MaxCliqueDyn; use MaxCliqueDyn;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Adj_Raises
     (G : Graph; U, V : Vertex_Id) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Adjacent (G, U, V);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Adj_Raises;

   function Set_Size_Raises (N : Natural) return Boolean is
      S : constant Vertex_Set := [others => False];
      Unused : Natural;
   begin
      Unused := Set_Size (S, N);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Size_Raises;

   -------------------------------------------------------------------------
   -- Brute-force ω(G) for N ≤ 12 (enumerate all subsets)
   -------------------------------------------------------------------------

   function Brute_Omega (G : Graph) return Natural is
      N : constant Natural := Vertex_Count (G);
      Best : Natural := 0;

      function Subset_Is_Clique (Mask : Natural) return Boolean is
      begin
         for I in 0 .. N - 1 loop
            if (Mask / (2 ** I)) mod 2 = 1 then
               for J in I + 1 .. N - 1 loop
                  if (Mask / (2 ** J)) mod 2 = 1 then
                     if not Is_Adjacent
                       (G, Vertex_Id (I + 1), Vertex_Id (J + 1))
                     then
                        return False;
                     end if;
                  end if;
               end loop;
            end if;
         end loop;
         return True;
      end Subset_Is_Clique;

      function Pop (Mask : Natural) return Natural is
         X : Natural := Mask;
         C : Natural := 0;
      begin
         while X > 0 loop
            C := C + X mod 2;
            X := X / 2;
         end loop;
         return C;
      end Pop;

   begin
      if N = 0 then
         return 0;
      end if;
      if N > 12 then
         raise Program_Error;
      end if;
      for Mask in 0 .. (2 ** N) - 1 loop
         if Subset_Is_Clique (Mask) then
            declare
               S : constant Natural := Pop (Mask);
            begin
               if S > Best then
                  Best := S;
               end if;
            end;
         end if;
      end loop;
      return Best;
   end Brute_Omega;

   procedure Check_Search
     (G : Graph; Expect : Natural; Label : String)
   is
      Clique : Vertex_Set;
      Size   : Natural;
   begin
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = Expect, Label & " size = expected");
      Check (Set_Size (Clique, Vertex_Count (G)) = Size,
             Label & " Set_Size matches");
      Check (Is_Clique (G, Clique), Label & " result is a clique");
      Check (Maximum_Clique_Size (G) = Expect,
             Label & " Maximum_Clique_Size");
   end Check_Search;

   procedure Check_Vs_Brute (G : Graph; Label : String) is
      B : constant Natural := Brute_Omega (G);
   begin
      Check_Search (G, B, Label & " (brute=" & Natural'Image (B) & ")");
   end Check_Vs_Brute;

   procedure Make_Complete (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Complete;

   procedure Make_Path (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
   end Make_Path;

   procedure Make_Cycle (G : in out Graph; N : Natural) is
   begin
      Make_Path (G, N);
      if N >= 3 then
         Add_Edge (G, Vertex_Id (1), Vertex_Id (N));
      end if;
   end Make_Cycle;

   procedure Make_Star (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
   end Make_Star;

   procedure Make_Bipartite_Complete
     (G : in out Graph; A, B : Natural)
   is
      N : constant Natural := A + B;
   begin
      Clear (G, N);
      for I in 1 .. A loop
         for J in A + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Bipartite_Complete;

   -------------------------------------------------------------------------
   -- 1. Empty / single / no edges
   -------------------------------------------------------------------------

   procedure Test_Trivial is
      G      : Graph;
      Clique : Vertex_Set;
      Size   : Natural;
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 0, "empty ω = 0");
      Check (Maximum_Clique_Size (G) = 0, "empty Maximum_Clique_Size = 0");
      Check (Set_Size (Clique, 0) = 0, "empty clique set empty");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Check (Edge_Count (G) = 0, "single Edge_Count = 0");
      Check_Search (G, 1, "single vertex");

      Clear (G, 5);
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 1, "5 isolates size=1");
      Check (Is_Clique (G, Clique), "isolates result is clique");
      Check (Set_Size (Clique, 5) = 1, "5 isolates Set_Size=1");

      Clear (G, 1);
      Add_Edge (G, 1, 1);
      Check (Edge_Count (G) = 0, "self-loop ignored");
      Check_Search (G, 1, "self-loop only");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Check (Edge_Count (G) = 1, "duplicates ignored → 1 edge");
      Check (Is_Adjacent (G, 1, 2), "adjacent after Add_Edge");
      Check (Is_Adjacent (G, 2, 1), "adjacency symmetric");
      Check (not Is_Adjacent (G, 1, 1), "not adjacent to self");
      Check_Search (G, 2, "single edge K2");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Triangles and small completes
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G : Graph;
   begin
      Section ("2. Triangles and complete Kn");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Check (Edge_Count (G) = 3, "triangle 3 edges");
      Check_Search (G, 3, "triangle K3");
      Check_Vs_Brute (G, "triangle");

      for N in 1 .. 10 loop
         Make_Complete (G, N);
         Check (Edge_Count (G) = N * (N - 1) / 2,
                "K" & Natural'Image (N) & " edge count");
         Check_Search (G, N, "K" & Natural'Image (N));
         Check_Vs_Brute (G, "K" & Natural'Image (N));
      end loop;

      Make_Complete (G, 12);
      Check_Search (G, 12, "K12");
      Check_Vs_Brute (G, "K12");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 3. Paths, cycles, stars
   -------------------------------------------------------------------------

   procedure Test_Sparse is
      G : Graph;
   begin
      Section ("3. Paths / cycles / stars");

      Make_Path (G, 2);
      Check_Search (G, 2, "P2");
      Make_Path (G, 3);
      Check_Search (G, 2, "P3");
      Check_Vs_Brute (G, "P3");
      Make_Path (G, 8);
      Check_Search (G, 2, "P8");
      Check_Vs_Brute (G, "P8");

      Make_Cycle (G, 3);
      Check_Search (G, 3, "C3");
      Make_Cycle (G, 4);
      Check_Search (G, 2, "C4");
      Check_Vs_Brute (G, "C4");
      Make_Cycle (G, 5);
      Check_Search (G, 2, "C5");
      Check_Vs_Brute (G, "C5");
      Make_Cycle (G, 6);
      Check_Search (G, 2, "C6");

      Make_Star (G, 5);
      Check_Search (G, 2, "star S5");
      Check_Vs_Brute (G, "star S5");
      Make_Star (G, 10);
      Check_Search (G, 2, "star S10");
   end Test_Sparse;

   -------------------------------------------------------------------------
   -- 4. Bipartite
   -------------------------------------------------------------------------

   procedure Test_Bipartite is
      G : Graph;
   begin
      Section ("4. Bipartite (ω ≤ 2)");

      Make_Bipartite_Complete (G, 2, 2);
      Check_Search (G, 2, "K2,2");
      Check_Vs_Brute (G, "K2,2");

      Make_Bipartite_Complete (G, 3, 3);
      Check_Search (G, 2, "K3,3");
      Check_Vs_Brute (G, "K3,3");

      Make_Bipartite_Complete (G, 4, 5);
      Check_Search (G, 2, "K4,5");
      Check_Vs_Brute (G, "K4,5");

      --  Path is bipartite
      Make_Path (G, 7);
      Check_Search (G, 2, "P7 bipartite");
   end Test_Bipartite;

   -------------------------------------------------------------------------
   -- 5. Composite / known patterns
   -------------------------------------------------------------------------

   procedure Test_Composite is
      G      : Graph;
      Clique : Vertex_Set;
      Size   : Natural;
   begin
      Section ("5. Composite / known patterns");

      --  Two disjoint edges → ω = 2
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Check_Search (G, 2, "2 disjoint edges");
      Check_Vs_Brute (G, "2 edges");

      --  K4 plus pendant
      Make_Complete (G, 4);
      Clear (G, 5);
      for I in 1 .. 4 loop
         for J in I + 1 .. 4 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      Add_Edge (G, 4, 5);
      Check_Search (G, 4, "K4 + pendant");
      Check_Vs_Brute (G, "K4+pendant");

      --  Two triangles sharing a vertex (bowtie)
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4); Add_Edge (G, 4, 5); Add_Edge (G, 5, 1);
      Check_Search (G, 3, "bowtie");
      Check_Vs_Brute (G, "bowtie");

      --  Wheel W6 = C5 + hub (vertices 1=hub, 2..6 cycle)
      Clear (G, 6);
      for I in 2 .. 6 loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
      for I in 2 .. 5 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 6, 2);
      --  Hub + any edge of the rim → triangle; no K4
      Check_Search (G, 3, "wheel W6");
      Check_Vs_Brute (G, "wheel W6");

      --  Petersen is too big for brute; skip. Small house graph:
      --  square 1-2-3-4-1 with roof 1-5-2
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1); Add_Edge (G, 1, 5); Add_Edge (G, 2, 5);
      Check_Search (G, 3, "house graph");
      Check_Vs_Brute (G, "house");

      --  Clique number of complement of matching
      Clear (G, 6);
      --  Only missing edges: 1-2, 3-4, 5-6 → ω of this = 3 (e.g. 1,3,5)
      for I in 1 .. 6 loop
         for J in I + 1 .. 6 loop
            if not ((I = 1 and J = 2) or else (I = 3 and J = 4)
              or else (I = 5 and J = 6))
            then
               Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
            end if;
         end loop;
      end loop;
      Check_Search (G, 3, "K6 minus matching");
      Check_Vs_Brute (G, "K6-matching");

      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 3, "K6-matching size again");
      Check (Is_Clique (G, Clique), "K6-matching Is_Clique");
   end Test_Composite;

   -------------------------------------------------------------------------
   -- 6. Brute-force battery (n ≤ 12)
   -------------------------------------------------------------------------

   procedure Test_Brute_Battery is
      G : Graph;
   begin
      Section ("6. Brute-force battery n≤12");

      for N in 0 .. 8 loop
         Clear (G, N);
         Check_Vs_Brute (G, "edgeless n=" & Natural'Image (N));
      end loop;

      for N in 3 .. 9 loop
         Make_Path (G, N);
         Check_Vs_Brute (G, "path n=" & Natural'Image (N));
         Make_Cycle (G, N);
         Check_Vs_Brute (G, "cycle n=" & Natural'Image (N));
         Make_Star (G, N);
         Check_Vs_Brute (G, "star n=" & Natural'Image (N));
      end loop;

      --  Random-ish deterministic graphs (fixed edge pattern)
      for N in 4 .. 10 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 7 + J * 3) mod 5) < 2 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern A n=" & Natural'Image (N));
      end loop;

      for N in 4 .. 10 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 5 + J * 11) mod 7) < 3 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern B n=" & Natural'Image (N));
      end loop;

      --  Nested cliques: K3 inside larger sparse
      Clear (G, 8);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5); Add_Edge (G, 6, 7);
      Add_Edge (G, 3, 4); Add_Edge (G, 5, 8);
      Check_Vs_Brute (G, "nested K3 sparse");
   end Test_Brute_Battery;

   -------------------------------------------------------------------------
   -- 7. API / Invalid_Argument / reset
   -------------------------------------------------------------------------

   procedure Test_API is
      G      : Graph;
      Clique : Vertex_Set := [others => False];
      Size   : Natural;
   begin
      Section ("7. API / Invalid_Argument / reset");

      Check (Clear_Raises (Nat (Max_Vertices + 1)),
             "Clear(Max_Vertices+1) raises");
      Check (Clear_Raises (Nat (1000)), "Clear(1000) raises");
      Check (not Clear_Raises (Nat (Max_Vertices)),
             "Clear(Max_Vertices) ok");
      Check (not Clear_Raises (Nat (0)), "Clear(0) ok");

      Clear (G, 3);
      Check (Add_Raises (G, 1, 4), "Add_Edge out of range raises");
      Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
      Check (Adj_Raises (G, 1, 4), "Is_Adjacent out of range");
      Check (Set_Size_Raises (Nat (Max_Vertices + 1)),
             "Set_Size overflow raises");

      Clear (G, 0);
      Check (Add_Raises (G, 1, 2), "Add_Edge on empty raises");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Check (Edge_Count (G) = 1, "before Clear edge=1");
      Clear (G, 4);
      Check (Edge_Count (G) = 0, "after Clear edge=0");
      Check (Vertex_Count (G) = 4, "after Clear N=4");
      Check_Search (G, 1, "after Clear edgeless");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 2, "P3 size 2");
      Check (Set_Size (Clique, 3) = 2, "P3 set size 2");
      --  Exactly one of the two edges should be represented
      declare
         Has12 : constant Boolean := Clique (1) and Clique (2);
         Has23 : constant Boolean := Clique (2) and Clique (3);
         Has13 : constant Boolean := Clique (1) and Clique (3);
      begin
         Check ((Has12 or Has23) and not Has13,
                "P3 clique is an actual edge");
      end;

      Check (Nat (Max_Vertices) = Nat (64), "Max_Vertices = 64");
      Check (Nat (Natural (Vertex_Id'Last)) = Nat (Max_Vertices), "Vertex_Id'Last");
   end Test_API;

   -------------------------------------------------------------------------
   -- 8. Larger educational instances (no brute)
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G : Graph;
   begin
      Section ("8. Larger instances (no brute)");

      Make_Complete (G, 20);
      Check_Search (G, 20, "K20");

      Make_Complete (G, 32);
      Check_Search (G, 32, "K32");

      Make_Path (G, 40);
      Check_Search (G, 2, "P40");

      Make_Star (G, 50);
      Check_Search (G, 2, "S50");

      Make_Bipartite_Complete (G, 10, 10);
      Check_Search (G, 2, "K10,10");

      Make_Cycle (G, 30);
      Check_Search (G, 2, "C30");

      --  Clique of size 8 inside n=40 with sparse extras
      Clear (G, 40);
      for I in 1 .. 8 loop
         for J in I + 1 .. 8 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      for I in 9 .. 39 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 8, 9);
      Check_Search (G, 8, "K8 + path tail");

      Make_Complete (G, 64);
      Check_Search (G, 64, "K64 capacity");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 9. Is_Clique / Set_Size extras
   -------------------------------------------------------------------------

   procedure Test_Helpers is
      G : Graph;
      S : Vertex_Set := [others => False];
   begin
      Section ("9. Is_Clique / Set_Size helpers");

      Make_Complete (G, 4);
      Check (Is_Clique (G, S), "empty set is clique");
      S (1) := True;
      Check (Is_Clique (G, S), "singleton is clique");
      Check (Set_Size (S, 4) = 1, "Set_Size singleton");
      S (2) := True;
      Check (Is_Clique (G, S), "edge is clique in K4");
      S (3) := True;
      S (4) := True;
      Check (Is_Clique (G, S), "all of K4 is clique");
      Check (Set_Size (S, 4) = 4, "Set_Size 4");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      S := [others => False];
      S (1) := True;
      S (2) := True;
      S (3) := True;
      Check (not Is_Clique (G, S), "non-clique detected");
   end Test_Helpers;

begin
   Put_Line ("MaxCliqueDyn Ada 2023 — test suite");
   Put_Line ("Max_Vertices =" & Positive'Image (Max_Vertices));

   Test_Trivial;
   Test_Complete;
   Test_Sparse;
   Test_Bipartite;
   Test_Composite;
   Test_Brute_Battery;
   Test_API;
   Test_Larger;
   Test_Helpers;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
