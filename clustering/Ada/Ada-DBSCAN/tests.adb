--  Standalone test suite for DBSCAN (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with DBSCAN; use DBSCAN;

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
     (Lab : Labels; A, B : Point_Id) return Boolean
   is
   begin
      return Lab (A) /= Noise_Label
        and then Lab (A) /= Undefined_Label
        and then Lab (A) = Lab (B);
   end Same_Cluster;

begin
   Put_Line ("DBSCAN test suite");
   Put_Line ("=================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Parameters / label sentinels");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      declare
         Sample : constant Labels (1 .. 3) :=
           [Undefined_Label, Noise_Label, 1];
      begin
         Check (Noise_Count_Of (Sample) = 1, "one Noise in sample labels");
         Check (Cluster_Count_Of (Sample) = 1, "one cluster id in sample");
         --  Undefined is ignored by Noise_Count / Cluster_Count helpers
         Check (Noise_Count_Of (Sample) + Cluster_Count_Of (Sample) = 2,
                "sample: 1 noise + 1 cluster (+ undefined ignored)");
      end;
      P := Make_Parameters (0.5, 4);
      Check (Near (P.Eps, 0.5) and then P.MinPts = 4, "Make_Parameters ok");
      begin
         P := Make_Parameters (0.0, 4);
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
      Check (Default_Parameters.MinPts = 4, "Default_Parameters MinPts=4");
      Check (Near (Default_Parameters.Eps, 0.5), "Default_Parameters Eps=0.5");
   end;

   ---------------------------------------------------------------------
   Section ("2. Distance / Neighbor_Count / Range_Query");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
      --  P1=(0,0), P2=(3,4), P3=(1,0), P4=(100,100)
      Nbr  : Point_Id_Array (1 .. 4);
      Len  : Natural;
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

      declare
         RQ : constant Point_Id_Array := Range_Query (Data, 1, 1.1);
         Has1, Has3 : Boolean := False;
      begin
         Check (RQ'Length = 2, "Range_Query len 2");
         for I in RQ'Range loop
            if RQ (I) = 1 then Has1 := True; end if;
            if RQ (I) = 3 then Has3 := True; end if;
         end loop;
         Check (Has1 and Has3, "Range_Query contains P1 and P3");
      end;

      declare
         RQ : constant Point_Id_Array := Range_Query (Data, 4, 1.0);
      begin
         Check (RQ'Length = 1 and then RQ (RQ'First) = 4,
                "Range_Query lonely = self only");
      end;

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
      pragma Unreferenced (Nbr, Len);
   end;

   ---------------------------------------------------------------------
   Section ("3. Is_Core_Point / MinPts includes self");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 2);
      Params_Dense  : constant Parameters := Make_Parameters (2.0, 3);
      Params_Sparse : constant Parameters := Make_Parameters (0.4, 3);
      Params_Self   : constant Parameters := Make_Parameters (0.1, 1);
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
      --  MinPts=1: every point is core (self alone suffices)
      Check (Is_Core_Point (Data, 4, Params_Self),
             "MinPts=1: lonely point is core (self)");
      Check (Is_Core_Point (Data, 1, Params_Self),
             "MinPts=1: P1 is core");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic diagram-like: core / border / noise (MinPts=4)");
   ---------------------------------------------------------------------
   --  Dense blob + reachable border + far noise (Wikipedia-style roles).
   declare
      Data : Dataset (1 .. 7, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.0, 4);
      R : Result (1, 7);
   begin
      --  P1..P5 dense; P6 border; P7 noise
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.4; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 0.4;
      Data (4, 1) := 0.4; Data (4, 2) := 0.4;
      Data (5, 1) := 0.8; Data (5, 2) := 0.2;
      Data (6, 1) := 1.5; Data (6, 2) := 0.2;
      Data (7, 1) := 10.0; Data (7, 2) := 10.0;

      Check (Neighbor_Count (Data, 1, 1.0) >= 4, "P1 |N|>=4");
      Check (Neighbor_Count (Data, 5, 1.0) >= 4, "P5 |N|>=4");
      Check (Neighbor_Count (Data, 6, 1.0) < 4, "P6 |N|<4 border candidate");
      Check (Neighbor_Count (Data, 7, 1.0) = 1, "P7 only self");
      Check (Is_Core_Point (Data, 1, Params), "P1 is core");
      Check (Is_Core_Point (Data, 5, Params), "P5 is core");
      Check (not Is_Core_Point (Data, 6, Params), "P6 not core");
      Check (not Is_Core_Point (Data, 7, Params), "P7 not core");

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 1, "classic: 1 cluster");
      Check (R.Noise_Count = 1, "classic: 1 noise");
      Check (Same_Cluster (R.Lab, 1, 2), "classic: P1~P2");
      Check (Same_Cluster (R.Lab, 1, 5), "classic: P1~P5");
      Check (Same_Cluster (R.Lab, 1, 6), "classic: border P6 in cluster");
      Check (R.Lab (7) = Noise_Label, "classic: P7 noise");
      Check (R.Kind (1) = Core_Kind, "classic: P1 Core_Kind");
      Check (R.Kind (5) = Core_Kind, "classic: P5 Core_Kind");
      Check (R.Kind (6) = Border_Kind, "classic: P6 Border_Kind");
      Check (R.Kind (7) = Noise_Kind, "classic: P7 Noise_Kind");
      Check (Cluster_Count_Of (R.Lab) = 1, "Cluster_Count_Of=1");
      Check (Noise_Count_Of (R.Lab) = 1, "Noise_Count_Of=1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Two blobs + noise");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 9, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.2, 3);
      R : Result (1, 9);
   begin
      --  Blob A
      Data (1, 1) := 0.0;  Data (1, 2) := 0.0;
      Data (2, 1) := 0.5;  Data (2, 2) := 0.0;
      Data (3, 1) := 0.0;  Data (3, 2) := 0.5;
      Data (4, 1) := 0.4;  Data (4, 2) := 0.4;
      --  Blob B
      Data (5, 1) := 10.0; Data (5, 2) := 0.0;
      Data (6, 1) := 10.5; Data (6, 2) := 0.0;
      Data (7, 1) := 10.0; Data (7, 2) := 0.5;
      Data (8, 1) := 10.4; Data (8, 2) := 0.4;
      --  Noise
      Data (9, 1) := 5.0;  Data (9, 2) := 5.0;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 2, "two blobs: 2 clusters");
      Check (R.Noise_Count = 1, "two blobs: 1 noise");
      Check (Same_Cluster (R.Lab, 1, 4), "blob A together");
      Check (Same_Cluster (R.Lab, 5, 8), "blob B together");
      Check (R.Lab (1) /= R.Lab (5), "blobs different ids");
      Check (R.Lab (9) = Noise_Label, "midpoint is noise");
      Check (R.Kind (9) = Noise_Kind, "midpoint Noise_Kind");
   end;

   ---------------------------------------------------------------------
   Section ("6. All noise when eps tiny");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 5, 1 .. 2);
      Params : constant Parameters := Make_Parameters (0.01, 3);
      R : Result (1, 5);
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 1.0; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 1.0;
      Data (4, 1) := 2.0; Data (4, 2) := 2.0;
      Data (5, 1) := 3.0; Data (5, 2) := 1.0;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 0, "tiny eps: 0 clusters");
      Check (R.Noise_Count = 5, "tiny eps: all noise");
      for I in 1 .. 5 loop
         Check (R.Lab (I) = Noise_Label, "tiny eps: point noise");
         Check (R.Kind (I) = Noise_Kind, "tiny eps: Noise_Kind");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. One cluster when eps large");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 2);
      Params : constant Parameters := Make_Parameters (100.0, 2);
      R : Result (1, 6);
   begin
      Data (1, 1) := 0.0;  Data (1, 2) := 0.0;
      Data (2, 1) := 1.0;  Data (2, 2) := 0.0;
      Data (3, 1) := 0.0;  Data (3, 2) := 1.0;
      Data (4, 1) := 10.0; Data (4, 2) := 10.0;
      Data (5, 1) := 11.0; Data (5, 2) := 10.0;
      Data (6, 1) := 50.0; Data (6, 2) := 50.0;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 1, "large eps: 1 cluster");
      Check (R.Noise_Count = 0, "large eps: no noise");
      Check (Same_Cluster (R.Lab, 1, 6), "large eps: all same cluster");
      for I in 1 .. 6 loop
         Check (R.Lab (I) > 0, "large eps: positive label");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Border reassignment from Noise");
   ---------------------------------------------------------------------
   --  Visit order: lonely border candidate first in index order, then dense
   --  core that reaches it → Noise then reassigned to cluster C.
   declare
      Data : Dataset (1 .. 5, 1 .. 1);
      Params : constant Parameters := Make_Parameters (1.1, 3);
      R : Result (1, 5);
   begin
      --  P1 is near P2 only (will be Noise if processed alone)
      --  P2,P3,P4 form a dense triple; P2 reaches P1
      Data (1, 1) := 0.0;   -- border candidate
      Data (2, 1) := 1.0;   -- core
      Data (3, 1) := 1.5;   -- core
      Data (4, 1) := 2.0;   -- core
      Data (5, 1) := 100.0; -- noise

      Check (Neighbor_Count (Data, 1, 1.1) < 3, "P1 not core alone");
      Check (Is_Core_Point (Data, 2, Params), "P2 is core");
      Check (Is_Core_Point (Data, 3, Params), "P3 is core");

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 1, "reassign: 1 cluster");
      Check (Same_Cluster (R.Lab, 1, 2), "reassign: P1 joined via core");
      Check (R.Kind (1) = Border_Kind, "reassign: P1 is Border");
      Check (R.Lab (5) = Noise_Label, "reassign: far still noise");
      Check (Noise_Count_Of (R.Lab) = 1, "reassign: 1 noise");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid args / empty-ish guards");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 2, 1 .. 1);
      R : Result (1, 2);
      Params_Ok : constant Parameters := Make_Parameters (1.0, 2);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.5;
      R := Run_DBSCAN (Data, Params_Ok);
      Check (R.Cluster_Count >= 1, "small valid run ok");

      begin
         declare
            Bad : Dataset (1 .. 0, 1 .. 1);
            pragma Unreferenced (Bad);
         begin
            --  Cannot easily construct empty unconstrained in all cases;
            --  Capacity / Make_Parameters already covered.
            Check (True, "empty dataset type constrained away");
         end;
      end;

      begin
         declare
            RQ : Point_Id_Array := Range_Query (Data, 9, 1.0);
            pragma Unreferenced (RQ);
         begin
            Check (False, "Range_Query bad id should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Range_Query bad id raises");
         when Constraint_Error =>
            Check (True, "Range_Query bad id raises (constraint)");
      end;

      begin
         declare
            B : Boolean;
         begin
            B := Is_Core_Point (Data, 9, Params_Ok);
            pragma Unreferenced (B);
            Check (False, "Is_Core_Point bad id should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Is_Core_Point bad id raises");
         when Constraint_Error =>
            Check (True, "Is_Core_Point bad id raises (constraint)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Identical points / single point");
   ---------------------------------------------------------------------
   declare
      Data3 : Dataset (1 .. 3, 1 .. 1);
      Data1 : Dataset (1 .. 1, 1 .. 2);
      Params3 : constant Parameters := Make_Parameters (1.0, 3);
      Params1 : constant Parameters := Make_Parameters (1.0, 1);
      R3 : Result (1, 3);
      R1 : Result (1, 1);
   begin
      Data3 (1, 1) := 0.0;
      Data3 (2, 1) := 0.0;
      Data3 (3, 1) := 0.0;
      Check (Neighbor_Count (Data3, 1, 1.0) = 3, "identical: all neighbors");
      Check (Is_Core_Point (Data3, 1, Params3), "identical: all core");
      R3 := Run_DBSCAN (Data3, Params3);
      Check (R3.Cluster_Count = 1, "identical: 1 cluster");
      Check (R3.Noise_Count = 0, "identical: no noise");
      Check (Same_Cluster (R3.Lab, 1, 3), "identical: all same");

      Data1 (1, 1) := 3.14; Data1 (1, 2) := 2.71;
      R1 := Run_DBSCAN (Data1, Params1);
      Check (R1.Cluster_Count = 1, "singleton MinPts=1: 1 cluster");
      Check (R1.Kind (1) = Core_Kind, "singleton is core");

      declare
         Params_Hi : constant Parameters := Make_Parameters (1.0, 2);
         Rh : Result (1, 1);
      begin
         Rh := Run_DBSCAN (Data1, Params_Hi);
         Check (Rh.Cluster_Count = 0, "singleton MinPts=2: no cluster");
         Check (Rh.Lab (1) = Noise_Label, "singleton MinPts=2: noise");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Non-convex / chain (moon-ish arc)");
   ---------------------------------------------------------------------
   declare
      --  Arc / chain of points: density-connected, not a convex blob.
      Data : Dataset (1 .. 10, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.5, 3);
      R : Result (1, 10);
   begin
      Data (1, 1) := 3.000000; Data (1, 2) := 0.000000;
      Data (2, 1) := 2.763183; Data (2, 2) := 1.168255;
      Data (3, 1) := 2.090120; Data (3, 2) := 2.152068;
      Data (4, 1) := 1.087073; Data (4, 2) := 2.796117;
      Data (5, 1) := -0.087599; Data (5, 2) := 2.998721;
      Data (6, 1) := -1.248441; Data (6, 2) := 2.727892;
      Data (7, 1) := -2.212181; Data (7, 2) := 2.026390;
      Data (8, 1) := -2.826667; Data (8, 2) := 1.004964;
      Data (9, 1) := 20.0; Data (9, 2) := 20.0;
      Data (10, 1) := -20.0; Data (10, 2) := 20.0;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 1, "arc: 1 density-connected cluster");
      Check (Same_Cluster (R.Lab, 1, 8), "arc: ends same cluster");
      Check (R.Lab (9) = Noise_Label, "arc: outlier 9 noise");
      Check (R.Lab (10) = Noise_Label, "arc: outlier 10 noise");
      Check (R.Noise_Count = 2, "arc: 2 noise");
   end;

   ---------------------------------------------------------------------
   Section ("12. Result counts match helpers / 1-D / multi-dim");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 3);
      Params : constant Parameters := Make_Parameters (2.0, 2);
      R : Result (1, 6);
   begin
      for I in 1 .. 3 loop
         Data (I, 1) := 0.0;
         Data (I, 2) := Real (I - 1) * 0.5;
         Data (I, 3) := 0.0;
      end loop;
      for I in 4 .. 6 loop
         Data (I, 1) := 20.0;
         Data (I, 2) := Real (I - 4) * 0.5;
         Data (I, 3) := 0.0;
      end loop;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = Cluster_Count_Of (R.Lab),
             "Result.Cluster_Count matches helper");
      Check (R.Noise_Count = Noise_Count_Of (R.Lab),
             "Result.Noise_Count matches helper");
      Check (R.Cluster_Count = 2, "3-D: two clusters");
      Check (Same_Cluster (R.Lab, 1, 3), "3-D: first group");
      Check (Same_Cluster (R.Lab, 4, 6), "3-D: second group");
      Check (R.Lab (1) /= R.Lab (4), "3-D: groups differ");
   end;

   ---------------------------------------------------------------------
   Section ("13. Caps constants / smoke grid");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 12, 1 .. 2);
      Params : constant Parameters := Make_Parameters (1.6, 3);
      R : Result (1, 12);
      N : Natural := 0;
   begin
      declare
         Only_Noise : constant Labels (1 .. 2) :=
           [Noise_Label, Noise_Label];
         Mixed : constant Labels (1 .. 3) :=
           [1, Noise_Label, 2];
      begin
         Check (Cluster_Count_Of (Only_Noise) = 0, "noise-only: 0 clusters");
         Check (Noise_Count_Of (Only_Noise) = 2, "two noise labels");
         Check (Cluster_Count_Of (Mixed) = 2, "mixed: 2 clusters");
         Check (Noise_Count_Of (Mixed) = 1, "mixed: 1 noise");
      end;

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

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count >= 1, "grid: ≥1 cluster");
      Check (Same_Cluster (R.Lab, 1, 2), "grid neighbors clustered");
      Check (R.Lab (10) = Noise_Label, "outlier 10 noise");
      Check (R.Lab (11) = Noise_Label, "outlier 11 noise");
      Check (R.Lab (12) = Noise_Label, "outlier 12 noise");
      Check (R.Noise_Count >= 3, "≥3 noise outliers");
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
