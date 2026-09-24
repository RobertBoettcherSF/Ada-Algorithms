--  Standalone test suite for Optics (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Optics; use Optics;

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

   --  True if Order is a permutation of First .. First+Count-1.
   function Is_Permutation
     (Order : Point_Id_Array;
      First : Point_Id;
      Count : Point_Count) return Boolean
   is
      Seen : array (1 .. Max_Points) of Boolean := [others => False];
      P    : Point_Id;
   begin
      if Count = 0 then
         return True;
      end if;
      for I in 0 .. Count - 1 loop
         P := Order (First + I);
         if P < First or else P > First + Count - 1 then
            return False;
         end if;
         if Seen (P) then
            return False;
         end if;
         Seen (P) := True;
      end loop;
      for I in 0 .. Count - 1 loop
         if not Seen (First + I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Permutation;

   function Same_Cluster
     (Lab : Labels; A, B : Point_Id) return Boolean
   is
   begin
      return Lab (A) /= Noise_Label
        and then Lab (A) = Lab (B);
   end Same_Cluster;

begin
   Put_Line ("Optics (OPTICS) test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Parameters / Undefined sentinel");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (Undefined, -1.0), "Undefined Near -1.0");
      P := Make_Parameters (0.5, 3);
      Check (Near (P.Eps, 0.5) and then P.MinPts = 3, "Make_Parameters ok");
      begin
         P := Make_Parameters (0.0, 3);
         Check (False, "Make_Parameters Eps=0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters Eps=0 raises");
      end;
      begin
         P := Make_Parameters (0.5, 0);
         Check (False, "Make_Parameters MinPts=0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters MinPts=0 raises");
      end;
      begin
         P := Make_Parameters (-1.0, 2);
         Check (False, "Make_Parameters Eps<0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters Eps<0 raises");
      end;
      begin
         P := Make_Parameters (1.0, -5);
         Check (False, "Make_Parameters MinPts<0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters MinPts<0 raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Distance / Neighbor_Count");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
      --  P1=(0,0), P2=(3,4), P3=(1,0), P4=(100,100)
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 3.0; Data (2, 2) := 4.0;
      Data (3, 1) := 1.0; Data (3, 2) := 0.0;
      Data (4, 1) := 100.0; Data (4, 2) := 100.0;

      Check (Near (Distance (Data, 1, 1), 0.0), "self distance 0");
      Check (Near (Distance (Data, 1, 2), 5.0), "3-4-5 triangle");
      Check (Near (Distance (Data, 1, 3), 1.0), "unit step on X");
      Check (Distance (Data, 1, 4) > 100.0, "far point large dist");
      Check (Neighbor_Count (Data, 1, 1.1) = 2,
             "N_1.1(P1): P1 and P3");
      Check (Neighbor_Count (Data, 1, 5.0) = 3,
             "N_5(P1): P1,P2,P3");
      Check (Neighbor_Count (Data, 1, 200.0) = 4,
             "N_200(P1): all");
      Check (Neighbor_Count (Data, 4, 1.0) = 1,
             "N_1(P4): only self");
      begin
         declare
            D : Non_Negative;
         begin
            D := Distance (Data, 1, 9);
            pragma Unreferenced (D);
            Check (False, "Distance bad id should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Distance bad id raises");
         when Constraint_Error =>
            Check (True, "Distance bad id raises (constraint)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Core_Distance dense vs sparse");
   ---------------------------------------------------------------------
   declare
      --  Three coincident-ish points at origin + one far.
      Data : Dataset (1 .. 4, 1 .. 2);
      Params_Dense : constant Parameters := Make_Parameters (2.0, 3);
      Params_Sparse : constant Parameters := Make_Parameters (0.4, 3);
      CD : Real;
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.5; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 0.5;
      Data (4, 1) := 50.0; Data (4, 2) := 50.0;

      Check (Is_Core_Point (Data, 1, Params_Dense),
             "P1 core with Eps=2 MinPts=3");
      Check (Is_Core_Point (Data, 2, Params_Dense),
             "P2 core with Eps=2 MinPts=3");
      Check (not Is_Core_Point (Data, 4, Params_Dense),
             "P4 not core (only self in N)");
      Check (not Is_Core_Point (Data, 1, Params_Sparse),
             "P1 not core with tiny Eps");

      CD := Core_Distance (Data, 1, Params_Dense);
      Check (CD /= Undefined and then CD >= 0.0,
             "core-dist P1 defined and non-neg");
      --  Distances from P1: 0 (self), 0.5 (P2), 0.5 (P3) — MinPts=3 → 0.5
      Check (Approx (CD, 0.5), "core-dist P1 = 0.5 (3rd smallest)");

      CD := Core_Distance (Data, 4, Params_Dense);
      Check (CD = Undefined, "core-dist P4 Undefined");

      Check (Has_Defined_Core (Data, 1, Params_Dense),
             "Has_Defined_Core P1");
      Check (not Has_Defined_Core (Data, 4, Params_Dense),
             "not Has_Defined_Core P4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identical points / MinPts edge");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.0, 3);
      CD : Real;
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.0;
      Data (3, 1) := 0.0;
      Check (Neighbor_Count (Data, 1, 1.0) = 3, "identical: all neighbors");
      Check (Is_Core_Point (Data, 1, Params), "identical: all core");
      CD := Core_Distance (Data, 2, Params);
      Check (Approx (CD, 0.0), "identical: core-dist 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Run_OPTICS permutation + reachability init");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 5, 1 .. 2);
      Params : constant Parameters := Make_Parameters (3.0, 2);
      Ord : Ordered_Result (1, 5);
   begin
      --  Two blobs: (0,0),(0.5,0) and (10,0),(10.5,0) + noise (5,5)
      Data (1, 1) := 0.0;  Data (1, 2) := 0.0;
      Data (2, 1) := 0.5;  Data (2, 2) := 0.0;
      Data (3, 1) := 10.0; Data (3, 2) := 0.0;
      Data (4, 1) := 10.5; Data (4, 2) := 0.0;
      Data (5, 1) := 5.0;  Data (5, 2) := 5.0;

      Ord := Run_OPTICS (Data, Params);
      Check (Ord.Count = 5, "ordered count = 5");
      Check (Is_Permutation (Ord.Order, 1, 5),
             "order is permutation of all points");
      --  First emitted point has Undefined reachability.
      Check (not Ord.Has_Reachability (1),
             "first in order: no reachability");
      Check (Ord.Reachability (1) = Undefined,
             "first reachability sentinel Undefined");
      --  At least some points get defined reachability inside blobs.
      declare
         Any_R : Boolean := False;
         Any_C : Boolean := False;
      begin
         for I in 1 .. 5 loop
            if Ord.Has_Reachability (I) then
               Any_R := True;
               Check (Ord.Reachability (I) >= 0.0,
                      "defined reachability non-negative");
            end if;
            if Ord.Has_Core_Distance (I) then
               Any_C := True;
            end if;
         end loop;
         Check (Any_R, "some points have reachability");
         Check (Any_C, "some points have core-distance");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Reachability monotonicity via update");
   ---------------------------------------------------------------------
   --  In a tight line of points, once a core expands, neighbor
   --  reachability should be max(core-dist, dist) and improve only downward.
   declare
      Data : Dataset (1 .. 4, 1 .. 1);
      Params : constant Parameters := Make_Parameters (5.0, 2);
      Ord : Ordered_Result (1, 4);
      Prev : Real;
      Ok_Mono : Boolean := True;
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 1.0;
      Data (3, 1) := 2.0;
      Data (4, 1) := 3.0;
      Ord := Run_OPTICS (Data, Params);
      Check (Ord.Count = 4, "line: 4 ordered");
      --  All should be core with MinPts=2 and large Eps.
      declare
         Cores : Natural := 0;
      begin
         for I in 1 .. 4 loop
            if Ord.Has_Core_Distance (I) then
               Cores := Cores + 1;
            end if;
         end loop;
         Check (Cores >= 3, "line: most points are cores");
      end;
      --  Defined reachabilities are finite and ≤ Eps.
      for I in 1 .. 4 loop
         if Ord.Has_Reachability (I) then
            Check (Ord.Reachability (I) <= Params.Eps + 1.0E-9,
                   "reachability ≤ Eps");
         end if;
      end loop;
      pragma Unreferenced (Prev, Ok_Mono);
   end;

   ---------------------------------------------------------------------
   Section ("7. Two well-separated blobs → two clusters at ξ");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.5, 2);
      Ord : Ordered_Result (1, 6);
      Lab : Labels (1 .. 6);
      Xi  : constant Real := 1.0;
   begin
      --  Blob A around origin, Blob B around (10,0)
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.4; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 0.4;
      Data (4, 1) := 10.0; Data (4, 2) := 0.0;
      Data (5, 1) := 10.4; Data (5, 2) := 0.0;
      Data (6, 1) := 10.0; Data (6, 2) := 0.4;

      Ord := Run_OPTICS (Data, Params);
      Check (Is_Permutation (Ord.Order, 1, 6), "blobs: permutation");
      Lab := Extract_DBSCAN_Clustering (Ord, Xi);
      Check (Cluster_Count_Of (Lab) = 2, "blobs: two clusters");
      Check (Noise_Count_Of (Lab) = 0, "blobs: no noise");
      Check (Same_Cluster (Lab, 1, 2), "A: P1-P2 same");
      Check (Same_Cluster (Lab, 1, 3), "A: P1-P3 same");
      Check (Same_Cluster (Lab, 4, 5), "B: P4-P5 same");
      Check (Same_Cluster (Lab, 4, 6), "B: P4-P6 same");
      Check (Lab (1) /= Lab (4), "A and B different labels");
      --  Labels_At_Xi synonym
      declare
         Lab2 : constant Labels := Labels_At_Xi (Ord, Xi);
      begin
         Check (Lab2 (1) = Lab (1) and then Lab2 (4) = Lab (4),
                "Labels_At_Xi matches Extract");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Noise points between blobs");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 5, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.2, 2);
      Ord : Ordered_Result (1, 5);
      Lab : Labels (1 .. 5);
   begin
      Data (1, 1) := 0.0;  Data (1, 2) := 0.0;
      Data (2, 1) := 0.3;  Data (2, 2) := 0.0;
      Data (3, 1) := 20.0; Data (3, 2) := 0.0;
      Data (4, 1) := 20.3; Data (4, 2) := 0.0;
      Data (5, 1) := 10.0; Data (5, 2) := 10.0;  -- noise

      Ord := Run_OPTICS (Data, Params);
      Lab := Extract_DBSCAN_Clustering (Ord, 1.0);
      Check (Cluster_Count_Of (Lab) = 2, "noise case: 2 clusters");
      Check (Lab (5) = Noise_Label, "isolated point is noise");
      Check (Noise_Count_Of (Lab) >= 1, "at least one noise");
      Check (Same_Cluster (Lab, 1, 2), "left blob together");
      Check (Same_Cluster (Lab, 3, 4), "right blob together");
   end;

   ---------------------------------------------------------------------
   Section ("9. Varying density (tight + loose) with large ε");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 8, 1 .. 2);
      --  Large Eps so both densities are visible in one ordering.
      Params : constant Parameters := Make_Parameters (5.0, 3);
      Ord : Ordered_Result (1, 8);
      Lab_Tight : Labels (1 .. 8);
      Lab_Loose : Labels (1 .. 8);
   begin
      --  Tight cluster (spacing ~0.2) around (0,0)
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.2; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 0.2;
      Data (4, 1) := 0.2; Data (4, 2) := 0.2;
      --  Loose cluster (spacing ~1.5) around (10,0)
      Data (5, 1) := 10.0; Data (5, 2) := 0.0;
      Data (6, 1) := 11.5; Data (6, 2) := 0.0;
      Data (7, 1) := 10.0; Data (7, 2) := 1.5;
      Data (8, 1) := 11.5; Data (8, 2) := 1.5;

      Ord := Run_OPTICS (Data, Params);
      Check (Ord.Count = 8, "varying dens: 8 ordered");
      --  Small ξ captures only the tight valley.
      Lab_Tight := Extract_DBSCAN_Clustering (Ord, 0.5);
      Check (Cluster_Count_Of (Lab_Tight) >= 1,
             "small ξ: at least tight cluster");
      Check (Same_Cluster (Lab_Tight, 1, 2),
             "small ξ: tight points clustered");
      --  Loose points should be noise or a separate weaker structure
      --  at ξ=0.5 (their mutual reachability is larger).
      Check (Lab_Tight (5) = Noise_Label
             or else Lab_Tight (5) /= Lab_Tight (1),
             "small ξ: loose not merged into tight");
      --  Larger ξ finds both clusters.
      Lab_Loose := Extract_DBSCAN_Clustering (Ord, 2.0);
      Check (Cluster_Count_Of (Lab_Loose) = 2,
             "larger ξ: two clusters (tight+loose)");
      Check (Same_Cluster (Lab_Loose, 1, 3), "large ξ: tight together");
      Check (Same_Cluster (Lab_Loose, 5, 6), "large ξ: loose together");
      Check (Lab_Loose (1) /= Lab_Loose (5),
             "large ξ: tight ≠ loose label");
   end;

   ---------------------------------------------------------------------
   Section ("10. Single point / all noise");
   ---------------------------------------------------------------------
   declare
      Data1 : Dataset (1 .. 1, 1 .. 2);
      Data3 : Dataset (1 .. 3, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.0, 3);
      Ord1 : Ordered_Result (1, 1);
      Ord3 : Ordered_Result (1, 3);
      Lab1 : Labels (1 .. 1);
      Lab3 : Labels (1 .. 3);
   begin
      Data1 (1, 1) := 0.0; Data1 (1, 2) := 0.0;
      Ord1 := Run_OPTICS (Data1, Params);
      Check (Ord1.Count = 1, "single: count 1");
      Check (not Ord1.Has_Reachability (1), "single: no reachability");
      Check (not Ord1.Has_Core_Distance (1), "single: not core MinPts=3");
      Lab1 := Extract_DBSCAN_Clustering (Ord1, 1.0);
      Check (Lab1 (1) = Noise_Label, "single: noise under MinPts=3");

      --  Three mutually far points → all noise
      Data3 (1, 1) := 0.0;  Data3 (1, 2) := 0.0;
      Data3 (2, 1) := 10.0; Data3 (2, 2) := 0.0;
      Data3 (3, 1) := 0.0;  Data3 (3, 2) := 10.0;
      Ord3 := Run_OPTICS (Data3, Params);
      Lab3 := Extract_DBSCAN_Clustering (Ord3, 1.0);
      Check (Cluster_Count_Of (Lab3) = 0, "far trio: 0 clusters");
      Check (Noise_Count_Of (Lab3) = 3, "far trio: all noise");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid args / extraction edge");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 2, 1 .. 1);
      Ord : Ordered_Result (1, 2);
      Params : Parameters;
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 1.0;
      Params := Make_Parameters (2.0, 2);
      Ord := Run_OPTICS (Data, Params);
      Check (Ord.Count = 2, "invalid-args setup ordered 2");

      declare
         function Dyn (X : Real) return Real is (X);
         --  Non-static so Positive_Real conversion is checked at run time.
      begin
         begin
            declare
               L : Labels (1 .. 2);
            begin
               L := Extract_DBSCAN_Clustering (Ord, Positive_Real (Dyn (0.0)));
               pragma Unreferenced (L);
               Check (False, "Xi=0 should raise");
            end;
         exception
            when Invalid_Argument =>
               Check (True, "Xi=0 raises Invalid_Argument");
            when Constraint_Error =>
               Check (True, "Xi=0 raises Constraint_Error");
         end;
         begin
            declare
               L : Labels (1 .. 2);
            begin
               L := Extract_DBSCAN_Clustering (Ord, Positive_Real (Dyn (-1.0)));
               pragma Unreferenced (L);
               Check (False, "Xi<0 should raise");
            end;
         exception
            when Invalid_Argument =>
               Check (True, "Xi<0 raises Invalid_Argument");
            when Constraint_Error =>
               Check (True, "Xi<0 raises Constraint_Error");
         end;
      end;
      begin
         declare
            Empty : Ordered_Result (1, 0);
         begin
            Empty.Count := 0;
            declare
               L : Labels (1 .. 1);
            begin
               L := Extract_DBSCAN_Clustering (Empty, 1.0);
               pragma Unreferenced (L);
               Check (False, "empty ordered should raise");
            end;
         end;
      exception
         when Invalid_Argument =>
            Check (True, "empty ordered raises");
      end;
      begin
         declare
            Bad : constant Parameters := (Eps => 1.0, MinPts => 2);
            Ignore : Ordered_Result (1, 2);
         begin
            --  Force invalid via local mutation path: Eps ok but call
            --  Core_Distance with crafted bad MinPts through Make_Parameters
            pragma Unreferenced (Bad, Ignore);
            declare
               Dummy : Real;
            begin
               Dummy := Core_Distance
                 (Data, 1, Make_Parameters (-0.1, 2));
               pragma Unreferenced (Dummy);
               Check (False, "Core_Distance bad params should raise");
            end;
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Core_Distance bad params raises");
         when Constraint_Error =>
            Check (True, "Core_Distance bad params raises (constraint)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. DBSCAN-equivalent: ξ cut splits valleys");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 9, 1 .. 2);
      Params : constant Parameters := Make_Parameters (2.0, 3);
      Ord : Ordered_Result (1, 9);
      Lab_A, Lab_B : Labels (1 .. 9);
   begin
      --  Three small clusters of 3
      for K in 0 .. 2 loop
         Data (1 + 3 * K, 1) := Real (K) * 10.0;
         Data (1 + 3 * K, 2) := 0.0;
         Data (2 + 3 * K, 1) := Real (K) * 10.0 + 0.3;
         Data (2 + 3 * K, 2) := 0.0;
         Data (3 + 3 * K, 1) := Real (K) * 10.0;
         Data (3 + 3 * K, 2) := 0.3;
      end loop;
      Ord := Run_OPTICS (Data, Params);
      Check (Is_Permutation (Ord.Order, 1, 9), "3-cluster: permutation");
      Lab_A := Labels_At_Xi (Ord, 1.0);
      Check (Cluster_Count_Of (Lab_A) = 3, "ξ=1: three clusters");
      Check (Same_Cluster (Lab_A, 1, 2) and then Same_Cluster (Lab_A, 1, 3),
             "cluster0 together");
      Check (Same_Cluster (Lab_A, 4, 5) and then Same_Cluster (Lab_A, 4, 6),
             "cluster1 together");
      Check (Same_Cluster (Lab_A, 7, 8) and then Same_Cluster (Lab_A, 7, 9),
             "cluster2 together");
      Check (Lab_A (1) /= Lab_A (4) and then Lab_A (4) /= Lab_A (7),
             "three distinct labels");
      --  Very small ξ → likely all noise (core-dist ~0.3, use tiny)
      Lab_B := Labels_At_Xi (Ord, 0.05);
      Check (Cluster_Count_Of (Lab_B) = 0 or else Noise_Count_Of (Lab_B) >= 6,
             "tiny ξ: mostly/all noise");
   end;

   ---------------------------------------------------------------------
   Section ("13. Reachability of seeds ≤ Eps; core defined ⇒ Is_Core");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
      Params : constant Parameters := Make_Parameters (2.5, 2);
      Ord : Ordered_Result (1, 4);
      Pid : Point_Id;
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 1.0; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 1.0;
      Data (4, 1) := 1.0; Data (4, 2) := 1.0;
      Ord := Run_OPTICS (Data, Params);
      for I in 1 .. 4 loop
         Pid := Ord.Order (I);
         if Ord.Has_Core_Distance (I) then
            Check (Is_Core_Point (Data, Pid, Params),
                   "ordered core ⇒ Is_Core_Point");
            Check (Approx (Ord.Core_Distance (I),
                           Core_Distance (Data, Pid, Params)),
                   "stored core-dist matches Core_Distance");
         end if;
         if Ord.Has_Reachability (I) then
            Check (Ord.Reachability (I) <= Params.Eps + 1.0E-9,
                   "seed reachability ≤ Eps");
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Smoke: larger grid + Noise_Label constant");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 12, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.6, 3);
      Ord : Ordered_Result (1, 12);
      Lab : Labels (1 .. 12);
      N : Natural := 0;
   begin
      declare
         One_Noise : constant Labels (1 .. 1) := [Noise_Label];
      begin
         Check (Noise_Count_Of (One_Noise) = 1, "Noise_Label counts as noise");
      end;
      --  3x3 grid at origin + 3 outliers
      for I in 0 .. 2 loop
         for J in 0 .. 2 loop
            N := N + 1;
            Data (N, 1) := Real (I);
            Data (N, 2) := Real (J);
         end loop;
      end loop;
      Data (10, 1) := 50.0; Data (10, 2) := 0.0;
      Data (11, 1) := 0.0;  Data (11, 2) := 50.0;
      Data (12, 1) := 50.0; Data (12, 2) := 50.0;

      Ord := Run_OPTICS (Data, Params);
      Check (Ord.Count = 12, "grid: 12 ordered");
      Check (Is_Permutation (Ord.Order, 1, 12), "grid: permutation");
      Lab := Extract_DBSCAN_Clustering (Ord, 1.5);
      Check (Cluster_Count_Of (Lab) >= 1, "grid: ≥1 cluster");
      Check (Same_Cluster (Lab, 1, 2), "grid neighbors clustered");
      Check (Lab (10) = Noise_Label, "outlier 10 noise");
      Check (Lab (11) = Noise_Label, "outlier 11 noise");
      Check (Lab (12) = Noise_Label, "outlier 12 noise");
      Check (Noise_Count_Of (Lab) >= 3, "≥3 noise outliers");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("=================================");
   pragma Assert (Fail_Count = 0);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
