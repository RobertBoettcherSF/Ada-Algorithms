--  Standalone test suite for Chinese_Whispers (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Chinese_Whispers; use Chinese_Whispers;

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

   function Same_Cluster
     (Labels : Label_Array; A, B : Node_Id) return Boolean
   is
   begin
      return Labels (A) = Labels (B);
   end Same_Cluster;

   function Approx (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   procedure Add_Clique (G : in out Graph; Lo, Hi : Node_Id) is
   begin
      for A in Lo .. Hi loop
         for B in A + 1 .. Hi loop
            Add_Undirected_Edge (G, A, B);
         end loop;
      end loop;
   end Add_Clique;

begin
   Put_Line ("Chinese_Whispers test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Empty / single node graphs");
   ---------------------------------------------------------------------
   declare
      G0 : constant Graph := Empty_Graph (0);
      G1 : constant Graph := Empty_Graph (1);
      R0 : constant Result := Run_Chinese_Whispers (G0);
      R1 : constant Result := Run_Chinese_Whispers (G1);
      L1 : constant Label_Array := Init_Labels (G1);
   begin
      Check (G0'Length = 0, "empty graph length 0");
      Check (R0.Cluster_Count = 0, "empty Cluster_Count=0");
      Check (R0.Converged, "empty converges");
      Check (R0.Iters = 0, "empty iters=0");
      Check (Degree (G1, 1) = 0, "singleton degree 0");
      Check (L1 (1) = 1, "singleton init label=1");
      Check (R1.Cluster_Count = 1, "singleton 1 cluster");
      Check (R1.Labels (1) = 1, "singleton keeps label");
      Check (R1.Converged, "singleton converges");
      Check (Cluster_Count (L1) = 1, "Cluster_Count singleton");
   end;

   ---------------------------------------------------------------------
   Section ("2. Graph construction / degrees / weights");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3, 2.5);
      Add_Undirected_Edge (G, 3, 4);
      Check (Degree (G, 1) = 1, "deg(1)=1");
      Check (Degree (G, 2) = 2, "deg(2)=2");
      Check (Degree (G, 3) = 2, "deg(3)=2");
      Check (Degree (G, 4) = 1, "deg(4)=1");
      Check (Approx (Edge_Weight (G, 1, 2), 1.0), "default weight 1");
      Check (Approx (Edge_Weight (G, 2, 3), 2.5), "weighted edge 2.5");
      Check (Approx (Edge_Weight (G, 3, 2), 2.5), "symmetric weight");
      Check (Approx (Edge_Weight (G, 1, 4), 0.0), "missing edge weight 0");
      Add_Undirected_Edge (G, 1, 2, 3.0);
      Check (Approx (Edge_Weight (G, 1, 2), 4.0), "accumulate weight 1+3");
      Check (Degree (G, 1) = 1, "accumulate does not raise degree");
   end;

   ---------------------------------------------------------------------
   Section ("3. Invalid edges / out of range");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      Raised : Boolean;
   begin
      Raised := False;
      begin
         Add_Undirected_Edge (G, 1, 1);
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "self-loop raises Invalid_Argument");

      Raised := False;
      begin
         Add_Undirected_Edge (G, 1, 9);
      exception
         when Constraint_Error | Invalid_Argument => Raised := True;
      end;
      Check (Raised, "out-of-range edge rejected");

      Raised := False;
      begin
         declare
            D : constant Natural := Degree (G, 9);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Constraint_Error | Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Degree out of range rejected");
   end;

   ---------------------------------------------------------------------
   Section ("4. Init_Labels and Neighbor_Label_Score");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      L : Label_Array (1 .. 3);
      S : Weight;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 1, 3);
      L := Init_Labels (G);
      Check (L (1) = 1 and L (2) = 2 and L (3) = 3, "init labels = ids");
      S := Neighbor_Label_Score (G, L, 1, 2);
      Check (Approx (S, 1.0), "score to label-2 neighbor = 1");
      S := Neighbor_Label_Score (G, L, 1, 3);
      Check (Approx (S, 1.0), "score to label-3 neighbor = 1");
      S := Neighbor_Label_Score (G, L, 1, 1);
      Check (Approx (S, 0.0), "score to own unused label = 0");
      L (3) := 2;
      S := Neighbor_Label_Score (G, L, 1, 2);
      Check (Approx (S, 2.0), "score sums two neighbors with label 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Two disjoint cliques → 2 clusters (fixed order)");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (6);
      Order : Node_Array (1 .. 6);
      P : constant Parameters :=
        (Max_Iters => 20, Seed => 42, Relabel_Clusters => True);
      R : Result (1, 6);
   begin
      Add_Clique (G, 1, 3);
      Add_Clique (G, 4, 6);
      for I in Order'Range loop
         Order (I) := I;
      end loop;
      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Cluster_Count = 2, "two cliques → 2 clusters");
      Check (Same_Cluster (R.Labels, 1, 2), "1,2 same cluster");
      Check (Same_Cluster (R.Labels, 2, 3), "2,3 same cluster");
      Check (Same_Cluster (R.Labels, 4, 5), "4,5 same cluster");
      Check (Same_Cluster (R.Labels, 5, 6), "5,6 same cluster");
      Check (not Same_Cluster (R.Labels, 1, 4), "cliques distinct");
      Check (R.Converged, "two cliques converged");
      Check (R.Iters >= 1, "at least one sweep");
   end;

   ---------------------------------------------------------------------
   Section ("6. Weighted edges bias label choice");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      L : Label_Array (1 .. 3);
      State : RNG_State := Init_RNG (1);
      Changed : Boolean;
   begin
      Add_Undirected_Edge (G, 1, 2, 1.0);
      Add_Undirected_Edge (G, 2, 3, 10.0);
      L := Init_Labels (G);
      Update_Node_Label (G, L, 2, State, Changed);
      Check (Changed, "node 2 label changes");
      Check (L (2) = 3, "heavy edge pulls node 2 toward label 3");
      Check (L (1) = 1 and L (3) = 3, "others unchanged this step");
   end;

   ---------------------------------------------------------------------
   Section ("7. Tie handling + fixed seed reproducibility");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
      L1, L2 : Label_Array (1 .. 4);
      S1 : RNG_State := Init_RNG (99);
      S2 : RNG_State := Init_RNG (99);
      S3 : RNG_State := Init_RNG (7);
      C1, C2, C3 : Boolean;
      Pick_A, Pick_B, Pick_C : Label_Id;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 1, 3);
      Add_Undirected_Edge (G, 1, 4);
      L1 := Init_Labels (G);
      L2 := Init_Labels (G);
      Update_Node_Label (G, L1, 1, S1, C1);
      Update_Node_Label (G, L2, 1, S2, C2);
      Pick_A := L1 (1);
      Pick_B := L2 (1);
      Check (C1 and C2, "tie update changes center label");
      Check (Pick_A = Pick_B, "same seed → same tie break");
      Check (Pick_A in 2 .. 4, "tie pick is a neighbor label");

      L1 := Init_Labels (G);
      Update_Node_Label (G, L1, 1, S3, C3);
      Pick_C := L1 (1);
      Check (Pick_C in 2 .. 4, "other seed still valid neighbor label");
      declare
         P : constant Parameters :=
           (Max_Iters => 10, Seed => 12345, Relabel_Clusters => False);
         RA : constant Result := Run_Chinese_Whispers (G, P);
         RB : constant Result := Run_Chinese_Whispers (G, P);
         Match : Boolean := True;
      begin
         for I in 1 .. 4 loop
            if RA.Labels (I) /= RB.Labels (I) then
               Match := False;
            end if;
         end loop;
         Check (Match, "identical Seed → identical full run labels");
         Check (RA.Iters = RB.Iters, "identical Seed → identical iters");
         Check (RA.Cluster_Count = RB.Cluster_Count,
                "identical Seed → identical Cluster_Count");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Convergence on stable coloring");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (2);
      Order : constant Node_Array := [1, 2];
      P : constant Parameters :=
        (Max_Iters => 50, Seed => 1, Relabel_Clusters => False);
      R : Result (1, 2);
   begin
      Add_Undirected_Edge (G, 1, 2);
      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Converged, "edge pair converges");
      Check (Same_Cluster (R.Labels, 1, 2), "pair same cluster");
      Check (R.Cluster_Count = 1, "pair → 1 cluster");
      Check (R.Iters < 50, "early stop before Max_Iters");
   end;

   ---------------------------------------------------------------------
   Section ("9. Max_Iters stop without requiring convergence");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
      Order : constant Node_Array := [1, 2, 3, 4];
      P : constant Parameters :=
        (Max_Iters => 1, Seed => 1, Relabel_Clusters => False);
      R : Result (1, 4);
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      Add_Undirected_Edge (G, 3, 4);
      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Iters = 1, "Max_Iters=1 → exactly one sweep");
      Check (R.Cluster_Count >= 1, "path has ≥1 cluster after 1 sweep");
   end;

   ---------------------------------------------------------------------
   Section ("10. Wikipedia-style plurality smoke");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
      Order : constant Node_Array := [4, 3, 2, 1];
      P : constant Parameters :=
        (Max_Iters => 30, Seed => 2, Relabel_Clusters => True);
      R : Result (1, 4);
      L : Label_Array (1 .. 4);
      State : RNG_State := Init_RNG (2);
      Changed : Boolean;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      Add_Undirected_Edge (G, 3, 1);
      Add_Undirected_Edge (G, 3, 4);

      L := Init_Labels (G);
      L (1) := 1;
      L (2) := 1;
      L (3) := 1;
      Update_Node_Label (G, L, 4, State, Changed);
      Check (Changed, "pendant changes toward plurality");
      Check (L (4) = 1, "pendant adopts triangle label (plurality)");

      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Cluster_Count = 1, "connected triangle+pendant → 1 cluster");
      Check (R.Converged, "wiki smoke converged");
      Check (Same_Cluster (R.Labels, 1, 4), "all nodes same community");
   end;

   ---------------------------------------------------------------------
   Section ("11. Shuffle_Nodes deterministic + Default_Order");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Empty_Graph (5);
      O1 : Node_Array := Default_Order (G);
      O2 : Node_Array := Default_Order (G);
      O3 : Node_Array := Default_Order (G);
      S1 : RNG_State := Init_RNG (77);
      S2 : RNG_State := Init_RNG (77);
      S3 : RNG_State := Init_RNG (88);
      Match : Boolean := True;
      Diff  : Boolean := False;
   begin
      Check (O1'Length = 5, "Default_Order length");
      Check (O1 (1) = 1 and O1 (5) = 5, "Default_Order identity");
      Shuffle_Nodes (O1, S1);
      Shuffle_Nodes (O2, S2);
      for I in O1'Range loop
         if O1 (I) /= O2 (I) then
            Match := False;
         end if;
      end loop;
      Check (Match, "same seed shuffle identical");
      Shuffle_Nodes (O3, S3);
      for I in O1'Range loop
         if O1 (I) /= O3 (I) then
            Diff := True;
         end if;
      end loop;
      Check (Diff, "different seed → different shuffle (likely)");
      declare
         Seen : array (1 .. 5) of Boolean := [others => False];
         Ok : Boolean := True;
      begin
         for I in O1'Range loop
            if O1 (I) not in 1 .. 5 or else Seen (O1 (I)) then
               Ok := False;
            else
               Seen (O1 (I)) := True;
            end if;
         end loop;
         Check (Ok, "shuffle preserves permutation");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Relabel_Contiguous and Cluster_Count");
   ---------------------------------------------------------------------
   declare
      L : Label_Array (1 .. 5) := [1 => 7, 2 => 3, 3 => 7, 4 => 3, 5 => 9];
      C : Natural;
   begin
      C := Cluster_Count (L);
      Check (C = 3, "Cluster_Count of {7,3,7,3,9}=3");
      Relabel_Contiguous (L);
      Check (L (1) = 1, "first appearance → 1");
      Check (L (2) = 2, "second distinct → 2");
      Check (L (3) = 1, "repeat of first stays 1");
      Check (L (4) = 2, "repeat of second stays 2");
      Check (L (5) = 3, "third distinct → 3");
      Check (Cluster_Count (L) = 3, "still 3 after relabel");
   end;

   ---------------------------------------------------------------------
   Section ("13. Seeded Run_Chinese_Whispers on two cliques");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (8);
      P : constant Parameters :=
        (Max_Iters => 40, Seed => 2026, Relabel_Clusters => True);
      R : Result (1, 8);
   begin
      Add_Clique (G, 1, 4);
      Add_Clique (G, 5, 8);
      R := Run_Chinese_Whispers (G, P);
      Check (R.Cluster_Count = 2, "seeded two cliques → 2");
      Check (Same_Cluster (R.Labels, 1, 4), "first clique united");
      Check (Same_Cluster (R.Labels, 5, 8), "second clique united");
      Check (not Same_Cluster (R.Labels, 1, 5), "cliques separated");
      Check (R.Converged, "seeded two cliques converged");
   end;

   ---------------------------------------------------------------------
   Section ("14. Bridge edge between cliques (weak)");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (6);
      Order : constant Node_Array := [1, 2, 3, 4, 5, 6];
      P : constant Parameters :=
        (Max_Iters => 25, Seed => 3, Relabel_Clusters => True);
      R : Result (1, 6);
   begin
      Add_Undirected_Edge (G, 1, 2, 5.0);
      Add_Undirected_Edge (G, 2, 3, 5.0);
      Add_Undirected_Edge (G, 3, 1, 5.0);
      Add_Undirected_Edge (G, 4, 5, 5.0);
      Add_Undirected_Edge (G, 5, 6, 5.0);
      Add_Undirected_Edge (G, 6, 4, 5.0);
      Add_Undirected_Edge (G, 3, 4, 0.1);
      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Cluster_Count = 2, "weak bridge keeps 2 communities");
      Check (Same_Cluster (R.Labels, 1, 2)
             and then Same_Cluster (R.Labels, 2, 3),
             "left triangle united");
      Check (Same_Cluster (R.Labels, 4, 5)
             and then Same_Cluster (R.Labels, 5, 6),
             "right triangle united");
   end;

   ---------------------------------------------------------------------
   Section ("15. Bad permutation rejected");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      Bad : constant Node_Array := [1, 1, 2];
      Raised : Boolean := False;
      P : constant Parameters := Default_Parameters;
   begin
      Add_Undirected_Edge (G, 1, 2);
      begin
         declare
            R : constant Result := Run_Chinese_Whispers (G, Bad, P);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "duplicate order raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("16. Isolated nodes remain distinct");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Empty_Graph (3);
      P : constant Parameters :=
        (Max_Iters => 5, Seed => 1, Relabel_Clusters => True);
      R : constant Result := Run_Chinese_Whispers (G, P);
   begin
      Check (R.Cluster_Count = 3, "3 isolates → 3 clusters");
      Check (R.Converged, "isolates converge immediately");
      Check (R.Labels (1) /= R.Labels (2), "isolate labels differ 1/2");
      Check (R.Labels (2) /= R.Labels (3), "isolate labels differ 2/3");
   end;

   ---------------------------------------------------------------------
   Section ("17. Update isolated node: no change");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Empty_Graph (2);
      L : Label_Array := Init_Labels (G);
      State : RNG_State := Init_RNG (1);
      Changed : Boolean;
   begin
      Update_Node_Label (G, L, 1, State, Changed);
      Check (not Changed, "isolated update Changed=False");
      Check (L (1) = 1, "isolated keeps label");
   end;

   ---------------------------------------------------------------------
   Section ("18. Complete graph → single cluster");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (5);
      Order : constant Node_Array := [1, 2, 3, 4, 5];
      P : constant Parameters :=
        (Max_Iters => 20, Seed => 9, Relabel_Clusters => True);
      R : Result (1, 5);
   begin
      Add_Clique (G, 1, 5);
      R := Run_Chinese_Whispers (G, Order, P);
      Check (R.Cluster_Count = 1, "K5 → 1 cluster");
      Check (R.Converged, "K5 converged");
      Check (Same_Cluster (R.Labels, 1, 5), "K5 endpoints same");
   end;

   ---------------------------------------------------------------------
   Section ("19. RNG basics");
   ---------------------------------------------------------------------
   declare
      S : RNG_State := Init_RNG (0);
      A, B : Natural;
   begin
      A := Next_Random (S);
      B := Next_Random (S);
      Check (A /= 0, "LCG never returns 0 after init seed 0→1");
      Check (A /= B, "consecutive LCG values differ");
      declare
         S2 : RNG_State := Init_RNG (0);
         C : constant Natural := Next_Random (S2);
      begin
         Check (C = A, "seed 0 reproducible first draw");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("20. Relabel option in Parameters");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
      Order : constant Node_Array := [1, 2, 3, 4];
      P_On : constant Parameters :=
        (Max_Iters => 20, Seed => 5, Relabel_Clusters => True);
      P_Off : constant Parameters :=
        (Max_Iters => 20, Seed => 5, Relabel_Clusters => False);
      R_On, R_Off : Result (1, 4);
      Max_Lab : Label_Id;
   begin
      Add_Clique (G, 1, 2);
      Add_Clique (G, 3, 4);
      R_On := Run_Chinese_Whispers (G, Order, P_On);
      R_Off := Run_Chinese_Whispers (G, Order, P_Off);
      Check (R_On.Cluster_Count = 2, "relabel on still 2 clusters");
      Check (R_Off.Cluster_Count = 2, "relabel off still 2 clusters");
      Max_Lab := 1;
      for I in R_On.Labels'Range loop
         if R_On.Labels (I) > Max_Lab then
            Max_Lab := R_On.Labels (I);
         end if;
      end loop;
      Check (Natural (Max_Lab) = R_On.Cluster_Count,
             "relabel → max label = Cluster_Count");
   end;

   ---------------------------------------------------------------------
   Section ("21. Extra coverage: path, star, Max_Iters=0");
   ---------------------------------------------------------------------
   declare
      Path : Graph := Empty_Graph (5);
      Star : Graph := Empty_Graph (5);
      Order : constant Node_Array := [1, 2, 3, 4, 5];
      P0 : constant Parameters :=
        (Max_Iters => 0, Seed => 1, Relabel_Clusters => False);
      P : constant Parameters :=
        (Max_Iters => 30, Seed => 11, Relabel_Clusters => True);
      R0, Rp, Rs : Result (1, 5);
   begin
      Add_Undirected_Edge (Path, 1, 2);
      Add_Undirected_Edge (Path, 2, 3);
      Add_Undirected_Edge (Path, 3, 4);
      Add_Undirected_Edge (Path, 4, 5);
      R0 := Run_Chinese_Whispers (Path, Order, P0);
      Check (R0.Iters = 0, "Max_Iters=0 → zero sweeps");
      Check (R0.Cluster_Count = 5, "Max_Iters=0 keeps init labels");
      Check (not R0.Converged, "Max_Iters=0 not marked converged");

      Rp := Run_Chinese_Whispers (Path, Order, P);
      Check (Rp.Cluster_Count = 1, "path → 1 cluster");
      Check (Rp.Converged, "path converged");

      Add_Undirected_Edge (Star, 1, 2);
      Add_Undirected_Edge (Star, 1, 3);
      Add_Undirected_Edge (Star, 1, 4);
      Add_Undirected_Edge (Star, 1, 5);
      Rs := Run_Chinese_Whispers (Star, Order, P);
      Check (Rs.Cluster_Count = 1, "star → 1 cluster");
      Check (Rs.Converged, "star converged");
   end;

   ---------------------------------------------------------------------
   Section ("22. Score with weights + Default_Parameters");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      L : Label_Array (1 .. 3);
      S : Weight;
      R : Result (1, 3);
   begin
      Add_Undirected_Edge (G, 1, 2, 2.0);
      Add_Undirected_Edge (G, 1, 3, 2.0);
      L := Init_Labels (G);
      L (2) := 9;
      L (3) := 9;
      --  Label 9 is valid Node_Id / Label_Id only up to Max_Nodes; use 2.
      L (2) := 2;
      L (3) := 2;
      S := Neighbor_Label_Score (G, L, 1, 2);
      Check (Approx (S, 4.0), "weighted score 2+2=4");
      R := Run_Chinese_Whispers (G);
      Check (R.Cluster_Count = 1, "default params triangle-ish path → 1");
      Check (Default_Parameters.Max_Iters = 50, "default Max_Iters=50");
      Check (Default_Parameters.Seed = 1, "default Seed=1");
      Check (not Default_Parameters.Relabel_Clusters,
             "default Relabel_Clusters=False");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   pragma Assert (Fail_Count = 0);
end Tests;
