--  Standalone test suite for WACA_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with WACA_Clustering; use WACA_Clustering;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Uniform_Attrs
     (N : Node_Count;
      Power : Positive_Real := 10.0;
      Signal : Unit_Interval := 0.5;
      Ideal : Natural := 7;
      King : Non_Negative := 0.0) return Attrs_Array
   is
      A : Attrs_Array (1 .. Device_Id (if N = 0 then 1 else N));
   begin
      if N = 0 then
         declare
            Empty : Attrs_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      for D in 1 .. Device_Id (N) loop
         A (D) := (Power => Power, Signal => Signal,
                   Ideal_Degree => Ideal, King_Bonus => King);
      end loop;
      return A (1 .. Device_Id (N));
   end Uniform_Attrs;

begin
   Put_Line ("WACA_Clustering test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   end;

   ---------------------------------------------------------------------
   Section ("2. Power appropriateness PA = log(1+P) monotonic");
   ---------------------------------------------------------------------
   declare
      PA1 : constant Real := Power_Appropriateness (1.0);
      PA2 : constant Real := Power_Appropriateness (10.0);
      PA3 : constant Real := Power_Appropriateness (100.0);
      --  ln(2) ≈ 0.693147
   begin
      Check (Approx (PA1, 0.693147, 1.0E-5), "PA(1)=ln(2)");
      Check (PA2 > PA1, "PA monotonic 1→10");
      Check (PA3 > PA2, "PA monotonic 10→100");
      Check (PA3 - PA2 < PA2 - PA1 + 1.0, "diminishing returns trend");
      Check (Power_Appropriateness (0.001) > 0.0, "tiny power still >0");
      Check (Approx (Power_Appropriateness (1.718281828), 1.0, 1.0E-4),
             "PA(e-1)≈1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Dissemination degree peaks at ideal");
   ---------------------------------------------------------------------
   declare
      Ideal : constant Natural := 7;
      Peak : constant Real := Dissemination_Degree_Score (7, Ideal);
      Low  : constant Real := Dissemination_Degree_Score (3, Ideal);
      High : constant Real := Dissemination_Degree_Score (11, Ideal);
      Far  : constant Real := Dissemination_Degree_Score (0, Ideal);
   begin
      Check (Approx (Peak, 1.0), "DD at ideal = 1");
      Check (Low < Peak, "DD lower when deg < ideal");
      Check (High < Peak, "DD lower when deg > ideal");
      Check (Approx (Low, High), "DD symmetric about ideal");
      Check (Approx (Dissemination_Degree_Score (6, Ideal), 0.5),
             "DD(|7-6|)=1/2");
      Check (Far < Low, "DD farther is smaller");
      Check (Approx (Dissemination_Degree_Score (0, 0), 1.0),
             "DD(0,0)=1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Local clustering coefficient: triangle=1, star center=0");
   ---------------------------------------------------------------------
   declare
      --  Triangle 1-2-3
      Tri : Graph := Empty_Graph (3);
      --  Star: center 1 connected to 2,3,4 (no leaf edges)
      Star : Graph := Empty_Graph (4);
      Path : Graph := Empty_Graph (3);
   begin
      Add_Undirected_Edge (Tri, 1, 2);
      Add_Undirected_Edge (Tri, 2, 3);
      Add_Undirected_Edge (Tri, 3, 1);
      Check (Approx (Local_Clustering_Coefficient (Tri, 1), 1.0),
             "triangle node c_L=1");
      Check (Approx (Local_Clustering_Coefficient (Tri, 2), 1.0),
             "triangle node2 c_L=1");
      Check (Degree (Tri, 1) = 2, "triangle deg=2");

      Add_Undirected_Edge (Star, 1, 2);
      Add_Undirected_Edge (Star, 1, 3);
      Add_Undirected_Edge (Star, 1, 4);
      Check (Approx (Local_Clustering_Coefficient (Star, 1), 0.0),
             "star center c_L=0");
      Check (Approx (Local_Clustering_Coefficient (Star, 2), 0.0),
             "star leaf deg=1 → c_L=0");
      Check (Degree (Star, 1) = 3, "star center deg=3");

      Add_Undirected_Edge (Path, 1, 2);
      Add_Undirected_Edge (Path, 2, 3);
      Check (Approx (Local_Clustering_Coefficient (Path, 2), 0.0),
             "path middle c_L=0 (no edge 1-3)");
      Check (Approx (Local_Clustering_Coefficient (Path, 1), 0.0),
             "path end deg=1 → 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Highest-weight node becomes CH in a clique");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (4);
      A : Attrs_Array := Uniform_Attrs (4, Power => 1.0, Signal => 0.1);
      F : constant Weight_Factors :=
        (Wf1 => 1.0, Wf2 => 1.0, Wf3 => 0.0, Wf4 => 0.0);
      R : WACA_Result (1, 4);
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 1, 3);
      Add_Undirected_Edge (G, 1, 4);
      Add_Undirected_Edge (G, 2, 3);
      Add_Undirected_Edge (G, 2, 4);
      Add_Undirected_Edge (G, 3, 4);
      --  Boost node 3 power → highest PA → highest weight
      A (3).Power := 1000.0;
      R := Run_WACA (G, A, F);
      Check (R.Role (3) = Clusterhead, "node 3 is Clusterhead");
      Check (R.Clusterhead_Of (1) = 3, "node 1 elects 3");
      Check (R.Clusterhead_Of (2) = 3, "node 2 elects 3");
      Check (R.Clusterhead_Of (4) = 3, "node 4 elects 3");
      Check (R.Clusterhead_Of (3) = 3, "node 3 elects self");
      Check (R.Weights (3) > R.Weights (1), "weight(3) > weight(1)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Sub-head chain on a path with increasing weights");
   ---------------------------------------------------------------------
   declare
      --  Path 1—2—3 with weights increasing toward 3
      G : Graph := Empty_Graph (3);
      A : Attrs_Array := Uniform_Attrs (3, Power => 1.0, Signal => 0.0);
      F : constant Weight_Factors :=
        (Wf1 => 0.0, Wf2 => 1.0, Wf3 => 0.0, Wf4 => 0.0);
      R : WACA_Result (1, 3);
      Root : Device_Id;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      A (1).Signal := 0.1;
      A (2).Signal := 0.5;
      A (3).Signal := 0.9;
      R := Elect_Clusterheads (G, A, F);
      Check (R.Clusterhead_Of (1) = 2, "1 elects 2 (higher nbr)");
      Check (R.Clusterhead_Of (2) = 3, "2 elects 3");
      Check (R.Clusterhead_Of (3) = 3, "3 elects self → CH");
      Check (R.Role (3) = Clusterhead, "3 is Clusterhead");
      Check (R.Role (2) = Sub_Head, "2 is Sub_Head (1 points to 2)");
      Check (R.Role (1) = Slave, "1 is Slave");
      Root := Follow_To_Root (R.Clusterhead_Of, 1);
      Check (Root = 3, "Follow_To_Root(1)=3");
      Check (Follow_To_Root (R.Clusterhead_Of, 2) = 3,
             "Follow_To_Root(2)=3");
      Check (Follow_To_Root (R.Clusterhead_Of, 3) = 3,
             "Follow_To_Root(3)=3");
   end;

   ---------------------------------------------------------------------
   Section ("7. King bonus can prevent flip when small weight gap");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (2);
      A : Attrs_Array := Uniform_Attrs (2, Power => 1.0, Signal => 0.5);
      F : constant Weight_Factors :=
        (Wf1 => 0.0, Wf2 => 1.0, Wf3 => 0.0, Wf4 => 0.0);
      R0, R1 : WACA_Result (1, 2);
      Old_N, New_N : Node_Neighbors;
   begin
      Add_Undirected_Edge (G, 1, 2);
      A (1).Signal := 0.50;
      A (2).Signal := 0.49;
      R0 := Run_WACA (G, A, F);
      Check (R0.Role (1) = Clusterhead, "initially 1 is CH");
      Check (R0.Clusterhead_Of (2) = 1, "2 elects 1");

      --  Without bonus, small signal bump on 2 would flip CH
      A (2).Signal := 0.51;
      R0 := Run_WACA (G, A, F);
      Check (R0.Role (2) = Clusterhead, "without bonus 2 becomes CH");

      --  Restore; give 1 a king bonus larger than the gap
      A (2).Signal := 0.51;
      A (1).Signal := 0.50;
      A (1).King_Bonus := 0.10;  -- gap is 0.01 in signal*wf2
      R1 := Run_WACA (G, A, F);
      Check (R1.Role (1) = Clusterhead, "king bonus keeps 1 as CH");
      Check (R1.Clusterhead_Of (2) = 1, "2 still elects 1 with bonus");
      Check (R1.Weights (1) > R1.Weights (2), "W(1)>W(2) with bonus");

      --  King_Bonus_Update: stable CH neighborhood → +33
      Old_N := G (1);
      New_N := G (1);
      A (1).King_Bonus := 0.0;
      King_Bonus_Update (A, 1, True, Old_N, New_N);
      Check (Approx (A (1).King_Bonus, 33.0), "stable CH → K+=33");
      King_Bonus_Update (A, 1, True, Old_N, New_N);
      Check (Approx (A (1).King_Bonus, 66.0), "stable again → 66");
      King_Bonus_Update (A, 1, True, Old_N, New_N);
      Check (Approx (A (1).King_Bonus, 99.0), "cap at 99");

      --  Lose CH → K=0
      King_Bonus_Update (A, 1, False, Old_N, New_N);
      Check (Approx (A (1).King_Bonus, 0.0), "not CH → K=0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty graph / single node elects self");
   ---------------------------------------------------------------------
   declare
      G0 : constant Graph := Empty_Graph (0);
      A0 : constant Attrs_Array := Uniform_Attrs (0);
      R0 : constant WACA_Result := Run_WACA (G0, A0);
      G1 : constant Graph := Empty_Graph (1);
      A1 : constant Attrs_Array := Uniform_Attrs (1);
      R1 : WACA_Result (1, 1);
   begin
      Check (G0'Length = 0, "empty graph length 0");
      Check (R0.Weights'Length = 0, "empty result weights");
      Check (Degree (G1, 1) = 0, "singleton degree 0");
      R1 := Run_WACA (G1, A1);
      Check (R1.Clusterhead_Of (1) = 1, "singleton elects self");
      Check (R1.Role (1) = Clusterhead, "singleton is Clusterhead");
      Check (Follow_To_Root (R1.Clusterhead_Of, 1) = 1,
             "singleton root is self");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid factors / ids raise");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (2);
      A : constant Attrs_Array := Uniform_Attrs (2);
      Bad_F : Weight_Factors := Default_Factors;
      Raised : Boolean;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Bad_F.Wf1 := -1.0;
      Raised := False;
      begin
         declare
            W : constant Real := Compute_Weight (G, 1, A, Bad_F);
            pragma Unreferenced (W);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "negative Wf1 → Invalid_Argument");

      Raised := False;
      begin
         declare
            D : constant Natural := Degree (G, 3);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Degree out of range → Invalid_Argument");

      Raised := False;
      begin
         Add_Undirected_Edge (G, 1, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "self-loop → Invalid_Argument");

      Raised := False;
      begin
         declare
            CH : constant CH_Array (1 .. 2) := [1, 2];
            X  : constant Device_Id := Follow_To_Root (CH, 3);
            pragma Unreferenced (X);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Follow_To_Root bad id → Invalid_Argument");

      Raised := False;
      begin
         declare
            --  Cycle 1→2→1
            CH : constant CH_Array (1 .. 2) := [2, 1];
            X  : constant Device_Id := Follow_To_Root (CH, 1);
            pragma Unreferenced (X);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "CH cycle → Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("10. Deterministic tie-break (lowest device id)");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      A : constant Attrs_Array := Uniform_Attrs (3, Power => 5.0, Signal => 0.5);
      F : constant Weight_Factors := Default_Factors;
      R : WACA_Result (1, 3);
   begin
      --  Clique with identical attrs → all weights equal
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 1, 3);
      Add_Undirected_Edge (G, 2, 3);
      R := Run_WACA (G, A, F);
      Check (Near (R.Weights (1), R.Weights (2)), "equal weights 1,2");
      Check (Near (R.Weights (2), R.Weights (3)), "equal weights 2,3");
      --  Each elects lowest id among self+neighbors = 1 for all
      Check (R.Clusterhead_Of (1) = 1, "tie: 1 elects self");
      Check (R.Clusterhead_Of (2) = 1, "tie: 2 elects 1");
      Check (R.Clusterhead_Of (3) = 1, "tie: 3 elects 1");
      Check (R.Role (1) = Clusterhead, "tie: 1 is sole CH");
   end;

   ---------------------------------------------------------------------
   Section ("11. Roles partition all nodes");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (5);
      A : Attrs_Array := Uniform_Attrs (5);
      F : constant Weight_Factors := Default_Factors;
      R : WACA_Result (1, 5);
      N_CH, N_SH, N_SL : Natural := 0;
   begin
      --  Two components: triangle 1-2-3 and edge 4-5
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      Add_Undirected_Edge (G, 3, 1);
      Add_Undirected_Edge (G, 4, 5);
      A (2).Power := 50.0;
      A (5).Power := 50.0;
      R := Run_WACA (G, A, F);
      for D in R.Role'Range loop
         case R.Role (D) is
            when Clusterhead => N_CH := N_CH + 1;
            when Sub_Head    => N_SH := N_SH + 1;
            when Slave       => N_SL := N_SL + 1;
         end case;
      end loop;
      Check (N_CH + N_SH + N_SL = 5, "roles partition |V|=5");
      Check (N_CH >= 1, "at least one CH");
      Check (R.Role (2) = Clusterhead, "boosted 2 is CH");
      Check (R.Role (5) = Clusterhead, "boosted 5 is CH");
      Check (Follow_To_Root (R.Clusterhead_Of, 1)
             = Follow_To_Root (R.Clusterhead_Of, 3),
             "triangle nodes share same root");
   end;

   ---------------------------------------------------------------------
   Section ("12. Unit-disk Build_Unit_Disk + Degree");
   ---------------------------------------------------------------------
   declare
      Pos : constant Position_Array (1 .. 3) :=
        [(0.0, 0.0), (1.0, 0.0), (10.0, 0.0)];
      G : constant Graph := Build_Unit_Disk (Pos, 1.5);
      G2 : constant Graph := Build_Unit_Disk (Pos, 0.5);
   begin
      Check (Degree (G, 1) = 1, "unit-disk: 1 neighbored to 2");
      Check (Degree (G, 2) = 1, "unit-disk: 2 neighbored to 1");
      Check (Degree (G, 3) = 0, "unit-disk: 3 isolated at R=1.5");
      Check (Degree (G2, 1) = 0, "short range isolates all");
      Check (Degree (G2, 2) = 0, "short range isolates 2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Compute_Weight composition + stability coefficient");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      A : Attrs_Array := Uniform_Attrs (3, Power => 1.718281828,
                                         Signal => 0.5, Ideal => 2);
      F : constant Weight_Factors :=
        (Wf1 => 1.0, Wf2 => 1.0, Wf3 => 1.0, Wf4 => 1.0);
      W : Real;
      Old_N, New_N : Node_Neighbors;
      S : Unit_Interval;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      Add_Undirected_Edge (G, 3, 1);
      --  Triangle, deg=2=ideal → DD=1, c_L=1, PA=ln(e)=1, s=0.5
      --  W0 = 1*1 + 1*0.5 + 1*1 + 1*1 = 3.5
      A (1).King_Bonus := 0.0;
      W := Compute_Weight (G, 1, A, F);
      Check (Approx (W, 3.5, 1.0E-4), "W0 composition = 3.5");
      A (1).King_Bonus := 10.0;
      W := Compute_Weight (G, 1, A, F);
      Check (Approx (W, 13.5, 1.0E-4), "W = W0 + K");

      Old_N := G (1);
      New_N := G (1);
      S := Stability_Coefficient (Old_N, New_N);
      Check (Approx (S, 0.0), "identical nbr sets → s=0");

      --  Remove one neighbor from New_N view
      New_N.Degree := 1;
      New_N.List (1) := 2;  -- lost 3; |MΔN|=1+0? Old has {2,3}, New {2}
      --  |Old\New|=1 (3), |New\Old|=0 → sym=1; den=2+1=3 → s=1/3
      S := Stability_Coefficient (Old_N, New_N);
      Check (Approx (S, 1.0 / 3.0), "partial churn s=1/3");

      declare
         Empty1, Empty2 : Node_Neighbors;
      begin
         Check (Approx (Stability_Coefficient (Empty1, Empty2), 0.0),
                "both empty → s=0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Capacity / empty helpers smoke");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (2);
      Huge : constant Graph := Empty_Graph (Max_Nodes);
   begin
      Check (Empty_Graph (0)'Length = 0, "Empty_Graph(0)");
      Check (Empty_Graph (1)'Length = 1, "Empty_Graph(1)");
      Add_Undirected_Edge (G, 1, 2);
      --  Idempotent re-add
      Add_Undirected_Edge (G, 1, 2);
      Check (Degree (G, 1) = 1, "re-add edge is idempotent");
      Check (Huge'Length = Max_Nodes, "Empty_Graph(Max_Nodes)");
      Check (Degree (Huge, 1) = 0, "Max_Nodes graph starts isolated");
   end;

   ---------------------------------------------------------------------
   Section ("15. King bonus churn reduction + Run_WACA defaults");
   ---------------------------------------------------------------------
   declare
      G : Graph := Empty_Graph (3);
      A : Attrs_Array := Uniform_Attrs (3, Power => 10.0, Signal => 0.4);
      R : WACA_Result (1, 3);
      Old_N, New_N : Node_Neighbors;
   begin
      Add_Undirected_Edge (G, 1, 2);
      Add_Undirected_Edge (G, 2, 3);
      A (2).Signal := 0.95;
      R := Run_WACA (G, A);  -- default factors
      Check (R.Role (2) = Clusterhead, "defaults: middle high-signal is CH");
      Check (R.Weights (2) > R.Weights (1), "defaults: W(2)>W(1)");

      A (2).King_Bonus := 66.0;
      Old_N := G (2);
      New_N := Old_N;
      --  Drop neighbor 3 from New_N
      New_N.Degree := 1;
      New_N.List (1) := 1;
      King_Bonus_Update (A, 2, True, Old_N, New_N);
      --  s = (|{1,3}\{1}| + |{1}\{1,3}|)/(2+1) = (1+0)/3 = 1/3
      --  K := 66 - 66*(1/3) = 44
      Check (Approx (A (2).King_Bonus, 44.0), "churn reduces K by K*s");

      --  Isolated CH → K=0
      declare
         Iso : Node_Neighbors;
      begin
         A (2).King_Bonus := 50.0;
         King_Bonus_Update (A, 2, True, Old_N, Iso);
         Check (Approx (A (2).King_Bonus, 0.0), "isolated CH → K=0");
      end;

      Check (Dissemination_Degree_Score (7, 7) >
             Dissemination_Degree_Score (1, 7),
             "DD peak beats far degree");
      Check (Power_Appropriateness (100.0) >
             Power_Appropriateness (10.0),
             "PA continues monotonic at high P");
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("======================================");
   pragma Assert (Fail_Count = 0);

exception
   when others =>
      Put_Line ("UNEXPECTED EXCEPTION");
      raise;
end Tests;
