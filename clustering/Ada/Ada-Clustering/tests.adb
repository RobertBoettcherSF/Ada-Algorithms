with Ada.Text_IO; use Ada.Text_IO;
with Cluster_Analysis;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   package CA_2D is new Cluster_Analysis (Dimensions => 2);
   use type CA_2D.Coordinate;
   use type CA_2D.Cluster_ID;

   package CA_3D is new Cluster_Analysis (Dimensions => 3);
   use type CA_3D.Coordinate;
   use type CA_3D.Cluster_ID;

   -- Test variables
   P1_2D : constant CA_2D.Point := [0.0, 0.0];
   P2_2D : constant CA_2D.Point := [3.0, 4.0];

   Data_2D : constant CA_2D.Point_Array (1 .. 4) :=
     [[0.0, 0.0], [0.1, 0.1], [10.0, 10.0], [10.1, 10.1]];
   Assign_2D : CA_2D.Cluster_Assignment (1 .. 4);
   Cents_2D  : CA_2D.Point_Array (1 .. 2);

   Data_3D : constant CA_3D.Point_Array (1 .. 3) :=
     [[0.0, 0.0, 0.0], [10.0, 10.0, 10.0], [20.0, 20.0, 20.0]];
   Assign_3D : CA_3D.Cluster_Assignment (1 .. 3);
   Cents_3D  : CA_3D.Point_Array (1 .. 3);

   -- Helpers for floating point equality tests
   function Is_Close (A, B : CA_2D.Coordinate) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;

   function Is_Close (A, B : CA_3D.Coordinate) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;

begin
   Put_Line ("TEST 1 — Euclidean Distance 2D");
   Check ("1.1 Dist(0,0 to 3,4) = 5", Is_Close (CA_2D.Euclidean_Distance (P1_2D, P2_2D), 5.0));
   Check ("1.2 Dist(P,P) = 0", Is_Close (CA_2D.Euclidean_Distance (P1_2D, P1_2D), 0.0));
   Check ("1.3 Dist is symmetric", CA_2D.Euclidean_Distance (P1_2D, P2_2D) = CA_2D.Euclidean_Distance (P2_2D, P1_2D));

   Put_Line ("TEST 2 — Manhattan Distance 2D");
   Check ("2.1 Dist(0,0 to 3,4) = 7", Is_Close (CA_2D.Manhattan_Distance (P1_2D, P2_2D), 7.0));
   Check ("2.2 Dist(P,P) = 0", Is_Close (CA_2D.Manhattan_Distance (P1_2D, P1_2D), 0.0));
   Check ("2.3 Dist is symmetric", CA_2D.Manhattan_Distance (P1_2D, P2_2D) = CA_2D.Manhattan_Distance (P2_2D, P1_2D));

   Put_Line ("TEST 3 — K-Means 2D Basic");
   CA_2D.K_Means (Data_2D, 2, 10, Assign_2D, Cents_2D);
   Check ("3.1 Group 1 matching", Assign_2D(1) = Assign_2D(2));
   Check ("3.2 Group 2 matching", Assign_2D(3) = Assign_2D(4));
   Check ("3.3 Distinct groups", Assign_2D(1) /= Assign_2D(3));

   Put_Line ("TEST 4 — K-Medians 2D Basic");
   CA_2D.K_Medians (Data_2D, 2, 10, Assign_2D, Cents_2D);
   Check ("4.1 Group 1 matching", Assign_2D(1) = Assign_2D(2));
   Check ("4.2 Group 2 matching", Assign_2D(3) = Assign_2D(4));
   Check ("4.3 Distinct groups", Assign_2D(1) /= Assign_2D(3));

   Put_Line ("TEST 5 — K-Means 2D Centroid Convergence");
   declare
      C1_Correct : constant Boolean := Is_Close(Cents_2D(1)(1), 0.05) or Is_Close(Cents_2D(1)(1), 10.05);
      C2_Correct : constant Boolean := Is_Close(Cents_2D(2)(1), 0.05) or Is_Close(Cents_2D(2)(1), 10.05);
   begin
      Check ("5.1 Centroid 1 X is correct", C1_Correct);
      Check ("5.2 Centroid 2 X is correct", C2_Correct);
      Check ("5.3 Centroids are distinct", Cents_2D(1)(1) /= Cents_2D(2)(1));
   end;

   Put_Line ("TEST 6 — Calculate_Inertia Euclidean");
   declare
      Inertia : constant CA_2D.Coordinate := CA_2D.Calculate_Inertia(Data_2D, Assign_2D, Cents_2D, False);
   begin
      Check ("6.1 Inertia > 0", Inertia > 0.0);
      Check ("6.2 Inertia < 1.0", Inertia < 1.0);
      Check ("6.3 Deterministic result", Inertia = CA_2D.Calculate_Inertia(Data_2D, Assign_2D, Cents_2D, False));
   end;

   Put_Line ("TEST 7 — Calculate_Inertia Manhattan");
   declare
      Inertia : constant CA_2D.Coordinate := CA_2D.Calculate_Inertia(Data_2D, Assign_2D, Cents_2D, True);
   begin
      Check ("7.1 Inertia > 0", Inertia > 0.0);
      Check ("7.2 Inertia approx 0.4", Is_Close (Inertia, 0.4));
      Check ("7.3 Inertia > Euclidean Inertia", Inertia > CA_2D.Calculate_Inertia(Data_2D, Assign_2D, Cents_2D, False));
   end;

   Put_Line ("TEST 8 — K-Means 3D K=3");
   CA_3D.K_Means (Data_3D, 3, 10, Assign_3D, Cents_3D);
   Check ("8.1 Group 1 unique", Assign_3D(1) /= Assign_3D(2) and then Assign_3D(1) /= Assign_3D(3));
   Check ("8.2 Group 2 unique", Assign_3D(2) /= Assign_3D(3));
   Check ("8.3 Centroids match data", Is_Close(Cents_3D(1)(1), 0.0) and then Is_Close(Cents_3D(3)(1), 20.0));

   Put_Line ("TEST 9 — K-Medians 3D K=3");
   CA_3D.K_Medians (Data_3D, 3, 10, Assign_3D, Cents_3D);
   Check ("9.1 Group 1 unique", Assign_3D(1) /= Assign_3D(2) and then Assign_3D(1) /= Assign_3D(3));
   Check ("9.2 Group 2 unique", Assign_3D(2) /= Assign_3D(3));
   Check ("9.3 Centroids match data", Is_Close(Cents_3D(1)(2), 0.0) and then Is_Close(Cents_3D(2)(2), 10.0));

   Put_Line ("TEST 10 — Single Iteration Limit");
   declare
      Data_Edge   : constant CA_2D.Point_Array (1 .. 3) := [[0.0, 0.0], [1.0, 1.0], [10.0, 10.0]];
      Assign_Edge : CA_2D.Cluster_Assignment (1 .. 3);
      Cents_Edge  : CA_2D.Point_Array (1 .. 2);
   begin
      CA_2D.K_Means (Data_Edge, 2, 1, Assign_Edge, Cents_Edge);
      Check ("10.1 First point in C1", Assign_Edge(1) = 1);
      Check ("10.2 Second point in C2", Assign_Edge(2) = 2);
      Check ("10.3 Third point in C2", Assign_Edge(3) = 2);
      Check ("10.4 Centroid 1 X is updated", Is_Close (Cents_Edge(1)(1), 0.0));
   end;

   Put_Line ("TEST 11 — K=1 Edge Case K-Means");
   declare
      Cents_1 : CA_2D.Point_Array (1 .. 1);
   begin
      CA_2D.K_Means (Data_2D, 1, 10, Assign_2D, Cents_1);
      Check ("11.1 All points in C1", Assign_2D(1) = 1 and then Assign_2D(4) = 1);
      Check ("11.2 Centroid X is mean", Is_Close (Cents_1(1)(1), 5.05));
      Check ("11.3 Centroid Y is mean", Is_Close (Cents_1(1)(2), 5.05));
   end;

   Put_Line ("TEST 12 — K=1 Edge Case K-Medians");
   declare
      Cents_1 : CA_2D.Point_Array (1 .. 1);
   begin
      CA_2D.K_Medians (Data_2D, 1, 10, Assign_2D, Cents_1);
      Check ("12.1 All points in C1", Assign_2D(1) = 1 and then Assign_2D(4) = 1);
      Check ("12.2 Centroid X is median", Is_Close (Cents_1(1)(1), 5.05)); 
      Check ("12.3 Centroid Y is median", Is_Close (Cents_1(1)(2), 5.05));
   end;

   Put_Line ("TEST 13 — Exception on Precondition Failure");
   declare
      Bad_Assign : CA_2D.Cluster_Assignment (1 .. 2); 
      pragma Warnings (Off, Bad_Assign);
   begin
      CA_2D.K_Means (Data_2D, 2, 10, Bad_Assign, Cents_2D);
      Check ("13.1 Should not reach here", False);
      Check ("13.2 Should not reach here", False);
      Check ("13.3 Should not reach here", False);
   exception
      when others =>
         Check ("13.1 Exception caught", True);
         Check ("13.2 Handled cleanly", True);
         Check ("13.3 Precondition protected execution", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
