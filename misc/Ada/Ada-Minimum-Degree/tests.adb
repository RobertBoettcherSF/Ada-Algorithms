--  Standalone test suite for Minimum_Degree (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Minimum_Degree; use Minimum_Degree;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Orders_Equal (A, B : Order) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (B'First + (I - A'First)) then
            return False;
         end if;
      end loop;
      return True;
   end Orders_Equal;

begin
   Ada.Text_IO.Put_Line ("Minimum_Degree test suite");
   Ada.Text_IO.Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Empty / tiny graphs / Add_Edge / Degree");
   ---------------------------------------------------------------------
   declare
      E0 : constant Graph := Empty_Graph (0);
      E1 : Graph := Empty_Graph (1);
      E3 : Graph := Empty_Graph (3);
   begin
      Check (E0.N = 0, "Empty_Graph 0");
      Check (Edge_Count (E0) = 0, "Edge_Count empty0");
      Check (Natural_Order (E0)'Length = 0, "Natural_Order empty");
      Check (Minimum_Degree_Order (E0)'Length = 0, "MD empty");
      Check (Natural_Fill (E0) = 0, "Natural_Fill empty");
      Check (MD_Fill (E0) = 0, "MD_Fill empty");
      Check (Is_Symmetric_Pattern (E0), "sym empty0");

      Check (E1.N = 1, "Empty_Graph 1");
      Check (Degree (E1, 1) = 0, "Degree isolated");
      Add_Edge (E1, 1, 1);
      Check (Degree (E1, 1) = 0, "loop ignored");
      Check (Edge_Count (E1) = 0, "no loop edge");
      Check (Fill_In_Count (E1, Natural_Order (E1)) = 0, "fill n=1");
      Check (Symbolic_Cholesky_Nnz (E1, Natural_Order (E1)) = 1,
             "chol nnz n=1");

      Add_Edge (E3, 1, 2);
      Add_Edge (E3, 2, 3);
      Check (Has_Edge (E3, 1, 2), "Has_Edge 1-2");
      Check (Has_Edge (E3, 2, 1), "Has_Edge symmetric");
      Check (not Has_Edge (E3, 1, 3), "no edge 1-3");
      Check (Degree (E3, 1) = 1, "deg 1");
      Check (Degree (E3, 2) = 2, "deg 2");
      Check (Degree (E3, 3) = 1, "deg 3");
      Check (Edge_Count (E3) = 2, "edges path3");
      Check (Is_Symmetric_Pattern (E3), "sym path3");
      Clear (E3);
      Check (Edge_Count (E3) = 0, "Clear removes edges");
      Check (E3.N = 3, "Clear keeps N");
   end;

   ---------------------------------------------------------------------
   Section ("2. Path / Cycle / Star / Clique / Band builders");
   ---------------------------------------------------------------------
   declare
      P4 : constant Graph := Path_Graph (4);
      C5 : constant Graph := Cycle_Graph (5);
      S5 : constant Graph := Star_Graph (5);
      K4 : constant Graph := Clique_Graph (4);
      B  : constant Graph := Band_Graph (6, 2);
      B0 : constant Graph := Band_Graph (4, 0);
   begin
      Check (Edge_Count (P4) = 3, "Path4 edges");
      Check (Degree (P4, 1) = 1 and then Degree (P4, 2) = 2, "Path4 degs");
      Check (Edge_Count (C5) = 5, "Cycle5 edges");
      Check (Degree (C5, 1) = 2, "Cycle deg");
      Check (Edge_Count (S5) = 4, "Star5 edges");
      Check (Degree (S5, 1) = 4, "Star center deg");
      Check (Degree (S5, 3) = 1, "Star leaf deg");
      Check (Edge_Count (K4) = 6, "K4 edges");
      Check (Degree (K4, 2) = 3, "K4 deg");
      Check (Edge_Count (B) = 9, "Band6 bw2 quick");
      Check (Edge_Count (B0) = 0, "Band bw0");
      Check (Is_Symmetric_Pattern (P4), "sym Path");
      Check (Is_Symmetric_Pattern (C5), "sym Cycle");
      Check (Is_Symmetric_Pattern (S5), "sym Star");
      Check (Is_Symmetric_Pattern (K4), "sym Clique");
      Check (Is_Symmetric_Pattern (B), "sym Band");
   end;

   --  Exact band edge count: for n=6, bw=2: offsets 1 → 5 edges, offset 2 → 4
   declare
      B : constant Graph := Band_Graph (6, 2);
   begin
      Check (Edge_Count (B) = 5 + 4, "Band6 bw2 edges=9");
      Check (Has_Edge (B, 1, 3) and then not Has_Edge (B, 1, 4),
             "Band connectivity");
   end;

   ---------------------------------------------------------------------
   Section ("3. Natural / reverse / Is_Valid_Order");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Path_Graph (4);
      Nat : constant Order := Natural_Order (G);
      Rev : constant Order := Reverse_Natural_Order (G);
      Bad : constant Order := [1, 2, 2, 4];
      Short : constant Order := [1, 2, 3];
   begin
      Check (Nat'Length = 4, "nat length");
      Check (Nat (1) = 1 and then Nat (4) = 4, "nat values");
      Check (Rev (1) = 4 and then Rev (4) = 1, "rev values");
      Check (Is_Valid_Order (G, Nat), "nat valid");
      Check (Is_Valid_Order (G, Rev), "rev valid");
      Check (not Is_Valid_Order (G, Bad), "dup invalid");
      Check (not Is_Valid_Order (G, Short), "short invalid");
      Check (Is_Valid_Order (Empty_Graph (0), Natural_Order (Empty_Graph (0))),
             "empty order valid");
   end;

   ---------------------------------------------------------------------
   Section ("4. Path graphs — little / zero fill under MD and natural");
   ---------------------------------------------------------------------
   declare
      P2 : constant Graph := Path_Graph (2);
      P5 : constant Graph := Path_Graph (5);
      P8 : constant Graph := Path_Graph (8);
      MD5 : constant Order := Minimum_Degree_Order (P5);
   begin
      Check (Natural_Fill (P2) = 0, "P2 natural fill 0");
      Check (MD_Fill (P2) = 0, "P2 MD fill 0");
      Check (Natural_Fill (P5) = 0, "P5 natural fill 0");
      Check (MD_Fill (P5) = 0, "P5 MD fill 0");
      Check (Natural_Fill (P8) = 0, "P8 natural fill 0");
      Check (MD_Fill (P8) = 0, "P8 MD fill 0");
      Check (Is_Valid_Order (P5, MD5), "P5 MD permutation");
      --  MD on path starts at an endpoint (deg 1, lowest index = 1).
      Check (MD5 (1) = 1, "P5 MD starts at 1");
      Check (Fill_Reduction (P5) = 0, "P5 fill reduction 0");
      Check (Symbolic_Cholesky_Nnz (P5, Natural_Order (P5)) =
               5 + Edge_Count (P5),
             "P5 chol nnz = n+|E|");
   end;

   ---------------------------------------------------------------------
   Section ("5. Star — MD avoids center-first fill disaster");
   ---------------------------------------------------------------------
   declare
      S : constant Graph := Star_Graph (7);
      Nat : constant Order := Natural_Order (S);
      --  Natural: center=1 first → fill among all 6 leaves = C(6,2)=15
      Center_First : constant Order :=
        [1, 2, 3, 4, 5, 6, 7];
      Leaves_First : constant Order :=
        [2, 3, 4, 5, 6, 7, 1];
      MD : constant Order := Minimum_Degree_Order (S);
   begin
      Check (Fill_In_Count (S, Center_First) = 15, "star center-first fill");
      Check (Fill_In_Count (S, Leaves_First) = 0, "star leaves-first fill");
      Check (Natural_Fill (S) = 15, "star natural = center first");
      Check (MD_Fill (S) = 0, "star MD fill 0");
      Check (Fill_Reduction (S) = 15, "star fill reduction 15");
      Check (MD (1) /= 1, "MD does not start at center");
      Check (MD (1) = 2, "MD starts at lowest leaf");
      Check (Is_Valid_Order (S, MD), "star MD valid");
      Check (Filled_Edge_Count (S, MD) = Edge_Count (S), "star filled=|E|");
      Check (Symbolic_Cholesky_Nnz (S, MD) = 7 + 6, "star chol nnz MD");
      Check (Symbolic_Cholesky_Nnz (S, Nat) = 7 + 6 + 15, "star chol nnz nat");
   end;

   ---------------------------------------------------------------------
   Section ("6. Clique — zero fill always");
   ---------------------------------------------------------------------
   declare
      K : constant Graph := Clique_Graph (5);
      MD : constant Order := Minimum_Degree_Order (K);
   begin
      Check (Natural_Fill (K) = 0, "K5 natural fill 0");
      Check (MD_Fill (K) = 0, "K5 MD fill 0");
      Check (Fill_In_Count (K, Reverse_Natural_Order (K)) = 0, "K5 rev fill");
      Check (Is_Valid_Order (K, MD), "K5 MD valid");
      Check (Edge_Count (K) = 10, "K5 |E|=10");
      Check (Symbolic_Cholesky_Nnz (K, MD) = 5 + 10, "K5 chol dense");
      --  All degrees equal → MD picks lowest indices in order 1..5
      Check (Orders_Equal (MD, Natural_Order (K)), "K5 MD = natural");
   end;

   ---------------------------------------------------------------------
   Section ("7. Tree / arrow patterns and known small examples");
   ---------------------------------------------------------------------
   declare
      --  Tree: 1—2—3 with 2—4 (like a small branched tree)
      T : Graph := Empty_Graph (4);
      MD : Order (1 .. 4);
      Nat_F, MD_F : Natural;
   begin
      Add_Edge (T, 1, 2);
      Add_Edge (T, 2, 3);
      Add_Edge (T, 2, 4);
      Nat_F := Natural_Fill (T);
      MD := Minimum_Degree_Order (T);
      MD_F := Fill_In_Count (T, MD);
      Check (Edge_Count (T) = 3, "tree edges");
      Check (Is_Valid_Order (T, MD), "tree MD valid");
      Check (MD_F <= Nat_F, "tree MD fill <= natural");
      Check (MD_F = 0, "tree MD fill 0");
      --  Natural 1,2,3,4: elim 1 (nbr 2) ok; elim 2 (nbrs 3,4) adds 3—4 → fill 1
      Check (Nat_F = 1, "tree natural fill 1");
      Check (Fill_Reduction (T) = 1, "tree reduction 1");
   end;

   declare
      --  Two hubs: 1 connected to 2,3; 4 connected to 2,3 (C4 without diagonals
      --  wait — that's C4). Use diamond with chord later.
      C4 : constant Graph := Cycle_Graph (4);
      MD : constant Order := Minimum_Degree_Order (C4);
   begin
      Check (Natural_Fill (C4) >= 0, "C4 natural fill defined");
      Check (MD_Fill (C4) <= Natural_Fill (C4), "C4 MD <= natural");
      Check (Is_Valid_Order (C4, MD), "C4 MD valid");
      --  C4 all deg 2; MD picks 1 first → neighbors 2,4 get edge 2—4 (fill);
      --  then continues. Exact fill for classical MD on C4:
      Check (MD (1) = 1, "C4 MD starts at 1");
      Check (MD_Fill (C4) = 1, "C4 MD fill 1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Band graphs / MD vs natural");
   ---------------------------------------------------------------------
   declare
      B : constant Graph := Band_Graph (8, 1); -- path-like
      W : constant Graph := Band_Graph (8, 3);
   begin
      Check (Edge_Count (B) = 7, "band8 bw1 = path");
      Check (MD_Fill (B) = 0 and then Natural_Fill (B) = 0, "narrow band 0");
      Check (MD_Fill (W) <= Natural_Fill (W), "wide band MD <= nat");
      Check (Is_Valid_Order (W, Minimum_Degree_Order (W)), "wide MD valid");
      Check (Filled_Edge_Count (W, Natural_Order (W)) >= Edge_Count (W),
             "filled >= |E|");
   end;

   ---------------------------------------------------------------------
   Section ("9. Tie-breaking / MD determinism");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Path_Graph (6);
      A : constant Order := Minimum_Degree_Order (G);
      B : constant Order := Minimum_Degree_Order (G);
   begin
      Check (Orders_Equal (A, B), "MD deterministic");
      Check (A (1) = 1, "tie picks lowest index endpoint");
   end;

   declare
      --  Three isolated vertices: all deg 0 → order 1,2,3
      Iso : constant Graph := Empty_Graph (3);
      MD : constant Order := Minimum_Degree_Order (Iso);
   begin
      Check (Orders_Equal (MD, Natural_Order (Iso)), "isolates MD=nat");
      Check (MD_Fill (Iso) = 0, "isolates fill 0");
      Check (Symbolic_Cholesky_Nnz (Iso, MD) = 3, "isolates chol diag only");
   end;

   ---------------------------------------------------------------------
   Section ("10. Taxonomy / method names");
   ---------------------------------------------------------------------
   begin
      Check (Implemented (Classical_Minimum_Degree), "classical implemented");
      Check (not Implemented (Approximate_Minimum_Degree), "AMD not impl");
      Check (Forthcoming (Approximate_Minimum_Degree), "AMD forthcoming");
      Check (Forthcoming (Multiple_Minimum_Degree), "MMD forthcoming");
      Check (Forthcoming (Nested_Dissection), "ND forthcoming");
      Check (not Forthcoming (Classical_Minimum_Degree), "classical not forth");
      Check (Method_Name (Classical_Minimum_Degree)'Length > 0, "name MD");
      Check (Method_Name (Approximate_Minimum_Degree)'Length > 0, "name AMD");
      Check (Method_Name (Multiple_Minimum_Degree)'Length > 0, "name MMD");
      Check (Method_Name (Nested_Dissection)'Length > 0, "name ND");
   end;

   ---------------------------------------------------------------------
   Section ("11. Capacity / symmetry / extra queries");
   ---------------------------------------------------------------------
   declare
      Big : Graph := Empty_Graph (Max_Vertices);
      P : constant Graph := Path_Graph (10);
   begin
      Check (Big.N = Max_Vertices, "max vertices");
      Add_Edge (Big, 1, Max_Vertices);
      Check (Has_Edge (Big, Max_Vertices, 1), "edge ends");
      Check (Degree (Big, 1) = 1, "big deg");
      Check (Is_Symmetric_Pattern (Big), "big sym");
      Check (Edge_Count (P) = 9, "P10 edges");
      Check (MD_Fill (P) = 0, "P10 MD fill");
      Check (Natural_Fill (P) = 0, "P10 nat fill");
      Check (Fill_Reduction (P) = 0, "P10 reduction");
   end;

   ---------------------------------------------------------------------
   Section ("12. Cholesky nnz consistency");
   ---------------------------------------------------------------------
   declare
      S : constant Graph := Star_Graph (4);
      MD : constant Order := Minimum_Degree_Order (S);
      Nat : constant Order := Natural_Order (S);
   begin
      Check (Symbolic_Cholesky_Nnz (S, MD) =
               S.N + Filled_Edge_Count (S, MD),
             "chol = n + filled MD");
      Check (Symbolic_Cholesky_Nnz (S, Nat) =
               S.N + Edge_Count (S) + Fill_In_Count (S, Nat),
             "chol = n+|E|+fill nat");
      Check (Filled_Edge_Count (S, MD) = Edge_Count (S) + MD_Fill (S),
             "filled identity MD");
   end;

   ---------------------------------------------------------------------
   Section ("13. Reverse natural on star / path");
   ---------------------------------------------------------------------
   declare
      S : constant Graph := Star_Graph (5);
      P : constant Graph := Path_Graph (5);
      RevS : constant Order := Reverse_Natural_Order (S);
   begin
      --  Reverse natural on star: 5,4,3,2,1 — leaves first then center → 0 fill
      Check (Fill_In_Count (S, RevS) = 0, "star rev-nat fill 0");
      Check (Fill_In_Count (P, Reverse_Natural_Order (P)) = 0,
             "path rev-nat fill 0");
      Check (RevS (1) = 5 and then RevS (5) = 1, "rev star ends");
   end;

   ---------------------------------------------------------------------
   Section ("14. Manual elimination check (triangle + pendant)");
   ---------------------------------------------------------------------
   declare
      MD : Order (1 .. 4);
      G4 : Graph := Empty_Graph (4);
      K3 : constant Graph := Clique_Graph (3);
   begin
      Add_Edge (G4, 1, 2);
      Add_Edge (G4, 2, 3);
      Add_Edge (G4, 1, 3);
      Add_Edge (G4, 1, 4);
      MD := Minimum_Degree_Order (G4);
      --  deg: 1→3, 2→2, 3→2, 4→1 → pick 4 first
      Check (MD (1) = 4, "pendant eliminated first");
      Check (MD_Fill (G4) = 0, "pendant+triangle MD fill 0");
      Check (Natural_Fill (G4) >= 0, "pendant natural defined");
      Check (Is_Valid_Order (G4, MD), "pendant MD valid");
      Check (Degree (G4, 1) = 3, "hub deg 3");
      Check (Degree (G4, 4) = 1, "pendant deg 1");
      Check (Edge_Count (K3) = 3, "triangle still K3");
   end;

   ---------------------------------------------------------------------
   Section ("15. Fill_In_Count Pre / multiple orders");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Path_Graph (4);
      Mid : constant Order := [2, 1, 3, 4];
      --  elim 2 with nbrs 1,3 → add 1-3 (fill 1); then rest no fill
   begin
      Check (Fill_In_Count (G, Mid) = 1, "path mid-first fill 1");
      Check (Fill_In_Count (G, Natural_Order (G)) = 0, "path nat 0 again");
      Check (Is_Valid_Order (G, Mid), "mid order valid");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=========================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   elsif Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED (but pass count < 80)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
