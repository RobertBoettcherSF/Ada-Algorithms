--  Standalone test suite for Best_Bin_First (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Best_Bin_First; use Best_Bin_First;

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

   function P2 (X, Y : Real) return Point is
      C : Coord_Array := [others => 0.0];
   begin
      C (1) := X;
      C (2) := Y;
      return Make_Point (2, C);
   end P2;

   function P3 (X, Y, Z : Real) return Point is
      C : Coord_Array := [others => 0.0];
   begin
      C (1) := X;
      C (2) := Y;
      C (3) := Z;
      return Make_Point (3, C);
   end P3;

   function P1 (X : Real) return Point is
      C : Coord_Array := [others => 0.0];
   begin
      C (1) := X;
      return Make_Point (1, C);
   end P1;

begin
   Put_Line ("Best_Bin_First test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Distance2 / Near / Dist2_To_AABB helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Point := P2 (0.0, 0.0);
      B : constant Point := P2 (3.0, 4.0);
      Lo : Coord_Array := [others => 0.0];
      Hi : Coord_Array := [others => 0.0];
   begin
      Check (Near (Distance2 (A, B, 2), 25.0), "Distance2 (3,4)->25");
      Check (Near (Distance2 (A, A, 2), 0.0), "Distance2 identical=0");
      Check (Near_Point (A, A, 2), "Near_Point identical");
      Check (not Near_Point (A, B, 2), "Near_Point distinct");
      Check (Near (1.0, 1.0 + 1.0E-10, 1.0E-8), "Near tolerant");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Lo (1) := 1.0; Lo (2) := 1.0;
      Hi (1) := 2.0; Hi (2) := 2.0;
      Check (Near (Dist2_To_AABB (P2 (1.5, 1.5), Lo, Hi, 2), 0.0),
             "AABB inside dist=0");
      Check (Near (Dist2_To_AABB (P2 (0.0, 1.5), Lo, Hi, 2), 1.0),
             "AABB left dist2=1");
      Check (Near (Dist2_To_AABB (P2 (3.0, 3.0), Lo, Hi, 2), 2.0),
             "AABB corner dist2=1+1");
      Check (Near (Dist2_To_AABB (P2 (1.5, 0.0), Lo, Hi, 2), 1.0),
             "AABB below dist2=1");
      Check (Near (Distance2 (P3 (1.0, 0.0, 0.0), P3 (0.0, 0.0, 0.0), 3),
                   1.0),
             "Distance2 3D unit");
      Check (Near (Distance2 (P1 (5.0), P1 (2.0), 1), 9.0),
             "Distance2 1D");
   end;

   ---------------------------------------------------------------------
   Section ("2. Cloud / Add_Point / empty Exact_NN");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      R : NN_Result;
   begin
      Check (Cloud_Count (C) = 0, "Make_Cloud Count=0");
      Check (Cloud_Dim (C) = 2, "Make_Cloud Dim=2");
      R := Exact_NN (C, P2 (0.0, 0.0));
      Check (not R.Found, "Exact_NN empty not Found");
      Add_Point (C, P2 (1.0, 2.0));
      Check (Cloud_Count (C) = 1, "Count after one Add");
      R := Exact_NN (C, P2 (1.0, 2.0));
      Check (R.Found, "Exact_NN singleton Found");
      Check (R.Index = 1, "Exact_NN singleton Index=1");
      Check (Near (R.Distance2, 0.0), "Exact_NN singleton Dist=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Singleton tree + Approximate_NN");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      R : NN_Result;
   begin
      Add_Point (C, P2 (5.0, 7.0));
      T := Build_Tree (C);
      Check (not Tree_Empty (T), "Singleton tree not empty");
      Check (Tree_Count (T) = 1, "Singleton Tree_Count=1");
      Check (Tree_Dim (T) = 2, "Singleton Tree_Dim=2");
      Check (Tree_Root (T) /= 0, "Singleton Root nonzero");
      Check (Node_Is_Leaf (T, Tree_Root (T)), "Singleton root is leaf");
      Check (Node_Point_Index (T, Tree_Root (T)) = 1,
             "Singleton leaf point index");
      R := Approximate_NN (T, P2 (5.0, 7.0), 10);
      Check (R.Found, "Approx singleton Found");
      Check (R.Index = 1, "Approx singleton Index");
      Check (Near (R.Distance2, 0.0), "Approx singleton Dist");
      R := Approximate_NN (T, P2 (6.0, 7.0), 10);
      Check (R.Found and then Near (R.Distance2, 1.0),
             "Approx singleton query offset");
   end;

   ---------------------------------------------------------------------
   Section ("4. Empty tree");
   ---------------------------------------------------------------------
   declare
      C : constant Point_Cloud := Make_Cloud (3);
      T : constant KD_Tree := Build_Tree (C);
      R : NN_Result;
      K : KNN_Result;
   begin
      Check (Tree_Empty (T), "Empty tree");
      Check (Tree_Count (T) = 0, "Empty Tree_Count=0");
      Check (Tree_Root (T) = 0, "Empty Root=0");
      R := Approximate_NN (T, P3 (0.0, 0.0, 0.0), 5);
      Check (not R.Found, "Approx empty not Found");
      K := Approximate_KNN (T, P3 (0.0, 0.0, 0.0), 3, 5);
      Check (K.Count = 0, "KNN empty Count=0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Obvious 2D 1-NN Exact vs BBF");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
      Cfg : constant Config := Default_Config (E_Max => 64);
   begin
      Add_Point (C, P2 (0.0, 0.0));
      Add_Point (C, P2 (10.0, 0.0));
      Add_Point (C, P2 (0.0, 10.0));
      Add_Point (C, P2 (10.0, 10.0));
      Add_Point (C, P2 (3.0, 4.0));
      T := Build_Tree (C);
      Check (Tree_Count (T) = 5, "2D cloud Tree_Count=5");
      Ex := Exact_NN (C, P2 (3.1, 4.1));
      Ap := Approximate_NN (T, P2 (3.1, 4.1), 64);
      Check (Ex.Found and Ap.Found, "2D Found both");
      Check (Ex.Index = 5, "Exact picks (3,4)");
      Check (Ap.Index = Ex.Index, "BBF matches Exact index (large E)");
      Check (Near (Ap.Distance2, Ex.Distance2), "BBF matches Exact dist2");
      Ap := Query_NN (T, P2 (3.1, 4.1), Cfg);
      Check (Ap.Index = Ex.Index, "Query_NN matches Exact");
      Ex := Exact_NN (C, P2 (-1.0, -1.0));
      Ap := Approximate_NN (T, P2 (-1.0, -1.0), 64);
      Check (Ex.Index = 1 and Ap.Index = 1, "Corner query -> (0,0)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Obvious 3D 1-NN");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (3);
      T : KD_Tree;
      Ex, Ap : NN_Result;
   begin
      Add_Point (C, P3 (0.0, 0.0, 0.0));
      Add_Point (C, P3 (1.0, 0.0, 0.0));
      Add_Point (C, P3 (0.0, 1.0, 0.0));
      Add_Point (C, P3 (0.0, 0.0, 1.0));
      Add_Point (C, P3 (2.0, 2.0, 2.0));
      T := Build_Tree (C);
      Ex := Exact_NN (C, P3 (1.9, 1.9, 1.9));
      Ap := Approximate_NN (T, P3 (1.9, 1.9, 1.9), 32);
      Check (Ex.Index = 5, "3D Exact nearest is (2,2,2)");
      Check (Ap.Index = Ex.Index, "3D BBF matches Exact");
      Ex := Exact_NN (C, P3 (0.1, 0.0, 0.0));
      Ap := Approximate_NN (T, P3 (0.1, 0.0, 0.0), 32);
      Check (Ex.Index = 1 or Ex.Index = 2, "3D near origin Exact ok");
      Check (Ap.Index = Ex.Index, "3D near origin BBF matches");
   end;

   ---------------------------------------------------------------------
   Section ("7. Identical points");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
   begin
      for I in 1 .. 8 loop
         Add_Point (C, P2 (1.0, 1.0));
      end loop;
      T := Build_Tree (C);
      Check (Tree_Count (T) = 8, "Identical Tree_Count=8");
      Ex := Exact_NN (C, P2 (1.0, 1.0));
      Ap := Approximate_NN (T, P2 (1.0, 1.0), 64);
      Check (Ex.Found and Near (Ex.Distance2, 0.0), "Identical Exact dist0");
      Check (Ap.Found and Near (Ap.Distance2, 0.0), "Identical BBF dist0");
      Ap := Approximate_NN (T, P2 (1.0, 2.0), 64);
      Check (Ap.Found and Near (Ap.Distance2, 1.0), "Identical offset dist1");
   end;

   ---------------------------------------------------------------------
   Section ("8. BBF matches Exact when E_max large (grid)");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
      Match : Natural := 0;
      Total : Natural := 0;
      Q : Point;
   begin
      for X in 0 .. 7 loop
         for Y in 0 .. 7 loop
            Add_Point (C, P2 (Real (X), Real (Y)));
         end loop;
      end loop;
      T := Build_Tree (C);
      Check (Tree_Count (T) = 64, "Grid 8x8 Count=64");
      for X in 0 .. 7 loop
         for Y in 0 .. 7 loop
            Q := P2 (Real (X) + 0.1, Real (Y) - 0.1);
            Ex := Exact_NN (C, Q);
            Ap := Approximate_NN (T, Q, 128);
            Total := Total + 1;
            if Ap.Index = Ex.Index
              and then Near (Ap.Distance2, Ex.Distance2)
            then
               Match := Match + 1;
            end if;
         end loop;
      end loop;
      Check (Match = Total, "Large E_max: all 64 queries match Exact");
      --  Also spot-check a few individually for clear PASS lines
      Ex := Exact_NN (C, P2 (3.2, 4.8));
      Ap := Approximate_NN (T, P2 (3.2, 4.8), 128);
      Check (Ap.Index = Ex.Index, "Spot (3.2,4.8) index match");
      Check (Near (Ap.Distance2, Ex.Distance2), "Spot (3.2,4.8) dist match");
   end;

   ---------------------------------------------------------------------
   Section ("9. Small E_max still returns a near neighbor");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
      Ratio_Ok : Natural := 0;
   begin
      for I in 1 .. 40 loop
         Add_Point (C, P2 (Real (I), Real (I mod 7)));
      end loop;
      T := Build_Tree (C);
      Ex := Exact_NN (C, P2 (20.3, 6.0));
      Ap := Approximate_NN (T, P2 (20.3, 6.0), 3);
      Check (Ap.Found, "Small E Found");
      Check (Ap.Bins_Examined <= 3, "Small E examined <= 3");
      Check (Ap.Bins_Examined >= 1, "Small E examined >= 1");
      --  Approximate distance should not be wildly worse than exact
      if Ex.Distance2 < 1.0E-12 then
         Check (Ap.Distance2 < 50.0, "Small E near when exact~0");
      else
         Check (Ap.Distance2 <= Ex.Distance2 * 100.0 + 50.0,
                "Small E within loose factor of Exact");
      end if;
      for Trial in 1 .. 10 loop
         declare
            Qx : constant Real := Real (Trial) * 3.7;
            Qy : constant Real := Real (Trial mod 5);
         begin
            Ex := Exact_NN (C, P2 (Qx, Qy));
            Ap := Approximate_NN (T, P2 (Qx, Qy), 4);
            if Ap.Found
              and then Ap.Distance2 <= Ex.Distance2 * 200.0 + 100.0
            then
               Ratio_Ok := Ratio_Ok + 1;
            end if;
         end;
      end loop;
      Check (Ratio_Ok >= 8, "Small E: >=8/10 queries reasonably near");
   end;

   ---------------------------------------------------------------------
   Section ("10. Priority queue helpers");
   ---------------------------------------------------------------------
   declare
      H : Bin_Heap := Empty_Heap;
      E : Bin_Entry;
   begin
      Check (Heap_Count (H) = 0, "Empty_Heap Count=0");
      Heap_Push (H, (Node => 3, Dist2 => 5.0));
      Heap_Push (H, (Node => 1, Dist2 => 1.0));
      Heap_Push (H, (Node => 2, Dist2 => 3.0));
      Heap_Push (H, (Node => 4, Dist2 => 0.5));
      Check (Heap_Count (H) = 4, "Heap Count=4");
      Check (Near (Heap_Peek (H).Dist2, 0.5), "Peek min Dist2=0.5");
      Check (Heap_Peek (H).Node = 4, "Peek Node=4");
      Heap_Pop (H, E);
      Check (E.Node = 4 and Near (E.Dist2, 0.5), "Pop first min");
      Heap_Pop (H, E);
      Check (E.Node = 1 and Near (E.Dist2, 1.0), "Pop second");
      Heap_Pop (H, E);
      Check (E.Node = 2 and Near (E.Dist2, 3.0), "Pop third");
      Heap_Pop (H, E);
      Check (E.Node = 3 and Near (E.Dist2, 5.0), "Pop fourth");
      Check (Heap_Count (H) = 0, "Heap empty after pops");
   end;

   ---------------------------------------------------------------------
   Section ("11. k-NN Approximate_KNN");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      K : KNN_Result;
   begin
      Add_Point (C, P2 (0.0, 0.0));
      Add_Point (C, P2 (1.0, 0.0));
      Add_Point (C, P2 (0.0, 1.0));
      Add_Point (C, P2 (5.0, 5.0));
      T := Build_Tree (C);
      K := Approximate_KNN (T, P2 (0.1, 0.1), 3, 32);
      Check (K.Count = 3, "KNN Count=3");
      Check (K.Items (1).Index /= 4, "KNN closest not far point");
      Check (K.Items (1).Distance2 <= K.Items (2).Distance2,
             "KNN sorted 1<=2");
      Check (K.Items (2).Distance2 <= K.Items (3).Distance2,
             "KNN sorted 2<=3");
      K := Approximate_KNN (T, P2 (0.0, 0.0), 1, 32);
      Check (K.Count = 1 and K.Items (1).Index = 1, "KNN k=1 exact hit");
   end;

   ---------------------------------------------------------------------
   Section ("12. Config / Default_Config");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config := Default_Config (16);
   begin
      Check (Cfg.E_Max = 16, "Default_Config E_Max");
      Check (Cfg.Max_Dim = Max_Dim, "Default_Config Max_Dim");
      Check (Cfg.Max_Points = Max_Points, "Default_Config Max_Points");
   end;

   ---------------------------------------------------------------------
   Section ("13. 1D line Exact vs BBF");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (1);
      T : KD_Tree;
      Ex, Ap : NN_Result;
      Ok : Natural := 0;
   begin
      for I in 1 .. 20 loop
         Add_Point (C, P1 (Real (I)));
      end loop;
      T := Build_Tree (C);
      for I in 1 .. 20 loop
         Ex := Exact_NN (C, P1 (Real (I) + 0.01));
         Ap := Approximate_NN (T, P1 (Real (I) + 0.01), 40);
         if Ap.Index = Ex.Index then
            Ok := Ok + 1;
         end if;
      end loop;
      Check (Ok = 20, "1D: all 20 BBF match Exact");
   end;

   ---------------------------------------------------------------------
   Section ("14. Capacity / exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      C : Point_Cloud := Make_Cloud (2);
   begin
      Raised := False;
      begin
         declare
            Bad : Point_Cloud := Make_Cloud (2);
         begin
            Bad.Dim := 0;
            Add_Point (Bad, P2 (0.0, 0.0));
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Add_Point Dim=0 raises Invalid_Argument");

      Raised := False;
      begin
         for I in 1 .. Max_Points loop
            Add_Point (C, P2 (Real (I), 0.0));
         end loop;
         Add_Point (C, P2 (0.0, 0.0));
      exception
         when Capacity_Exceeded =>
            Raised := True;
      end;
      Check (Raised, "Add_Point over Max_Points raises");
      Check (Cloud_Count (C) = Max_Points, "Cloud full at Max_Points");
   end;

   ---------------------------------------------------------------------
   Section ("15. Many random-ish 2D queries large E");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
      Match : Natural := 0;
      Seed  : Natural := 17;
      function Next_R return Real is
         S : Natural;
      begin
         Seed := (Seed * 75 + 74) rem 65537;
         S := Seed rem 100;
         return Real (S) / 10.0;
      end Next_R;
   begin
      for I in 1 .. 50 loop
         Add_Point (C, P2 (Next_R, Next_R));
      end loop;
      T := Build_Tree (C);
      for I in 1 .. 30 loop
         declare
            Q : constant Point := P2 (Next_R, Next_R);
         begin
            Ex := Exact_NN (C, Q);
            Ap := Approximate_NN (T, Q, 100);
            if Ap.Found and then Ap.Index = Ex.Index
              and then Near (Ap.Distance2, Ex.Distance2)
            then
               Match := Match + 1;
            end if;
         end;
      end loop;
      Check (Match = 30, "50-pt cloud: 30/30 BBF=Exact large E");
   end;

   ---------------------------------------------------------------------
   Section ("16. Bins_Examined respects E_max");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ap : NN_Result;
   begin
      for I in 1 .. 30 loop
         Add_Point (C, P2 (Real (I), Real (I * 2)));
      end loop;
      T := Build_Tree (C);
      Ap := Approximate_NN (T, P2 (15.5, 30.0), 1);
      Check (Ap.Bins_Examined = 1, "E_max=1 => examined=1");
      Ap := Approximate_NN (T, P2 (15.5, 30.0), 5);
      Check (Ap.Bins_Examined = 5, "E_max=5 => examined=5");
      Ap := Approximate_NN (T, P2 (15.5, 30.0), 1000);
      Check (Ap.Bins_Examined <= 30, "Huge E_max <= n leaves");
      Check (Ap.Found, "Huge E_max Found");
   end;

   ---------------------------------------------------------------------
   Section ("17. Make_Point / Coord padding");
   ---------------------------------------------------------------------
   declare
      Coords : Coord_Array := [others => 9.0];
      P : Point;
   begin
      Coords (1) := 1.0;
      Coords (2) := 2.0;
      P := Make_Point (2, Coords);
      Check (Near (P.C (1), 1.0) and Near (P.C (2), 2.0),
             "Make_Point sets used dims");
      Check (Near (P.C (3), 0.0), "Make_Point zeros unused dim 3");
   end;

   ---------------------------------------------------------------------
   Section ("18. High-D (Dim=8) smoke");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (8);
      T : KD_Tree;
      Coords : Coord_Array;
      Ex, Ap : NN_Result;
      Q : Point;
   begin
      for I in 1 .. 16 loop
         for D in Dim_Index loop
            Coords (D) := Real (I) * Real (D);
         end loop;
         Add_Point (C, Make_Point (8, Coords));
      end loop;
      T := Build_Tree (C);
      Check (Tree_Dim (T) = 8, "Dim=8 tree");
      for D in Dim_Index loop
         Coords (D) := Real (8) * Real (D);
      end loop;
      Q := Make_Point (8, Coords);
      Ex := Exact_NN (C, Q);
      Ap := Approximate_NN (T, Q, 64);
      Check (Ap.Index = Ex.Index, "Dim=8 BBF matches Exact");
      Check (Near (Ap.Distance2, 0.0), "Dim=8 exact hit dist0");
   end;


   ---------------------------------------------------------------------
   Section ("19. Extra Distance2 / AABB / Near cases");
   ---------------------------------------------------------------------
   declare
      Lo : Coord_Array := [others => 0.0];
      Hi : Coord_Array := [others => 0.0];
      A, B : Point;
   begin
      A := P2 (0.0, 0.0);
      B := P2 (0.0, 5.0);
      Check (Near (Distance2 (A, B, 2), 25.0), "Dist2 vertical 25");
      B := P2 (5.0, 0.0);
      Check (Near (Distance2 (A, B, 2), 25.0), "Dist2 horizontal 25");
      Check (Near (Distance2 (P3 (1.0, 2.0, 2.0), P3 (0.0, 0.0, 0.0), 3), 9.0),
             "Dist2 3D 1+4+4=9");
      Lo (1) := -1.0; Lo (2) := -1.0; Lo (3) := -1.0;
      Hi (1) := 1.0; Hi (2) := 1.0; Hi (3) := 1.0;
      Check (Near (Dist2_To_AABB (P3 (0.0, 0.0, 0.0), Lo, Hi, 3), 0.0),
             "AABB 3D center 0");
      Check (Near (Dist2_To_AABB (P3 (2.0, 0.0, 0.0), Lo, Hi, 3), 1.0),
             "AABB 3D outside x");
      Check (Near (Dist2_To_AABB (P3 (2.0, 2.0, 2.0), Lo, Hi, 3), 3.0),
             "AABB 3D corner 3");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (not Near (0.0, 1.0E-3, 1.0E-6), "Near rejects 1e-3 vs 1e-6");
      Check (Near_Point (P1 (3.0), P1 (3.0), 1), "Near_Point 1D");
      Check (not Near_Point (P1 (3.0), P1 (4.0), 1), "Near_Point 1D far");
   end;

   ---------------------------------------------------------------------
   Section ("20. More Exact/BBF agreement spot checks");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      Ex, Ap : NN_Result;
   begin
      for X in 0 .. 4 loop
         for Y in 0 .. 4 loop
            Add_Point (C, P2 (Real (X), Real (Y)));
         end loop;
      end loop;
      T := Build_Tree (C);
      Check (Tree_Count (T) = 25, "5x5 Count=25");
      Ex := Exact_NN (C, P2 (2.0, 2.0));
      Ap := Approximate_NN (T, P2 (2.0, 2.0), 64);
      Check (Ex.Index = Ap.Index, "5x5 center index");
      Check (Near (Ex.Distance2, 0.0), "5x5 center exact0");
      Ex := Exact_NN (C, P2 (4.4, 0.1));
      Ap := Approximate_NN (T, P2 (4.4, 0.1), 64);
      Check (Ap.Index = Ex.Index, "5x5 (4.4,0.1) match");
      Ex := Exact_NN (C, P2 (0.0, 4.0));
      Ap := Query_NN (T, P2 (0.0, 4.0), Default_Config (64));
      Check (Ap.Index = Ex.Index, "5x5 Query_NN match");
      Ex := Exact_NN (C, P2 (1.4, 3.6));
      Ap := Approximate_NN (T, P2 (1.4, 3.6), 64);
      Check (Ap.Index = Ex.Index, "5x5 (1.4,3.6) match");
      Check (Near (Ap.Distance2, Ex.Distance2), "5x5 (1.4,3.6) dist");
      Ap := Approximate_NN (T, P2 (2.2, 2.2), 2);
      Check (Ap.Found, "5x5 small E still Found");
      Check (Ap.Bins_Examined = 2, "5x5 small E examined=2");
   end;

   ---------------------------------------------------------------------
   Section ("21. k-NN more / leaf accessors");
   ---------------------------------------------------------------------
   declare
      C : Point_Cloud := Make_Cloud (2);
      T : KD_Tree;
      K : KNN_Result;
   begin
      Add_Point (C, P2 (0.0, 0.0));
      Add_Point (C, P2 (1.0, 0.0));
      Add_Point (C, P2 (2.0, 0.0));
      Add_Point (C, P2 (3.0, 0.0));
      Add_Point (C, P2 (100.0, 100.0));
      T := Build_Tree (C);
      K := Approximate_KNN (T, P2 (0.5, 0.0), 2, 32);
      Check (K.Count = 2, "KNN2 Count=2");
      Check (K.Items (1).Index = 1 or K.Items (1).Index = 2,
             "KNN2 first is 1 or 2");
      Check (K.Items (2).Index = 1 or K.Items (2).Index = 2,
             "KNN2 second is 1 or 2");
      Check (K.Items (1).Index /= K.Items (2).Index, "KNN2 distinct");
      K := Approximate_KNN (T, P2 (0.0, 0.0), 4, 64);
      Check (K.Count = 4, "KNN4 Count=4");
      Check (K.Items (1).Index = 1, "KNN4 closest is origin");
      Check (Node_Point_Index (T, 0) = 0, "Node_Point_Index 0 => 0");
      Check (not Node_Is_Leaf (T, 0), "Node_Is_Leaf 0 => False");
      Check (Cloud_Dim (C) = 2, "Cloud_Dim still 2");
      Check (Cloud_Count (C) = 5, "Cloud_Count still 5");
   end;

   New_Line;
   Put_Line ("=========================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 100 — expand tests");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
