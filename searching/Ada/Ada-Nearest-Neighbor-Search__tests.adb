--  Standalone test suite for Nearest_Neighbor_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nearest_Neighbor_Search; use Nearest_Neighbor_Search;

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
   Put_Line ("Nearest_Neighbor_Search test suite");
   Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Distances / Near helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Point := P2 (0.0, 0.0);
      B : constant Point := P2 (3.0, 4.0);
      C : constant Point := P2 (1.0, 0.0);
   begin
      Check (Near (Distance2 (A, B, 2), 25.0), "Distance2 (3,4)->25");
      Check (Near (Distance2 (A, A, 2), 0.0), "Distance2 identical=0");
      Check (Near (Manhattan (A, B, 2), 7.0), "Manhattan (3,4)->7");
      Check (Near (Chebyshev (A, B, 2), 4.0), "Chebyshev (3,4)->4");
      Check (Near (Distance (A, B, 2, Euclidean_Squared), 25.0),
             "Distance dispatch Euc2");
      Check (Near (Distance (A, B, 2, Manhattan), 7.0),
             "Distance dispatch L1");
      Check (Near (Distance (A, B, 2, Chebyshev), 4.0),
             "Distance dispatch Linf");
      Check (Near_Point (A, A, 2), "Near_Point identical");
      Check (not Near_Point (A, B, 2), "Near_Point distinct");
      Check (Near (1.0, 1.0 + 1.0E-10, 1.0E-8), "Near tolerant");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (Distance2 (P3 (1.0, 0.0, 0.0), P3 (0.0, 0.0, 0.0), 3),
                   1.0),
             "Distance2 3D unit");
      Check (Near (Distance2 (P1 (5.0), P1 (2.0), 1), 9.0),
             "Distance2 1D");
      Check (Near (Manhattan (A, C, 2), 1.0), "Manhattan unit X");
      Check (Near (Chebyshev (P2 (0.0, 0.0), P2 (2.0, 5.0), 2), 5.0),
             "Chebyshev max");
   end;

   ---------------------------------------------------------------------
   Section ("2. Metric property checks");
   ---------------------------------------------------------------------
   declare
      A : constant Point := P2 (0.0, 0.0);
      B : constant Point := P2 (3.0, 0.0);
      C : constant Point := P2 (0.0, 4.0);
   begin
      Check (not Is_Metric (Euclidean_Squared), "Euc2 not a metric");
      Check (Is_Metric (Manhattan), "Manhattan is metric");
      Check (Is_Metric (Chebyshev), "Chebyshev is metric");
      Check (Check_Nonnegativity (A, B, 2, Manhattan), "L1 nonneg");
      Check (Check_Nonnegativity (A, B, 2, Euclidean_Squared), "Euc2 nonneg");
      Check (Check_Symmetry (A, B, 2, Manhattan), "L1 symmetry");
      Check (Check_Symmetry (A, B, 2, Chebyshev), "Linf symmetry");
      Check (Check_Symmetry (A, B, 2, Euclidean_Squared), "Euc2 symmetry");
      Check (Check_Identity_Of_Indiscernibles (A, 2, Manhattan),
             "L1 identity");
      Check (Check_Identity_Of_Indiscernibles (B, 2, Chebyshev),
             "Linf identity");
      Check (Check_Triangle (A, B, C, 2, Manhattan), "L1 triangle");
      Check (Check_Triangle (A, B, C, 2, Chebyshev), "Linf triangle");
      --  Euc2: d(A,B)=9, d(B,C)=25, d(A,C)=16; 16 <= 9+25 OK often,
      --  but classic counterexample for squared Euclidean as metric:
      --  A=(0,0), B=(1,0), C=(2,0): d2(A,C)=4, d2(A,B)+d2(B,C)=1+1=2.
      Check (not Check_Triangle
               (P2 (0.0, 0.0), P2 (1.0, 0.0), P2 (2.0, 0.0), 2,
                Euclidean_Squared),
             "Euc2 fails triangle on line");
      Check (Check_Triangle
               (P2 (0.0, 0.0), P2 (1.0, 0.0), P2 (2.0, 0.0), 2, Manhattan),
             "L1 triangle on line");
   end;

   ---------------------------------------------------------------------
   Section ("3. Cloud / Labels / Config / empty Linear_NN");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      R  : NN_Result;
      L  : Labels;
      Cfg : Config;
   begin
      Check (Cloud_Count (Cl) = 0, "Make_Cloud Count=0");
      Check (Cloud_Dim (Cl) = 2, "Make_Cloud Dim=2");
      R := Linear_NN (Cl, P2 (0.0, 0.0));
      Check (not R.Found, "Linear_NN empty not Found");
      Add_Point (Cl, P2 (1.0, 2.0));
      Check (Cloud_Count (Cl) = 1, "Count after one Add");
      R := Linear_NN (Cl, P2 (1.0, 2.0));
      Check (R.Found, "Linear_NN singleton Found");
      Check (R.Index = 1, "Linear_NN singleton Index=1");
      Check (Near (R.Distance, 0.0), "Linear_NN singleton Dist=0");
      L := Make_Labels (3);
      Check (L.Count = 3, "Make_Labels Count=3");
      Set_Label (L, 1, 2);
      Set_Label (L, 2, 1);
      Set_Label (L, 3, 2);
      Check (Get_Label (L, 1) = 2, "Get_Label 1");
      Check (Get_Label (L, 2) = 1, "Get_Label 2");
      Cfg := Default_Config (Manhattan, 3);
      Check (Cfg.Metric = Manhattan, "Default_Config Metric");
      Check (Cfg.Default_K = 3, "Default_Config K");
   end;

   ---------------------------------------------------------------------
   Section ("4. Linear 1-NN obvious 2D / 3D / metrics");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      R  : NN_Result;
   begin
      Add_Point (Cl, P2 (0.0, 0.0));
      Add_Point (Cl, P2 (10.0, 0.0));
      Add_Point (Cl, P2 (0.0, 10.0));
      Add_Point (Cl, P2 (10.0, 10.0));
      Add_Point (Cl, P2 (3.0, 4.0));
      R := Linear_NN (Cl, P2 (3.1, 4.1));
      Check (R.Found and R.Index = 5, "Linear picks (3,4)");
      Check (Near (R.Distance, Distance2 (P2 (3.1, 4.1), P2 (3.0, 4.0), 2)),
             "Linear dist2 match");
      R := Linear_NN (Cl, P2 (-1.0, -1.0));
      Check (R.Index = 1, "Corner query -> (0,0)");
      R := Linear_NN (Cl, P2 (3.0, 4.0), Manhattan);
      Check (R.Index = 5 and Near (R.Distance, 0.0), "Linear L1 exact hit");
      R := Linear_NN (Cl, P2 (9.0, 9.0), Chebyshev);
      Check (R.Index = 4, "Linear Linf near (10,10)");
   end;

   declare
      Cl : Cloud := Make_Cloud (3);
      R  : NN_Result;
   begin
      Add_Point (Cl, P3 (0.0, 0.0, 0.0));
      Add_Point (Cl, P3 (1.0, 0.0, 0.0));
      Add_Point (Cl, P3 (0.0, 1.0, 0.0));
      Add_Point (Cl, P3 (0.0, 0.0, 1.0));
      Add_Point (Cl, P3 (2.0, 2.0, 2.0));
      R := Linear_NN (Cl, P3 (1.9, 1.9, 1.9));
      Check (R.Index = 5, "3D Linear picks (2,2,2)");
      R := Linear_NN (Cl, P3 (0.1, 0.0, 0.0));
      Check (R.Index = 1 or R.Index = 2, "3D near origin axis");
   end;

   ---------------------------------------------------------------------
   Section ("5. Linear k-NN sorted partial");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (1);
      K  : KNN_Result;
   begin
      Add_Point (Cl, P1 (0.0));
      Add_Point (Cl, P1 (1.0));
      Add_Point (Cl, P1 (2.0));
      Add_Point (Cl, P1 (3.0));
      Add_Point (Cl, P1 (10.0));
      K := Linear_KNN (Cl, P1 (0.5), 3);
      Check (K.Count = 3, "k-NN Count=3");
      Check (K.Items (1).Index = 1 or K.Items (1).Index = 2,
             "k-NN first near 0 or 1");
      Check (K.Items (1).Distance <= K.Items (2).Distance, "k-NN sorted 1<=2");
      Check (K.Items (2).Distance <= K.Items (3).Distance, "k-NN sorted 2<=3");
      K := Linear_KNN (Cl, P1 (0.0), 1);
      Check (K.Count = 1 and K.Items (1).Index = 1, "1-NN via KNN");
      K := Linear_KNN (Cl, P1 (100.0), 5);
      Check (K.Count = 5, "k-NN K>n capped by n");
      Check (K.Items (5).Index = 1 or K.Items (1).Index = 5,
             "farthest includes endpoints");
   end;

   declare
      Cl : Cloud := Make_Cloud (2);
      K  : KNN_Result;
   begin
      Add_Point (Cl, P2 (0.0, 0.0));
      Add_Point (Cl, P2 (1.0, 0.0));
      Add_Point (Cl, P2 (0.0, 1.0));
      Add_Point (Cl, P2 (5.0, 5.0));
      K := Linear_KNN (Cl, P2 (0.1, 0.1), 2, Manhattan);
      Check (K.Count = 2, "L1 k-NN Count=2");
      Check (K.Items (1).Index /= 4, "L1 k-NN excludes far point");
      Check (K.Items (2).Index /= 4, "L1 k-NN second not far");
   end;

   ---------------------------------------------------------------------
   Section ("6. Radius search");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      R  : Radius_Result;
      Hit_Origin : Boolean := False;
      Hit_Far    : Boolean := False;
   begin
      Add_Point (Cl, P2 (0.0, 0.0));
      Add_Point (Cl, P2 (1.0, 0.0));
      Add_Point (Cl, P2 (0.0, 1.0));
      Add_Point (Cl, P2 (10.0, 10.0));
      R := Radius_Search (Cl, P2 (0.0, 0.0), 1.0);
      Check (R.Count = 3, "Radius Euc2 R=1 hits 3");
      for I in 1 .. R.Count loop
         if R.Indices (I) = 1 then
            Hit_Origin := True;
         end if;
         if R.Indices (I) = 4 then
            Hit_Far := True;
         end if;
      end loop;
      Check (Hit_Origin, "Radius includes origin");
      Check (not Hit_Far, "Radius excludes far");
      R := Radius_Search (Cl, P2 (0.0, 0.0), 0.0);
      Check (R.Count = 1 and R.Indices (1) = 1, "Radius 0 only self");
      R := Radius_Search (Cl, P2 (0.0, 0.0), 1.0, Manhattan);
      Check (R.Count = 3, "Radius L1 R=1 hits 3");
      R := Radius_Search (Cl, P2 (0.0, 0.0), 0.5, Chebyshev);
      Check (R.Count = 1, "Radius Linf small");
      R := Radius_Search (Make_Cloud (2), P2 (0.0, 0.0), 1.0);
      Check (R.Count = 0, "Radius empty cloud");
   end;

   ---------------------------------------------------------------------
   Section ("7. k-d tree build / empty / singleton");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      T  : KD_Tree;
      R  : NN_Result;
   begin
      T := Build_Tree (Cl);
      Check (Tree_Empty (T), "Empty tree");
      Check (Tree_Count (T) = 0, "Empty Tree_Count=0");
      Check (Tree_Root (T) = 0, "Empty Root=0");
      R := Tree_NN (T, P2 (0.0, 0.0));
      Check (not R.Found, "Tree_NN empty not Found");

      Add_Point (Cl, P2 (5.0, 7.0));
      T := Build_Tree (Cl);
      Check (not Tree_Empty (T), "Singleton tree not empty");
      Check (Tree_Count (T) = 1, "Singleton Tree_Count=1");
      Check (Tree_Dim (T) = 2, "Singleton Tree_Dim=2");
      Check (Tree_Root (T) /= 0, "Singleton Root nonzero");
      Check (Node_Is_Leaf (T, Tree_Root (T)), "Singleton root is leaf");
      Check (Node_Point_Index (T, Tree_Root (T)) = 1,
             "Singleton leaf point index");
      R := Tree_NN (T, P2 (5.0, 7.0));
      Check (R.Found and R.Index = 1 and Near (R.Distance, 0.0),
             "Tree_NN singleton exact");
      R := Tree_NN (T, P2 (6.0, 7.0));
      Check (R.Found and Near (R.Distance, 1.0), "Tree_NN singleton offset");
   end;

   ---------------------------------------------------------------------
   Section ("8. Tree_NN matches Linear_NN (exact)");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      T  : KD_Tree;
      Ex, Tr : NN_Result;
   begin
      Add_Point (Cl, P2 (0.0, 0.0));
      Add_Point (Cl, P2 (10.0, 0.0));
      Add_Point (Cl, P2 (0.0, 10.0));
      Add_Point (Cl, P2 (10.0, 10.0));
      Add_Point (Cl, P2 (3.0, 4.0));
      T := Build_Tree (Cl);
      Check (Tree_Count (T) = 5, "2D Tree_Count=5");
      Ex := Linear_NN (Cl, P2 (3.1, 4.1));
      Tr := Tree_NN (T, P2 (3.1, 4.1));
      Check (Ex.Found and Tr.Found, "2D Found both");
      Check (Ex.Index = Tr.Index, "Tree matches Linear index");
      Check (Near (Ex.Distance, Tr.Distance), "Tree matches Linear dist");
      Ex := Linear_NN (Cl, P2 (-1.0, -1.0));
      Tr := Tree_NN (T, P2 (-1.0, -1.0));
      Check (Ex.Index = Tr.Index, "Corner Tree=Linear");
      Ex := Linear_NN (Cl, P2 (9.5, 0.2));
      Tr := Tree_NN (T, P2 (9.5, 0.2));
      Check (Ex.Index = Tr.Index, "Near (10,0) Tree=Linear");
   end;

   declare
      Cl : Cloud := Make_Cloud (3);
      T  : KD_Tree;
      Ex, Tr : NN_Result;
   begin
      Add_Point (Cl, P3 (0.0, 0.0, 0.0));
      Add_Point (Cl, P3 (1.0, 0.0, 0.0));
      Add_Point (Cl, P3 (0.0, 1.0, 0.0));
      Add_Point (Cl, P3 (0.0, 0.0, 1.0));
      Add_Point (Cl, P3 (2.0, 2.0, 2.0));
      Add_Point (Cl, P3 (-1.0, -1.0, -1.0));
      T := Build_Tree (Cl);
      Ex := Linear_NN (Cl, P3 (1.9, 1.9, 1.9));
      Tr := Tree_NN (T, P3 (1.9, 1.9, 1.9));
      Check (Ex.Index = Tr.Index, "3D Tree=Linear far");
      Ex := Linear_NN (Cl, P3 (-0.9, -0.9, -0.9));
      Tr := Tree_NN (T, P3 (-0.9, -0.9, -0.9));
      Check (Ex.Index = Tr.Index, "3D Tree=Linear near neg");
   end;

   ---------------------------------------------------------------------
   Section ("9. Tree_NN grid / many queries");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      T  : KD_Tree;
      Ex, Tr : NN_Result;
      All_Match : Boolean := True;
      N_Queries : Natural := 0;
   begin
      for X in 0 .. 4 loop
         for Y in 0 .. 4 loop
            Add_Point (Cl, P2 (Real (X), Real (Y)));
         end loop;
      end loop;
      T := Build_Tree (Cl);
      Check (Tree_Count (T) = 25, "5x5 grid Tree_Count=25");
      for Xi in 0 .. 4 loop
         for Yi in 0 .. 4 loop
            declare
               Q : constant Point :=
                 P2 (Real (Xi) + 0.1, Real (Yi) - 0.1);
            begin
               Ex := Linear_NN (Cl, Q);
               Tr := Tree_NN (T, Q);
               N_Queries := N_Queries + 1;
               if Ex.Index /= Tr.Index
                 or else not Near (Ex.Distance, Tr.Distance)
               then
                  All_Match := False;
               end if;
            end;
         end loop;
      end loop;
      Check (N_Queries = 25, "25 grid queries");
      Check (All_Match, "Tree=Linear all 25 grid queries");
      --  Extra off-grid queries
      Ex := Linear_NN (Cl, P2 (2.4, 2.6));
      Tr := Tree_NN (T, P2 (2.4, 2.6));
      Check (Ex.Index = Tr.Index, "off-grid Tree=Linear");
      Ex := Linear_NN (Cl, P2 (-5.0, 10.0));
      Tr := Tree_NN (T, P2 (-5.0, 10.0));
      Check (Ex.Index = Tr.Index, "exterior Tree=Linear");
   end;

   ---------------------------------------------------------------------
   Section ("10. k-NN majority-vote classification");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      L  : Labels;
      Cr : Classify_Result;
      Ix : Index_List := [others => 0];
   begin
      Add_Point (Cl, P2 (0.0, 0.0));  -- class 1
      Add_Point (Cl, P2 (0.1, 0.0));  -- class 1
      Add_Point (Cl, P2 (0.0, 0.1));  -- class 1
      Add_Point (Cl, P2 (5.0, 5.0));  -- class 2
      Add_Point (Cl, P2 (5.1, 5.0));  -- class 2
      L := Make_Labels (5);
      Set_Label (L, 1, 1);
      Set_Label (L, 2, 1);
      Set_Label (L, 3, 1);
      Set_Label (L, 4, 2);
      Set_Label (L, 5, 2);
      Cr := Classify_KNN (Cl, L, P2 (0.05, 0.05), 3);
      Check (Cr.Found, "Classify Found");
      Check (Cr.Predicted = 1, "Classify near origin -> 1");
      Check (Cr.Vote_Count = 3, "Classify vote 3 for class 1");
      Cr := Classify_KNN (Cl, L, P2 (5.05, 5.0), 3);
      Check (Cr.Predicted = 2, "Classify near (5,5) -> 2");
      Ix (1) := 1;
      Ix (2) := 4;
      Ix (3) := 5;
      Cr := Majority_Vote (L, Ix, 3);
      Check (Cr.Predicted = 2, "Majority_Vote 2 beats 1");
      Check (Cr.Vote_Count = 2, "Majority_Vote count=2");
      Ix (1) := 1;
      Ix (2) := 2;
      Cr := Majority_Vote (L, Ix, 2);
      Check (Cr.Predicted = 1 and Cr.Vote_Count = 2, "Unanimous class 1");
      Cr := Majority_Vote (L, Ix, 0);
      Check (not Cr.Found, "Majority empty neighbors");
   end;

   ---------------------------------------------------------------------
   Section ("11. Taxonomy metadata");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Check (Method_Count = 4, "Method_Count=4");
      Check (Method_Name (Linear) = "Linear", "Name Linear");
      Check (Method_Name (Exact_KD_Tree) = "KD_Tree", "Name KD_Tree");
      Check (Method_Name (Best_Bin_First) = "Best_Bin_First", "Name BBF");
      Check (Method_Name (LSH) = "LSH", "Name LSH");
      Info := Classify_Method (Linear);
      Check (Info.Exact and Info.Implemented and not Info.Approximate,
             "Linear flags");
      Info := Classify_Method (Exact_KD_Tree);
      Check (Info.Exact and Info.Implemented and not Info.Approximate,
             "KD_Tree flags");
      Info := Classify_Method (Best_Bin_First);
      Check (not Info.Exact and not Info.Implemented and Info.Approximate,
             "BBF metadata only");
      Info := Classify_Method (LSH);
      Check (not Info.Exact and not Info.Implemented and Info.Approximate,
             "LSH metadata only");
   end;

   ---------------------------------------------------------------------
   Section ("12. 1D Tree / Linear consistency + radius L1");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (1);
      T  : KD_Tree;
      Ex, Tr : NN_Result;
      Rr : Radius_Result;
   begin
      for I in 1 .. 16 loop
         Add_Point (Cl, P1 (Real (I)));
      end loop;
      T := Build_Tree (Cl);
      Check (Tree_Count (T) = 16, "1D Tree_Count=16");
      Ex := Linear_NN (Cl, P1 (7.4));
      Tr := Tree_NN (T, P1 (7.4));
      Check (Ex.Index = Tr.Index, "1D Tree=Linear");
      Check (Ex.Index = 7 or Ex.Index = 8, "1D nearest 7 or 8");
      Rr := Radius_Search (Cl, P1 (8.0), 2.0, Manhattan);
      Check (Rr.Count = 5, "1D radius L1 |x-8|<=2 -> 5 pts");
   end;

   ---------------------------------------------------------------------
   Section ("13. Tie-breaking / Examined counts");
   ---------------------------------------------------------------------
   declare
      Cl : Cloud := Make_Cloud (2);
      R  : NN_Result;
      K  : KNN_Result;
   begin
      Add_Point (Cl, P2 (1.0, 0.0));
      Add_Point (Cl, P2 (-1.0, 0.0));
      --  Equidistant: first in scan wins for Linear_NN
      R := Linear_NN (Cl, P2 (0.0, 0.0));
      Check (R.Index = 1, "Equidistant prefers first");
      Check (R.Examined = 2, "Examined=2");
      K := Linear_KNN (Cl, P2 (0.0, 0.0), 2);
      Check (K.Count = 2, "Both equidistant in k-NN");
      Check (Near (K.Items (1).Distance, K.Items (2).Distance),
             "Equal distances");
   end;

   ---------------------------------------------------------------------
   Section ("14. Capacity / exception smoke");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      declare
         Cl : Cloud := Make_Cloud (2);
      begin
         for I in 1 .. Max_Points loop
            Add_Point (Cl, P2 (Real (I), 0.0));
         end loop;
         Check (Cloud_Count (Cl) = Max_Points, "Filled to Max_Points");
         begin
            Add_Point (Cl, P2 (0.0, 0.0));
         exception
            when Capacity_Exceeded =>
               Raised := True;
         end;
         Check (Raised, "Add_Point raises Capacity_Exceeded");
      end;

      Raised := False;
      begin
         declare
            L : constant Labels := Make_Labels (1);
            Unused : Label_Id;
         begin
            Unused := Get_Label (L, 2);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Get_Label OOR raises");
   end;

   New_Line;
   Put_Line ("----------------------------------");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
   pragma Assert (Fail_Count = 0);
   pragma Assert (Pass_Count >= 100);
end Tests;
