--  Standalone test suite for Cliques (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Cliques; use Cliques;

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
   -- Brute-force helpers for N ≤ 10 / 12
   -------------------------------------------------------------------------

   function Bit (Mask, I : Natural) return Boolean is
     ((Mask / (2 ** I)) mod 2 = 1);

   function Brute_Maximal_Count (G : Graph) return Natural is
      N     : constant Natural := Vertex_Count (G);
      Total : Natural := 0;

      function Subset_Is_Clique (Mask : Natural) return Boolean is
      begin
         for I in 0 .. N - 1 loop
            if Bit (Mask, I) then
               for J in I + 1 .. N - 1 loop
                  if Bit (Mask, J) then
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

      function Is_Maximal_Mask (Mask : Natural) return Boolean is
      begin
         if Mask = 0 then
            return False;
         end if;
         if not Subset_Is_Clique (Mask) then
            return False;
         end if;
         for V in 0 .. N - 1 loop
            if not Bit (Mask, V) then
               declare
                  Ok : Boolean := True;
               begin
                  for U in 0 .. N - 1 loop
                     if Bit (Mask, U) then
                        if not Is_Adjacent
                          (G, Vertex_Id (U + 1), Vertex_Id (V + 1))
                        then
                           Ok := False;
                           exit;
                        end if;
                     end if;
                  end loop;
                  if Ok then
                     return False;
                  end if;
               end;
            end if;
         end loop;
         return True;
      end Is_Maximal_Mask;

   begin
      if N = 0 then
         return 0;
      end if;
      if N > 10 then
         raise Program_Error;
      end if;
      for Mask in 0 .. (2 ** N) - 1 loop
         if Is_Maximal_Mask (Mask) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Brute_Maximal_Count;

   function Brute_Omega (G : Graph) return Natural is
      N     : constant Natural := Vertex_Count (G);
      Best  : Natural := 0;
      Size  : Natural;

      function Subset_Is_Clique (Mask : Natural) return Boolean is
      begin
         for I in 0 .. N - 1 loop
            if Bit (Mask, I) then
               for J in I + 1 .. N - 1 loop
                  if Bit (Mask, J) then
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
         M : Natural := Mask;
         C : Natural := 0;
      begin
         while M > 0 loop
            C := C + M mod 2;
            M := M / 2;
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
            Size := Pop (Mask);
            if Size > Best then
               Best := Size;
            end if;
         end if;
      end loop;
      return Best;
   end Brute_Omega;

   function Clique_To_Mask (S : Vertex_Set; N : Natural) return Natural is
      M : Natural := 0;
   begin
      for I in 1 .. N loop
         if S (Vertex_Id (I)) then
            M := M + 2 ** (I - 1);
         end if;
      end loop;
      return M;
   end Clique_To_Mask;

   procedure Check_Enumeration
     (G : Graph; Expect : Natural; Label : String)
   is
      Cliques : Clique_List;
      Count   : Natural;
      N       : constant Natural := Vertex_Count (G);
      Seen    : array (0 .. 2 ** 10 - 1) of Boolean := [others => False];
   begin
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = Expect, Label & " count = expected");
      Check (Maximal_Clique_Count (G) = Expect,
             Label & " Maximal_Clique_Count");

      for K in 1 .. Count loop
         Check (Is_Clique (G, Cliques.Items (K)),
                Label & " clique" & Natural'Image (K) & " Is_Clique");
         Check (Is_Maximal_Clique (G, Cliques.Items (K)),
                Label & " clique" & Natural'Image (K) & " maximal");
         Check (Set_Size (Cliques.Items (K), N) >= 1 or else N = 0,
                Label & " clique" & Natural'Image (K) & " nonempty");
      end loop;

      if N <= 10 and then Count <= Expect then
         for K in 1 .. Count loop
            declare
               M : constant Natural := Clique_To_Mask (Cliques.Items (K), N);
            begin
               Check (not Seen (M),
                      Label & " unique mask" & Natural'Image (M));
               Seen (M) := True;
            end;
         end loop;
      end if;
   end Check_Enumeration;

   procedure Check_Vs_Brute (G : Graph; Label : String) is
      B : constant Natural := Brute_Maximal_Count (G);
   begin
      Check_Enumeration
        (G, B, Label & " (brute=" & Natural'Image (B) & ")");
   end Check_Vs_Brute;

   --  ω(G) equals max size over enumerated maximal cliques
   procedure Check_Omega_Consistency (G : Graph; Label : String) is
      Cliques : Clique_List;
      Count   : Natural;
      N       : constant Natural := Vertex_Count (G);
      Max_Sz  : Natural := 0;
      Omega   : Natural;
      Clique  : Vertex_Set;
      Size    : Natural;
      Sz      : Natural;
   begin
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      for K in 1 .. Count loop
         Sz := Set_Size (Cliques.Items (K), N);
         if Sz > Max_Sz then
            Max_Sz := Sz;
         end if;
      end loop;

      Omega := Clique_Number (G);
      Find_Maximum_Clique (G, Clique, Size);

      Check (Omega = Max_Sz,
             Label & " Clique_Number = max maximal size");
      Check (Size = Omega, Label & " Find_Maximum_Clique Size = ω");
      Check (Set_Size (Clique, N) = Size,
             Label & " reported clique Set_Size = Size");
      Check (Is_Clique (G, Clique) or else Size = 0,
             Label & " reported set Is_Clique");
      if Size > 0 then
         Check (Is_Maximal_Clique (G, Clique),
                Label & " reported set is maximal");
      end if;
   end Check_Omega_Consistency;

   procedure Check_Omega_Brute (G : Graph; Label : String) is
      B : constant Natural := Brute_Omega (G);
   begin
      Check (Clique_Number (G) = B,
             Label & " Clique_Number = brute ω" & Natural'Image (B));
      Check_Omega_Consistency (G, Label);
   end Check_Omega_Brute;

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
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
      Clique  : Vertex_Set;
      Size    : Natural;
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 0, "empty Count = 0");
      Check (Maximal_Clique_Count (G) = 0, "empty Maximal_Clique_Count = 0");
      Check (Clique_Number (G) = 0, "empty Clique_Number = 0");
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 0, "empty Find_Maximum_Clique Size = 0");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Check (Edge_Count (G) = 0, "single Edge_Count = 0");
      Check_Enumeration (G, 1, "single vertex");
      Check (Clique_Number (G) = 1, "single Clique_Number = 1");
      Check_Omega_Consistency (G, "single");

      Clear (G, 5);
      Check_Enumeration (G, 5, "5 isolates");
      Check (Clique_Number (G) = 1, "5 isolates ω = 1");
      Check_Omega_Consistency (G, "5 isolates");

      Clear (G, 1);
      Add_Edge (G, 1, 1);
      Check (Edge_Count (G) = 0, "self-loop ignored");
      Check_Enumeration (G, 1, "self-loop only");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Check (Edge_Count (G) = 1, "duplicates ignored → 1 edge");
      Check (Is_Adjacent (G, 1, 2), "adjacent after Add_Edge");
      Check (Is_Adjacent (G, 2, 1), "adjacency symmetric");
      Check (not Is_Adjacent (G, 1, 1), "not adjacent to self");
      Check_Enumeration (G, 1, "single edge K2 → 1 maximal clique");
      Check (Clique_Number (G) = 2, "K2 Clique_Number = 2");
      Check_Omega_Consistency (G, "K2");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Triangles and complete Kn
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("2. Triangles and complete Kn");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Check (Edge_Count (G) = 3, "triangle 3 edges");
      Check_Enumeration (G, 1, "triangle K3 → 1 clique");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 1
             and then Cliques.Items (1) (1)
             and then Cliques.Items (1) (2)
             and then Cliques.Items (1) (3),
             "triangle clique is {1,2,3}");
      Check_Vs_Brute (G, "triangle");
      Check (Clique_Number (G) = 3, "triangle ω = 3");
      Check_Omega_Consistency (G, "triangle");

      for N in 1 .. 8 loop
         Make_Complete (G, N);
         Check (Edge_Count (G) = N * (N - 1) / 2,
                "K" & Natural'Image (N) & " edge count");
         Check_Enumeration (G, 1, "K" & Natural'Image (N) & " → 1 clique");
         Enumerate_Maximal_Cliques (G, Cliques, Count);
         Check (Set_Size (Cliques.Items (1), N) = N,
                "K" & Natural'Image (N) & " clique size = N");
         Check (Clique_Number (G) = N,
                "K" & Natural'Image (N) & " Clique_Number = N");
         Check_Omega_Consistency (G, "K" & Natural'Image (N));
         Check_Vs_Brute (G, "K" & Natural'Image (N));
      end loop;

      Make_Complete (G, 12);
      Check_Enumeration (G, 1, "K12 → 1 clique");
      Check (Clique_Number (G) = 12, "K12 Clique_Number = 12");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 3. Paths, cycles, stars
   -------------------------------------------------------------------------

   procedure Test_Sparse is
      G : Graph;
   begin
      Section ("3. Paths / cycles / stars");

      Make_Path (G, 2);
      Check_Enumeration (G, 1, "P2");
      Check (Clique_Number (G) = 2, "P2 ω = 2");
      Make_Path (G, 3);
      Check_Enumeration (G, 2, "P3 → 2 edges");
      Check_Vs_Brute (G, "P3");
      Check (Clique_Number (G) = 2, "P3 ω = 2");
      Check_Omega_Consistency (G, "P3");
      Make_Path (G, 8);
      Check_Enumeration (G, 7, "P8 → 7 edges");
      Check_Vs_Brute (G, "P8");
      Check (Clique_Number (G) = 2, "P8 ω = 2");
      Check_Omega_Consistency (G, "P8");

      Make_Cycle (G, 3);
      Check_Enumeration (G, 1, "C3 → 1 triangle");
      Check (Clique_Number (G) = 3, "C3 ω = 3");
      Make_Cycle (G, 4);
      Check_Enumeration (G, 4, "C4 → 4 edges");
      Check_Vs_Brute (G, "C4");
      Check (Clique_Number (G) = 2, "C4 ω = 2");
      Check_Omega_Consistency (G, "C4");
      Make_Cycle (G, 5);
      Check_Enumeration (G, 5, "C5 → 5 edges");
      Check_Vs_Brute (G, "C5");
      Check (Clique_Number (G) = 2, "C5 ω = 2");
      Make_Cycle (G, 6);
      Check_Enumeration (G, 6, "C6 → 6 edges");
      Check (Clique_Number (G) = 2, "C6 ω = 2");

      Make_Star (G, 5);
      Check_Enumeration (G, 4, "star S5 → 4 edges");
      Check_Vs_Brute (G, "star S5");
      Check (Clique_Number (G) = 2, "star S5 ω = 2");
      Check_Omega_Consistency (G, "star S5");
      Make_Star (G, 10);
      Check_Enumeration (G, 9, "star S10 → 9 edges");
      Check (Clique_Number (G) = 2, "star S10 ω = 2");
   end Test_Sparse;

   -------------------------------------------------------------------------
   -- 4. Bipartite
   -------------------------------------------------------------------------

   procedure Test_Bipartite is
      G : Graph;
   begin
      Section ("4. Bipartite (edges as maximal cliques)");

      Make_Bipartite_Complete (G, 2, 2);
      Check_Enumeration (G, 4, "K2,2 → 4 edges");
      Check_Vs_Brute (G, "K2,2");
      Check (Clique_Number (G) = 2, "K2,2 ω = 2");
      Check_Omega_Consistency (G, "K2,2");

      Make_Bipartite_Complete (G, 3, 3);
      Check_Enumeration (G, 9, "K3,3 → 9 edges");
      Check_Vs_Brute (G, "K3,3");
      Check (Clique_Number (G) = 2, "K3,3 ω = 2");
      Check_Omega_Consistency (G, "K3,3");

      Make_Bipartite_Complete (G, 2, 4);
      Check_Enumeration (G, 8, "K2,4 → 8 edges");
      Check_Vs_Brute (G, "K2,4");
      Check (Clique_Number (G) = 2, "K2,4 ω = 2");

      Make_Path (G, 7);
      Check_Enumeration (G, 6, "P7 bipartite → 6 edges");
      Check (Clique_Number (G) = 2, "P7 ω = 2");
   end Test_Bipartite;

   -------------------------------------------------------------------------
   -- 5. Composite / known patterns
   -------------------------------------------------------------------------

   procedure Test_Composite is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("5. Composite / known patterns");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Check_Enumeration (G, 2, "2 disjoint edges");
      Check_Vs_Brute (G, "2 edges");
      Check (Clique_Number (G) = 2, "2 edges ω = 2");
      Check_Omega_Consistency (G, "2 edges");

      --  Bowtie
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4); Add_Edge (G, 4, 5); Add_Edge (G, 5, 1);
      Check_Enumeration (G, 2, "bowtie → 2 triangles");
      Check_Vs_Brute (G, "bowtie");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 2, "bowtie count again");
      Check (Set_Size (Cliques.Items (1), 5) = 3
             and then Set_Size (Cliques.Items (2), 5) = 3,
             "bowtie both size 3");
      Check (Clique_Number (G) = 3, "bowtie ω = 3");
      Check_Omega_Consistency (G, "bowtie");

      --  Two triangles sharing an edge
      Clear (G, 4);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4); Add_Edge (G, 4, 3);
      Check_Enumeration (G, 2, "diamond minus edge → 2 triangles");
      Check_Vs_Brute (G, "2 tri share edge");
      Check (Clique_Number (G) = 3, "2 tri share edge ω = 3");
      Check_Omega_Consistency (G, "2 tri share edge");

      --  K4 + pendant
      Clear (G, 5);
      for I in 1 .. 4 loop
         for J in I + 1 .. 4 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      Add_Edge (G, 4, 5);
      Check_Enumeration (G, 2, "K4 + pendant → 2 maximal");
      Check_Vs_Brute (G, "K4+pendant");
      Check (Clique_Number (G) = 4, "K4+pendant ω = 4");
      Check_Omega_Consistency (G, "K4+pendant");

      --  House
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1); Add_Edge (G, 1, 5); Add_Edge (G, 2, 5);
      Check_Vs_Brute (G, "house");
      Check_Omega_Brute (G, "house");

      --  Wheel W6 = C5 + hub
      Clear (G, 6);
      for I in 2 .. 6 loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
      for I in 2 .. 5 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 6, 2);
      Check_Enumeration (G, 5, "wheel W6 → 5 triangles");
      Check_Vs_Brute (G, "wheel W6");
      Check (Clique_Number (G) = 3, "wheel W6 ω = 3");
      Check_Omega_Consistency (G, "wheel W6");

      --  Disjoint K3 ∪ K3
      Clear (G, 6);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5); Add_Edge (G, 5, 6); Add_Edge (G, 6, 4);
      Check_Enumeration (G, 2, "2 disjoint triangles");
      Check_Vs_Brute (G, "2 K3");
      Check (Clique_Number (G) = 3, "2 K3 ω = 3");
      Check_Omega_Consistency (G, "2 K3");

      --  K3 + isolate
      Clear (G, 4);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Check_Enumeration (G, 2, "K3 + isolate");
      Check_Vs_Brute (G, "K3+isolate");
      Check (Clique_Number (G) = 3, "K3+isolate ω = 3");
      Check_Omega_Consistency (G, "K3+isolate");

      --  Maximal ≠ maximum: K4 plus a disjoint edge
      Clear (G, 6);
      for I in 1 .. 4 loop
         for J in I + 1 .. 4 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      Add_Edge (G, 5, 6);
      Check_Enumeration (G, 2, "K4 ∪ K2 → 2 maximal");
      Check (Clique_Number (G) = 4, "K4 ∪ K2 ω = 4 (not 2)");
      Check_Omega_Consistency (G, "K4 ∪ K2");
   end Test_Composite;

   -------------------------------------------------------------------------
   -- 6. Brute-force battery (enumeration + ω)
   -------------------------------------------------------------------------

   procedure Test_Brute_Battery is
      G : Graph;
   begin
      Section ("6. Brute-force battery n≤10");

      for N in 0 .. 8 loop
         Clear (G, N);
         Check_Vs_Brute (G, "edgeless n=" & Natural'Image (N));
         Check_Omega_Brute (G, "edgeless n=" & Natural'Image (N));
      end loop;

      for N in 3 .. 9 loop
         Make_Path (G, N);
         Check_Vs_Brute (G, "path n=" & Natural'Image (N));
         Check_Omega_Brute (G, "path n=" & Natural'Image (N));
         Make_Cycle (G, N);
         Check_Vs_Brute (G, "cycle n=" & Natural'Image (N));
         Check_Omega_Brute (G, "cycle n=" & Natural'Image (N));
         Make_Star (G, N);
         Check_Vs_Brute (G, "star n=" & Natural'Image (N));
         Check_Omega_Brute (G, "star n=" & Natural'Image (N));
      end loop;

      for N in 4 .. 9 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 7 + J * 3) mod 5) < 2 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern A n=" & Natural'Image (N));
         Check_Omega_Brute (G, "pattern A n=" & Natural'Image (N));
      end loop;

      for N in 4 .. 9 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 5 + J * 11) mod 7) < 3 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern B n=" & Natural'Image (N));
         Check_Omega_Brute (G, "pattern B n=" & Natural'Image (N));
      end loop;

      Clear (G, 8);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5); Add_Edge (G, 6, 7);
      Add_Edge (G, 3, 4); Add_Edge (G, 5, 8);
      Check_Vs_Brute (G, "nested K3 sparse");
      Check_Omega_Brute (G, "nested K3 sparse");
   end Test_Brute_Battery;

   -------------------------------------------------------------------------
   -- 7. Is_Clique / Is_Maximal_Clique predicates
   -------------------------------------------------------------------------

   procedure Test_Predicates is
      G : Graph;
      S : Vertex_Set;
   begin
      Section ("7. Is_Clique / Is_Maximal_Clique predicates");

      Clear (G, 4);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      --  triangle on 1,2,3; vertex 4 isolated

      S := [others => False];
      Check (Is_Clique (G, S), "empty set is vacuous clique");
      Check (not Is_Maximal_Clique (G, S), "empty not maximal");

      S := [others => False];
      S (1) := True;
      Check (Is_Clique (G, S), "singleton Is_Clique");
      Check (not Is_Maximal_Clique (G, S),
             "singleton {1} not maximal (in triangle)");

      S := [others => False];
      S (4) := True;
      Check (Is_Clique (G, S), "isolate singleton Is_Clique");
      Check (Is_Maximal_Clique (G, S), "isolate {4} is maximal");

      S := [others => False];
      S (1) := True; S (2) := True;
      Check (Is_Clique (G, S), "edge {1,2} Is_Clique");
      Check (not Is_Maximal_Clique (G, S), "edge {1,2} not maximal");

      S := [others => False];
      S (1) := True; S (2) := True; S (3) := True;
      Check (Is_Clique (G, S), "triangle Is_Clique");
      Check (Is_Maximal_Clique (G, S), "triangle is maximal");

      S := [others => False];
      S (1) := True; S (4) := True;
      Check (not Is_Clique (G, S), "non-edge {1,4} not clique");
      Check (not Is_Maximal_Clique (G, S), "non-clique not maximal");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      S := [others => False];
      S (1) := True; S (2) := True;
      Check (Is_Maximal_Clique (G, S), "P2 edge is maximal");
      S (3) := True;
      Check (not Is_Clique (G, S), "{1,2,3} not clique on P2+isolate");
   end Test_Predicates;

   -------------------------------------------------------------------------
   -- 8. API / Invalid_Argument / reset
   -------------------------------------------------------------------------

   procedure Test_API is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
      S       : Vertex_Set := [others => False];
      Clique  : Vertex_Set;
      Size    : Natural;
   begin
      Section ("8. API / Invalid_Argument / reset");

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
      Check_Enumeration (G, 4, "after Clear edgeless → 4 singletons");
      Check (Clique_Number (G) = 1, "after Clear ω = 1");

      Clear (G, 3);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Find_Maximum_Clique (G, Clique, Size);
      Check (Size = 3, "API Find_Maximum_Clique triangle");
      Check (Set_Size (Clique, 3) = 3, "API clique size 3");
      Check (Clique_Number (G) = 3, "API Clique_Number triangle");

      S := [others => False];
      Check (Set_Size (S, 0) = 0, "Set_Size N=0");
      Check (Set_Size (S, 3) = 0, "Set_Size empty flags");
      S (2) := True;
      Check (Set_Size (S, 3) = 1, "Set_Size one flag");

      pragma Unreferenced (Cliques, Count);
   end Test_API;

   -------------------------------------------------------------------------
   -- 9. Larger ω checks without full enum uniqueness
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G : Graph;
   begin
      Section ("9. Larger graphs ω consistency");

      Make_Complete (G, 16);
      Check (Clique_Number (G) = 16, "K16 ω = 16");
      Check_Omega_Consistency (G, "K16");

      Make_Bipartite_Complete (G, 5, 5);
      Check (Clique_Number (G) = 2, "K5,5 ω = 2");
      Check_Enumeration (G, 25, "K5,5 → 25 edges");
      Check_Omega_Consistency (G, "K5,5");

      Make_Star (G, 20);
      Check (Clique_Number (G) = 2, "star S20 ω = 2");
      Check_Enumeration (G, 19, "star S20 → 19 edges");

      Make_Path (G, 20);
      Check (Clique_Number (G) = 2, "P20 ω = 2");
      Check_Enumeration (G, 19, "P20 → 19 edges");

      Make_Cycle (G, 15);
      Check (Clique_Number (G) = 2, "C15 ω = 2");
      Check_Enumeration (G, 15, "C15 → 15 edges");

      --  Two K5 sharing a vertex
      Clear (G, 9);
      for I in 1 .. 5 loop
         for J in I + 1 .. 5 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      for I in 5 .. 9 loop
         for J in I + 1 .. 9 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      Check_Enumeration (G, 2, "two K5 share vertex → 2 maximal");
      Check (Clique_Number (G) = 5, "two K5 share vertex ω = 5");
      Check_Omega_Consistency (G, "two K5 share vertex");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 10. Extra random-ish patterns for volume
   -------------------------------------------------------------------------

   procedure Test_Extra_Patterns is
      G : Graph;
   begin
      Section ("10. Extra patterns / volume");

      for Seed in 1 .. 6 loop
         Clear (G, 7);
         for I in 1 .. 7 loop
            for J in I + 1 .. 7 loop
               if ((I * (13 + Seed) + J * (17 + Seed)) mod 11) < 4 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "extra seed" & Natural'Image (Seed));
         Check_Omega_Brute (G, "extra seed" & Natural'Image (Seed));
      end loop;

      --  Chordal-ish: path with chords
      Clear (G, 6);
      Make_Path (G, 6);
      Add_Edge (G, 1, 3); Add_Edge (G, 2, 4); Add_Edge (G, 3, 5);
      Check_Vs_Brute (G, "path+chords");
      Check_Omega_Brute (G, "path+chords");

      --  Turán T(6,2) = complete bipartite balanced ≈ K3,3
      Make_Bipartite_Complete (G, 3, 3);
      Check (Clique_Number (G) = 2, "Turán-like K3,3 ω = 2");

      --  Complement of a matching: almost complete
      Clear (G, 6);
      for I in 1 .. 6 loop
         for J in I + 1 .. 6 loop
            if not ((I = 1 and J = 2)
                    or else (I = 3 and J = 4)
                    or else (I = 5 and J = 6))
            then
               Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
            end if;
         end loop;
      end loop;
      Check_Vs_Brute (G, "K6 minus matching");
      Check_Omega_Brute (G, "K6 minus matching");
   end Test_Extra_Patterns;

begin
   Put_Line ("Cliques (survey) — Ada 2023 educational test suite");
   Put_Line ("Max_Vertices =" & Positive'Image (Max_Vertices)
             & "  Max_Cliques =" & Positive'Image (Max_Cliques));

   Test_Trivial;
   Test_Complete;
   Test_Sparse;
   Test_Bipartite;
   Test_Composite;
   Test_Brute_Battery;
   Test_Predicates;
   Test_API;
   Test_Larger;
   Test_Extra_Patterns;

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS, "
             & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
