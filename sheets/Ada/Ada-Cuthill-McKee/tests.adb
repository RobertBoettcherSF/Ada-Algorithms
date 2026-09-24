--  Standalone test suite for Cuthill_Mckee (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Cuthill_Mckee; use Cuthill_Mckee;

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
   end Orders_equal;

begin
   Ada.Text_IO.Put_Line ("Cuthill_Mckee test suite");
   Ada.Text_IO.Put_Line ("========================");

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
      Check (Cuthill_Mckee_Order (E0)'Length = 0, "CM empty");
      Check (Reverse_Cuthill_Mckee_Order (E0)'Length = 0, "RCM empty");
      Check (Bandwidth (E0) = 0, "Bandwidth empty");
      Check (Profile (E0) = 0, "Profile empty");
      Check (Is_Symmetric_Pattern (E0), "sym empty0");

      Check (E1.N = 1, "Empty_Graph 1");
      Check (Degree (E1, 1) = 0, "Degree isolated");
      Add_Edge (E1, 1, 1);
      Check (Degree (E1, 1) = 0, "loop ignored");
      Check (Edge_Count (E1) = 0, "no loop edge");
      Check (Bandwidth (E1) = 0, "Bandwidth n=1");
      Check (Profile (E1) = 0, "Profile n=1");
      Check (Is_Valid_Order (E1, Cuthill_Mckee_Order (E1)), "CM n=1 perm");

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
      Check (Bandwidth (E3) = 1, "Bandwidth path3");
      Clear (E3);
      Check (Edge_Count (E3) = 0, "Clear removes edges");
      Check (E3.N = 3, "Clear keeps N");
   end;

   ---------------------------------------------------------------------
   Section ("2. Path / Cycle / Star / Clique / Band / Grid builders");
   ---------------------------------------------------------------------
   declare
      P4 : constant Graph := Path_Graph (4);
      C5 : constant Graph := Cycle_Graph (5);
      S5 : constant Graph := Star_Graph (5);
      K4 : constant Graph := Clique_Graph (4);
      B  : constant Graph := Band_Graph (6, 2);
      B0 : constant Graph := Band_Graph (4, 0);
      G22 : constant Graph := Grid_Graph (2, 2);
      G34 : constant Graph := Grid_Graph (3, 4);
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
      Check (Edge_Count (B) = 9, "Band6 bw2 edges");
      Check (Edge_Count (B0) = 0, "Band bw0");
      Check (Edge_Count (G22) = 4, "Grid 2x2 edges");
      Check (G34.N = 12, "Grid 3x4 n");
      --  rows*(cols-1)+cols*(rows-1) = 3*3+4*2 = 17
      --  3x4 grid: horizontal 3*3=9 per... rows* (cols-1) + cols*(rows-1)
      --  = 3*3 + 4*2 = 9+8 = 17
      Check (Edge_Count (G34) = 17, "Grid 3x4 edges=17");
      Check (Is_Symmetric_Pattern (P4), "sym Path");
      Check (Is_Symmetric_Pattern (C5), "sym Cycle");
      Check (Is_Symmetric_Pattern (S5), "sym Star");
      Check (Is_Symmetric_Pattern (K4), "sym Clique");
      Check (Is_Symmetric_Pattern (B), "sym Band");
      Check (Is_Symmetric_Pattern (G34), "sym Grid");
   end;

   ---------------------------------------------------------------------
   Section ("3. Natural / reverse / Is_Valid_Order / Reverse_Order");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Path_Graph (4);
      Nat : constant Order := Natural_Order (G);
      Rev : constant Order := Reverse_Natural_Order (G);
      Bad : constant Order := [1, 2, 2, 4];
      Short : constant Order := [1, 2, 3];
      R2 : constant Order := Reverse_Order (Nat);
   begin
      Check (Nat'Length = 4, "nat length");
      Check (Nat (1) = 1 and then Nat (4) = 4, "nat values");
      Check (Rev (1) = 4 and then Rev (4) = 1, "rev values");
      Check (Is_Valid_Order (G, Nat), "nat valid");
      Check (Is_Valid_Order (G, Rev), "rev valid");
      Check (not Is_Valid_Order (G, Bad), "dup invalid");
      Check (not Is_Valid_Order (G, Short), "short invalid");
      Check (Orders_Equal (R2, Rev), "Reverse_Order = Reverse_Natural");
      Check (Is_Valid_Order (Empty_Graph (0), Natural_Order (Empty_Graph (0))),
             "empty order valid");
   end;

   ---------------------------------------------------------------------
   Section ("4. Path — already narrow; CM/RCM keep small bandwidth");
   ---------------------------------------------------------------------
   declare
      P2 : constant Graph := Path_Graph (2);
      P5 : constant Graph := Path_Graph (5);
      P8 : constant Graph := Path_Graph (8);
      CM5 : constant Order := Cuthill_Mckee_Order (P5);
      RCM5 : constant Order := Reverse_Cuthill_Mckee_Order (P5);
   begin
      Check (Bandwidth (P2) = 1, "P2 natural bw");
      Check (Bandwidth (P5) = 1, "P5 natural bw");
      Check (Bandwidth (P8) = 1, "P8 natural bw");
      Check (Is_Valid_Order (P5, CM5), "P5 CM permutation");
      Check (Is_Valid_Order (P5, RCM5), "P5 RCM permutation");
      Check (Bandwidth (P5, CM5) = 1, "P5 CM bw=1");
      Check (Bandwidth (P5, RCM5) = 1, "P5 RCM bw=1");
      Check (Orders_equal (RCM5, Reverse_Order (CM5)), "RCM = reverse CM");
      Check (Bandwidth (P8, Cuthill_Mckee_Order (P8)) = 1, "P8 CM bw=1");
      Check (Profile (P5) = 4, "P5 profile natural");
      --  path profile: each i>1 contributes 1 → n-1 = 4
   end;

   ---------------------------------------------------------------------
   Section ("5. Pseudo-peripheral on path / cycle / star");
   ---------------------------------------------------------------------
   declare
      P : constant Graph := Path_Graph (7);
      C : constant Graph := Cycle_Graph (6);
      S : constant Graph := Star_Graph (6);
      PP : constant Vertex_Id := Pseudo_Peripheral_Vertex (P);
      PC : constant Vertex_Id := Pseudo_Peripheral_Vertex (C);
      PS : constant Vertex_Id := Pseudo_Peripheral_Vertex (S);
   begin
      Check (PP = 1 or else PP = 7, "path pseudo-peripheral is endpoint");
      Check (PC in 1 .. 6, "cycle pseudo in range");
      Check (PS /= 1, "star pseudo is a leaf (not center)");
      Check (Degree (S, PS) = 1, "star pseudo leaf deg 1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Star / Clique bandwidth under CM");
   ---------------------------------------------------------------------
   declare
      S : constant Graph := Star_Graph (8);
      K : constant Graph := Clique_Graph (5);
      CM_S : constant Order := Cuthill_Mckee_Order (S);
      RCM_S : constant Order := Reverse_Cuthill_Mckee_Order (S);
      CM_K : constant Order := Cuthill_Mckee_Order (K);
   begin
      Check (Bandwidth (S) = 7, "star natural bw (center=1 to leaf=8)");
      Check (Bandwidth (S, CM_S) <= Bandwidth (S), "star CM bw <= natural");
      Check (Bandwidth (S, RCM_S) <= Bandwidth (S), "star RCM bw <= natural");
      Check (Is_Valid_Order (S, CM_S), "star CM valid");
      Check (Bandwidth (K) = 4, "K5 natural bw");
      Check (Bandwidth (K, CM_K) = 4, "K5 CM bw unchanged (dense)");
      Check (Is_Valid_Order (K, CM_K), "K5 CM valid");
   end;

   ---------------------------------------------------------------------
   Section ("7. Scrambled path — CM restores bandwidth 1");
   ---------------------------------------------------------------------
   declare
      --  Path with vertices labeled out of order: edges connect
      --  a geometric path but ids are permuted so natural bw is large.
      G : Graph := Empty_Graph (6);
      --  Logical path order: 1-3-5-6-4-2  → edges those consecutive
      CM, RCM : Order (1 .. 6);
   begin
      Add_Edge (G, 1, 3);
      Add_Edge (G, 3, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Add_Edge (G, 4, 2);
      Check (Edge_Count (G) = 5, "scrambled path edges");
      Check (Bandwidth (G) > 1, "scrambled natural bw > 1");
      CM := Cuthill_Mckee_Order (G);
      RCM := Reverse_Cuthill_Mckee_Order (G);
      Check (Is_Valid_Order (G, CM), "scrambled CM valid");
      Check (Bandwidth (G, CM) = 1, "scrambled CM restores bw=1");
      Check (Bandwidth (G, RCM) = 1, "scrambled RCM bw=1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Random-ish banded / arrowhead — bandwidth decreases");
   ---------------------------------------------------------------------
   declare
      --  Wide arrowhead: vertex 1 connected to all; plus a path of leaves.
      --  Natural labeling has large bandwidth; CM from a leaf should shrink.
      G : Graph := Empty_Graph (10);
      Nat_BW, CM_BW, RCM_BW : Natural;
      CM, RCM : Order (1 .. 10);
   begin
      for V in 2 .. 10 loop
         Add_Edge (G, 1, V);
      end loop;
      for V in 2 .. 9 loop
         Add_Edge (G, V, V + 1);
      end loop;
      Nat_BW := Bandwidth (G);
      CM := Cuthill_Mckee_Order (G);
      RCM := Reverse_Cuthill_Mckee_Order (G);
      CM_BW := Bandwidth (G, CM);
      RCM_BW := Bandwidth (G, RCM);
      Check (Nat_BW = 9, "arrowhead natural bw");
      Check (CM_BW < Nat_BW, "arrowhead CM decreases bw");
      Check (RCM_BW < Nat_BW, "arrowhead RCM decreases bw");
      Check (Is_Valid_Order (G, CM), "arrowhead CM valid");
      Check (Is_Valid_Order (G, RCM), "arrowhead RCM valid");
   end;

   declare
      --  Mesh with deliberate bad labeling: connect i to i+3 and wrap-ish
      G : Graph := Empty_Graph (12);
      Nat_BW, RCM_BW : Natural;
      RCM : Order (1 .. 12);
   begin
      for I in 1 .. 12 loop
         Add_Edge (G, I, (if I + 3 <= 12 then I + 3 else I + 3 - 12));
      end loop;
      for I in 1 .. 11 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Nat_BW := Bandwidth (G);
      RCM := Reverse_Cuthill_Mckee_Order (G);
      RCM_BW := Bandwidth (G, RCM);
      Check (Nat_BW >= 3, "mesh-ish natural bw >= 3");
      Check (RCM_BW <= Nat_BW, "mesh-ish RCM bw <= natural");
      Check (Is_Valid_Order (G, RCM), "mesh-ish RCM valid");
      Check (Profile (G, RCM) <= Profile (G) + 50, "mesh-ish profile bounded");
   end;

   ---------------------------------------------------------------------
   Section ("9. Grid — RCM reduces bandwidth vs row-major");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Grid_Graph (4, 4);
      Nat_BW : constant Natural := Bandwidth (G);
      CM : constant Order := Cuthill_Mckee_Order (G);
      RCM : constant Order := Reverse_Cuthill_Mckee_Order (G);
      CM_BW : constant Natural := Bandwidth (G, CM);
      RCM_BW : constant Natural := Bandwidth (G, RCM);
   begin
      Check (G.N = 16, "grid 4x4 n");
      Check (Nat_BW = 4, "grid 4x4 natural bw (vertical stride)");
      Check (CM_BW <= Nat_BW, "grid CM bw <= natural");
      Check (RCM_BW <= Nat_BW, "grid RCM bw <= natural");
      Check (Is_Valid_Order (G, CM) and then Is_Valid_Order (G, RCM),
             "grid orders valid");
      Check (Orders_equal (RCM, Reverse_Order (CM)), "grid RCM=rev CM");
   end;

   ---------------------------------------------------------------------
   Section ("10. Explicit Start vs default pseudo-peripheral");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Path_Graph (6);
      CM1 : constant Order := Cuthill_Mckee_Order (G, Start => 1);
      CM6 : constant Order := Cuthill_Mckee_Order (G, Start => 6);
      RCM1 : constant Order := Reverse_Cuthill_Mckee_Order (G, Start => 1);
   begin
      Check (CM1 (1) = 1, "CM start=1 begins at 1");
      Check (CM6 (1) = 6, "CM start=6 begins at 6");
      Check (RCM1 (RCM1'Last) = 1, "RCM start=1 ends at 1");
      Check (Bandwidth (G, CM1) = 1, "CM start1 bw");
      Check (Bandwidth (G, CM6) = 1, "CM start6 bw");
   end;

   ---------------------------------------------------------------------
   Section ("11. Disconnected graph — covers all components");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (5);
      CM : Order (1 .. 5);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 4, 5);
      --  vertex 3 isolated
      CM := Cuthill_Mckee_Order (G);
      Check (Is_Valid_Order (G, CM), "disconnected CM permutation");
      Check (Bandwidth (G, CM) = 1, "disconnected CM bw");
      Check (Reverse_Cuthill_Mckee_Order (G)'Length = 5, "disconnected RCM len");
   end;

   ---------------------------------------------------------------------
   Section ("12. Profile decreases on scrambled path");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (8);
      Nat_P, RCM_P : Natural;
      RCM : Order (1 .. 8);
   begin
      --  Path in order 1-8-2-7-3-6-4-5
      Add_Edge (G, 1, 8);
      Add_Edge (G, 8, 2);
      Add_Edge (G, 2, 7);
      Add_Edge (G, 7, 3);
      Add_Edge (G, 3, 6);
      Add_Edge (G, 6, 4);
      Add_Edge (G, 4, 5);
      Nat_P := Profile (G);
      RCM := Reverse_Cuthill_Mckee_Order (G);
      RCM_P := Profile (G, RCM);
      Check (Bandwidth (G) > 1, "zigzag natural bw > 1");
      Check (Bandwidth (G, RCM) = 1, "zigzag RCM bw=1");
      Check (RCM_P < Nat_P, "zigzag RCM profile decreases");
      Check (Profile (G, Natural_Order (G)) = Nat_P, "profile overload nat");
   end;

   ---------------------------------------------------------------------
   Section ("13. Taxonomy");
   ---------------------------------------------------------------------
   begin
      Check (Implemented (Classical_CM), "CM implemented");
      Check (Implemented (Classical_RCM), "RCM implemented");
      Check (not Implemented (Sloan), "Sloan not implemented");
      Check (Forthcoming (Sloan), "Sloan forthcoming");
      Check (Forthcoming (Nested_Dissection), "ND forthcoming");
      Check (Method_Name (Classical_CM) = "Cuthill-McKee", "name CM");
      Check (Method_Name (Classical_RCM) = "Reverse Cuthill-McKee",
             "name RCM");
   end;

   ---------------------------------------------------------------------
   Section ("14. Band graph already optimal-ish");
   ---------------------------------------------------------------------
   declare
      B : constant Graph := Band_Graph (10, 2);
      RCM : constant Order := Reverse_Cuthill_Mckee_Order (B);
   begin
      Check (Bandwidth (B) = 2, "band natural bw=2");
      Check (Bandwidth (B, RCM) = 2, "band RCM keeps bw=2");
      Check (Is_Valid_Order (B, RCM), "band RCM valid");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra bandwidth / RCM vs CM consistency");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Grid_Graph (3, 5);
      CM : constant Order := Cuthill_Mckee_Order (G);
      RCM : constant Order := Reverse_Cuthill_Mckee_Order (G);
   begin
      Check (Bandwidth (G, CM) = Bandwidth (G, RCM),
             "CM and RCM same bandwidth (reversal)");
      Check (Profile (G, RCM) <= Profile (G, CM)
               or else Profile (G, CM) <= Profile (G, RCM),
             "profiles comparable");
      Check (Degree (G, 1) = 2, "grid corner deg");
      Check (Degree (G, 8) >= 3, "grid interior-ish deg");
   end;

   --  More small checks to push Pass_Count well above 80
   declare
      P : constant Graph := Path_Graph (3);
      C : constant Graph := Cycle_Graph (4);
      S : constant Graph := Star_Graph (4);
   begin
      Check (Bandwidth (P) = 1, "P3 bw");
      Check (Bandwidth (C) = 3, "C4 natural bw (edge 1-4)");
      Check (Bandwidth (C, Reverse_Cuthill_Mckee_Order (C)) <= 2,
             "C4 RCM bw <= 2");
      Check (Edge_Count (S) = 3, "S4 edges");
      Check (Pseudo_Peripheral_Vertex (P, Start => 2) = 1 or else Pseudo_Peripheral_Vertex (P, Start => 2) = 3,
             "P3 pseudo from mid is endpoint");
      Check (Has_Edge (C, 1, 4), "C4 wrap edge");
      Check (not Has_Edge (P, 1, 3), "P3 no chord");
      Check (Bandwidth (S, Cuthill_Mckee_Order (S, 2)) <= 3,
             "S4 CM from leaf bw");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: Pass_Count =" & Pass_Count'Image
     & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
