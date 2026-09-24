--  Standalone test suite for Grid_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Grid_Search; use Grid_Search;

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

   --  Shared enumeration counters for Visit callbacks.
   Visits_Seen : Natural := 0;
   Visit_Sum_X : Real := 0.0;
   Visit_Stop_At : Natural := 0;
   Visit_Stopped_Early : Boolean := False;

   procedure Count_Visit
     (X : Point; Rank : Positive; Stop : in out Boolean)
   is
   begin
      Visits_Seen := Visits_Seen + 1;
      if X'Length >= 1 then
         Visit_Sum_X := Visit_Sum_X + X (X'First);
      end if;
      if Visit_Stop_At > 0 and then Rank = Visit_Stop_At then
         Stop := True;
         Visit_Stopped_Early := True;
      end if;
   end Count_Visit;

   function Brute_Min (G : Grid; Obj : Objective_Fn) return Real is
      Best : Real := Real'Last;
      F    : Real;
   begin
      for R in 1 .. Cardinality (G) loop
         F := Obj (Point_At (G, R));
         if F < Best then
            Best := F;
         end if;
      end loop;
      return Best;
   end Brute_Min;

   function Brute_Max (G : Grid; Obj : Objective_Fn) return Real is
      Best : Real := Real'First;
      F    : Real;
   begin
      for R in 1 .. Cardinality (G) loop
         F := Obj (Point_At (G, R));
         if F > Best then
            Best := F;
         end if;
      end loop;
      return Best;
   end Brute_Max;

begin
   Put_Line ("Grid_Search test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (not Near (-1.0, 1.0), "Near opposite signs");
   end;

   ---------------------------------------------------------------------
   Section ("2. Default_Config");
   ---------------------------------------------------------------------
   declare
      C1 : constant Config := Default_Config;
      C2 : constant Config := Default_Config (Maximize_Sense);
   begin
      Check (C1.Sense_Flag = Minimize_Sense, "default is Minimize");
      Check (C2.Sense_Flag = Maximize_Sense, "explicit Maximize config");
   end;

   ---------------------------------------------------------------------
   Section ("3. Build_Linspace_Axis endpoints");
   ---------------------------------------------------------------------
   declare
      A1 : constant Axis := Build_Linspace_Axis (0.0, 1.0, 5);
      A2 : constant Axis := Build_Linspace_Axis (-2.0, 2.0, 3);
      A3 : constant Axis := Build_Linspace_Axis (7.0, 7.0, 1);
      A4 : constant Axis := Build_Linspace_Axis (0.0, 10.0, 11);
      A5 : constant Axis := Build_Linspace_Axis (-1.0, 1.0, 2);
   begin
      Check (Axis_Length (A1) = 5, "linspace N=5 length");
      Check (Near (Get_Value (A1, 1), 0.0), "linspace lo endpoint");
      Check (Near (Get_Value (A1, 5), 1.0), "linspace hi endpoint");
      Check (Near (Get_Value (A1, 3), 0.5), "linspace midpoint");
      Check (Near (Get_Value (A1, 2), 0.25), "linspace 0.25");
      Check (Near (Get_Value (A1, 4), 0.75), "linspace 0.75");

      Check (Axis_Length (A2) = 3, "linspace [-2,2] N=3");
      Check (Near (Get_Value (A2, 1), -2.0), "linspace -2 endpoint");
      Check (Near (Get_Value (A2, 2), 0.0), "linspace 0 midpoint");
      Check (Near (Get_Value (A2, 3), 2.0), "linspace +2 endpoint");

      Check (Axis_Length (A3) = 1, "linspace N=1 length");
      Check (Near (Get_Value (A3, 1), 7.0), "linspace N=1 value = Lo");

      Check (Axis_Length (A4) = 11, "linspace N=11");
      Check (Near (Get_Value (A4, 1), 0.0), "linspace 0..10 lo");
      Check (Near (Get_Value (A4, 11), 10.0), "linspace 0..10 hi");
      Check (Near (Get_Value (A4, 6), 5.0), "linspace 0..10 mid");

      Check (Axis_Length (A5) = 2, "linspace N=2");
      Check (Near (Get_Value (A5, 1), -1.0), "linspace N=2 lo");
      Check (Near (Get_Value (A5, 2), 1.0), "linspace N=2 hi");
   end;

   ---------------------------------------------------------------------
   Section ("4. Build_Axis sort / unique");
   ---------------------------------------------------------------------
   declare
      A : constant Axis := Build_Axis ([3.0, 1.0, 2.0, 1.0, 2.0 + 1.0E-12]);
      B : constant Axis := Build_Axis ([5.0]);
      C : constant Axis := Build_Axis ([-1.0, 0.0, 1.0]);
   begin
      Check (Axis_Length (A) = 3, "Build_Axis dedupes to 3");
      Check (Near (Get_Value (A, 1), 1.0), "Build_Axis sorted[1]");
      Check (Near (Get_Value (A, 2), 2.0), "Build_Axis sorted[2]");
      Check (Near (Get_Value (A, 3), 3.0), "Build_Axis sorted[3]");
      Check (Axis_Length (B) = 1, "Build_Axis singleton");
      Check (Near (Get_Value (B, 1), 5.0), "Build_Axis singleton value");
      Check (Axis_Length (C) = 3, "Build_Axis already sorted");
      Check (Near (Get_Value (C, 1), -1.0), "Build_Axis neg");
   end;

   ---------------------------------------------------------------------
   Section ("5. Cardinality");
   ---------------------------------------------------------------------
   declare
      G0 : Grid;  -- Dim = 0
      A  : constant Axis := Build_Linspace_Axis (0.0, 1.0, 4);
      B  : constant Axis := Build_Axis ([10.0, 100.0, 1000.0]);
      C  : constant Axis := Build_Axis ([0.1, 0.2, 0.5, 1.0]);
      G1 : constant Grid := Make_Grid ([A]);
      G2 : constant Grid := Make_Grid ([B, C]);
      G3 : constant Grid := Make_Grid
        ([Build_Linspace_Axis (0.0, 1.0, 2),
          Build_Linspace_Axis (0.0, 1.0, 3),
          Build_Linspace_Axis (0.0, 1.0, 4)]);
      Empty_Ax : Axis;  -- Count = 0
      G_Bad    : Grid;
   begin
      Check (Cardinality (G0) = 0, "empty Dim=0 cardinality 0");
      Check (Cardinality (G1) = 4, "1-D card = 4");
      Check (Cardinality (G2) = 12, "2-D card = 3*4");
      Check (Cardinality (G3) = 24, "3-D card = 2*3*4");
      Check (G1.Dim = 1, "G1 dim");
      Check (G2.Dim = 2, "G2 dim");
      Check (G3.Dim = 3, "G3 dim");

      --  Manually craft grid with empty axis → card 0
      G_Bad.Dim := 1;
      G_Bad.Axes (1) := Empty_Ax;
      Check (Cardinality (G_Bad) = 0, "empty axis → card 0");

      declare
         G4 : constant Grid := Make_Grid
           ([Build_Linspace_Axis (-1.0, 1.0, 5),
             Build_Linspace_Axis (-1.0, 1.0, 5),
             Build_Linspace_Axis (-1.0, 1.0, 5),
             Build_Linspace_Axis (-1.0, 1.0, 2)]);
      begin
         Check (Cardinality (G4) = 250, "4-D card = 5^3*2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Point_At lex order");
   ---------------------------------------------------------------------
   declare
      Ax : constant Axis := Build_Axis ([1.0, 2.0]);
      Ay : constant Axis := Build_Axis ([10.0, 20.0, 30.0]);
      G  : constant Grid := Make_Grid ([Ax, Ay]);
      P  : Point (1 .. 2);
   begin
      Check (Cardinality (G) = 6, "2x3 card");
      P := Point_At (G, 1);
      Check (Near (P (1), 1.0) and then Near (P (2), 10.0), "rank1 (1,10)");
      P := Point_At (G, 2);
      Check (Near (P (1), 1.0) and then Near (P (2), 20.0), "rank2 (1,20)");
      P := Point_At (G, 3);
      Check (Near (P (1), 1.0) and then Near (P (2), 30.0), "rank3 (1,30)");
      P := Point_At (G, 4);
      Check (Near (P (1), 2.0) and then Near (P (2), 10.0), "rank4 (2,10)");
      P := Point_At (G, 5);
      Check (Near (P (1), 2.0) and then Near (P (2), 20.0), "rank5 (2,20)");
      P := Point_At (G, 6);
      Check (Near (P (1), 2.0) and then Near (P (2), 30.0), "rank6 (2,30)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Enumerate visits all");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Axis ([0.0, 1.0]),
          Build_Axis ([0.0, 1.0, 2.0])]);
   begin
      Visits_Seen := 0;
      Visit_Sum_X := 0.0;
      Visit_Stop_At := 0;
      Visit_Stopped_Early := False;
      declare
         procedure Run is new Enumerate (Count_Visit);
      begin
         Run (G);
      end;
      Check (Visits_Seen = 6, "Enumerate visits 6");
      Check (Near (Visit_Sum_X, 0.0 + 0.0 + 0.0 + 1.0 + 1.0 + 1.0),
             "Enumerate sum of first coords");

      Visits_Seen := 0;
      Visit_Stop_At := 3;
      Visit_Stopped_Early := False;
      declare
         procedure Run is new Enumerate (Count_Visit);
      begin
         Run (G);
      end;
      Check (Visit_Stopped_Early, "Enumerate early stop flag");
      Check (Visits_Seen = 3, "Enumerate stopped after 3");
   end;

   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (0.0, 1.0, 3),
          Build_Linspace_Axis (0.0, 1.0, 3),
          Build_Linspace_Axis (0.0, 1.0, 2)]);
   begin
      Visits_Seen := 0;
      Visit_Stop_At := 0;
      declare
         procedure Run is new Enumerate (Count_Visit);
      begin
         Run (G);
      end;
      Check (Visits_Seen = Cardinality (G), "Enumerate 3-D visits all");
      Check (Visits_Seen = 18, "Enumerate 3*3*2 = 18");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty axis / empty grid raises");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Empty_A : Axis;
      G_Bad : Grid;
      R : Result;
      pragma Unreferenced (R);
   begin
      Raised := False;
      begin
         G_Bad := Make_Grid ([Empty_A]);
         Check (False, "Make_Grid empty should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Make_Grid empty axis raises");

      Raised := False;
      G_Bad.Dim := 0;
      begin
         R := Minimize (Sphere'Access, G_Bad);
         Check (False, "Minimize Dim=0 should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Minimize Dim=0 raises");

      Raised := False;
      G_Bad.Dim := 1;
      G_Bad.Axes (1) := Empty_A;
      begin
         R := Maximize (Sphere'Access, G_Bad);
         Check (False, "Maximize empty should raise");
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Maximize empty axis raises");

      Raised := False;
      begin
         declare
            procedure Run is new Enumerate (Count_Visit);
         begin
            Run (G_Bad);
            Check (False, "Enumerate empty should raise");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "Enumerate empty axis raises");

      Raised := False;
      declare
         G_Ok : constant Grid := Make_Grid ([Build_Axis ([1.0])]);
         Dummy : Point (1 .. 1);
      begin
         begin
            Dummy := Point_At (G_Ok, 2);
            Check (False, "Point_At OOR should raise");
         exception
            when Invalid_Argument =>
               Raised := True;
            when others =>
               Raised := False;
         end;
      end;
      Check (Raised, "Point_At out of range raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sphere minimize on linspace box");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (-1.0, 1.0, 5),
          Build_Linspace_Axis (-1.0, 1.0, 5)]);
      R : constant Result := Minimize (Sphere'Access, G);
      Oracle : constant Real := Brute_Min (G, Sphere'Access);
   begin
      Check (R.Evaluations = 25, "Sphere 5x5 evaluations");
      Check (R.Dim = 2, "Sphere dim 2");
      Check (Near (R.Best_F, 0.0), "Sphere best ≈ 0");
      Check (Near (R.Best_X (1), 0.0), "Sphere x1 ≈ 0");
      Check (Near (R.Best_X (2), 0.0), "Sphere x2 ≈ 0");
      Check (Near (R.Best_F, Oracle), "Sphere matches brute oracle");
      Check (R.Best_Rank >= 1 and then R.Best_Rank <= 25, "Sphere rank in range");
   end;

   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (-2.0, 2.0, 9),
          Build_Linspace_Axis (-2.0, 2.0, 9),
          Build_Linspace_Axis (-2.0, 2.0, 5)]);
      R : constant Result := Minimize (Sphere'Access, G);
   begin
      Check (R.Evaluations = 405, "Sphere 9x9x5 evals");
      Check (Near (R.Best_F, 0.0), "3-D Sphere near zero");
      Check (Near (R.Best_X (1), 0.0) and then Near (R.Best_X (2), 0.0)
               and then Near (R.Best_X (3), 0.0),
             "3-D Sphere at origin sample");
   end;

   ---------------------------------------------------------------------
   Section ("10. Maximize Neg_Sphere");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (-1.0, 1.0, 5),
          Build_Linspace_Axis (-1.0, 1.0, 5)]);
      R : constant Result := Maximize (Neg_Sphere'Access, G);
      Oracle : constant Real := Brute_Max (G, Neg_Sphere'Access);
   begin
      Check (Near (R.Best_F, 0.0), "Neg_Sphere max ≈ 0");
      Check (Near (R.Best_X (1), 0.0) and then Near (R.Best_X (2), 0.0),
             "Neg_Sphere at origin");
      Check (Near (R.Best_F, Oracle), "Maximize matches brute max oracle");
      Check (R.Evaluations = 25, "Maximize eval count");
   end;

   ---------------------------------------------------------------------
   Section ("11. Multimodal 1-D finds global among samples");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (0.0, 1.0, 11)]);
      R : constant Result := Minimize (Multimodal_1D'Access, G);
      Oracle : constant Real := Brute_Min (G, Multimodal_1D'Access);
      --  Evaluate all samples manually for expected best x
      Best_X : Real := 0.0;
      Best_F : Real := Real'Last;
      F      : Real;
      P      : Point (1 .. 1);
   begin
      for I in Axis_Index range 1 .. 11 loop
         P (1) := Get_Value (G.Axes (1), I);
         F := Multimodal_1D (P);
         if F < Best_F then
            Best_F := F;
            Best_X := P (1);
         end if;
      end loop;
      Check (Near (R.Best_F, Oracle), "multimodal matches oracle");
      Check (Near (R.Best_F, Best_F), "multimodal matches manual sweep");
      Check (Near (R.Best_X (1), Best_X), "multimodal best x among samples");
      Check (R.Evaluations = 11, "multimodal 11 evals");
      --  Global among dense samples should be near a basin (0.2 or 0.8)
      Check (Near (R.Best_X (1), 0.2, 0.15)
               or else Near (R.Best_X (1), 0.8, 0.15),
             "multimodal best near a basin");
   end;

   ---------------------------------------------------------------------
   Section ("12. SVM-style (C, γ) discrete set");
   ---------------------------------------------------------------------
   declare
      C_Axis : constant Axis := Build_Axis ([10.0, 100.0, 1000.0]);
      G_Axis : constant Axis := Build_Axis ([0.1, 0.2, 0.5, 1.0]);
      G      : constant Grid := Make_Grid ([C_Axis, G_Axis]);
      R      : constant Result := Maximize (SVM_Toy_Score'Access, G);
      Oracle : constant Real := Brute_Max (G, SVM_Toy_Score'Access);
   begin
      Check (Cardinality (G) = 12, "SVM grid 3x4");
      Check (R.Evaluations = 12, "SVM 12 evaluations");
      Check (Near (R.Best_F, Oracle), "SVM matches brute oracle");
      --  Peak designed at C=100, γ=0.1
      Check (Near (R.Best_X (1), 100.0), "SVM best C = 100");
      Check (Near (R.Best_X (2), 0.1), "SVM best γ = 0.1");
      Check (R.Best_F > SVM_Toy_Score ([10.0, 1.0]),
             "SVM best beats corner (10,1)");
      Check (R.Best_F >= SVM_Toy_Score ([100.0, 0.1]) - 1.0E-12,
             "SVM best equals designed peak");
   end;

   ---------------------------------------------------------------------
   Section ("13. Shifted_Sphere / Search with Config");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (0.0, 2.0, 5),
          Build_Linspace_Axis (0.0, 2.0, 5)]);
      R_Min : constant Result :=
        Search (Shifted_Sphere'Access, G, Default_Config (Minimize_Sense));
      R_Max : constant Result :=
        Search (Shifted_Sphere'Access, G, Default_Config (Maximize_Sense));
   begin
      Check (Near (R_Min.Best_X (1), 1.0) and then Near (R_Min.Best_X (2), 1.0),
             "Shifted_Sphere min at (1,1)");
      Check (Near (R_Min.Best_F, 0.0), "Shifted_Sphere min value 0");
      Check (R_Min.Evaluations = 25, "Shifted_Sphere evals");
      --  Max of shifted sphere on [0,2]^2 is at a corner farthest from (1,1)
      Check (R_Max.Best_F > 0.0, "Shifted_Sphere max > 0");
      Check (Near (R_Max.Best_F, Brute_Max (G, Shifted_Sphere'Access)),
             "Shifted_Sphere max matches oracle");
   end;

   ---------------------------------------------------------------------
   Section ("14. Best matches brute oracle (many grids)");
   ---------------------------------------------------------------------
   declare
      procedure Check_Oracle (Label : String; G : Grid) is
         R : constant Result := Minimize (Sphere'Access, G);
         O : constant Real := Brute_Min (G, Sphere'Access);
      begin
         Check (Near (R.Best_F, O), "oracle " & Label);
         Check (R.Evaluations = Cardinality (G), "evals=" & Label);
      end Check_Oracle;
   begin
      Check_Oracle ("1x3", Make_Grid ([Build_Axis ([0.0, 1.0, -1.0])]));
      Check_Oracle ("2x2", Make_Grid
        ([Build_Linspace_Axis (-0.5, 0.5, 2),
          Build_Linspace_Axis (-0.5, 0.5, 2)]));
      Check_Oracle ("3x3", Make_Grid
        ([Build_Linspace_Axis (-1.0, 1.0, 3),
          Build_Linspace_Axis (-1.0, 1.0, 3)]));
      Check_Oracle ("4x2", Make_Grid
        ([Build_Linspace_Axis (0.0, 1.0, 4),
          Build_Linspace_Axis (-2.0, 0.0, 2)]));
      Check_Oracle ("2x2x2", Make_Grid
        ([Build_Axis ([-1.0, 1.0]),
          Build_Axis ([-1.0, 1.0]),
          Build_Axis ([-1.0, 1.0])]));
      Check_Oracle ("5x1", Make_Grid
        ([Build_Linspace_Axis (-2.0, 2.0, 5),
          Build_Axis ([0.0])]));
   end;

   ---------------------------------------------------------------------
   Section ("15. Point_At consistency with Enumerate");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Axis ([1.0, 2.0, 3.0]),
          Build_Axis ([4.0, 5.0])]);
      Match : Boolean := True;
      Rank_Local : Natural := 0;

      procedure Check_Rank
        (X : Point; Rank : Positive; Stop : in out Boolean)
      is
         P : constant Point := Point_At (G, Rank);
      begin
         pragma Unreferenced (Stop);
         Rank_Local := Rank;
         if X'Length /= P'Length then
            Match := False;
         else
            for I in X'Range loop
               if not Near (X (I), P (I)) then
                  Match := False;
               end if;
            end loop;
         end if;
      end Check_Rank;
   begin
      declare
         procedure Run is new Enumerate (Check_Rank);
      begin
         Run (G);
      end;
      Check (Match, "Enumerate X = Point_At(Rank) for all");
      Check (Rank_Local = 6, "last rank was 6");
   end;

   ---------------------------------------------------------------------
   Section ("16. Higher-D cardinality / tiny grids");
   ---------------------------------------------------------------------
   declare
      Ones : constant Axis := Build_Axis ([0.0]);
      Twos : constant Axis := Build_Axis ([0.0, 1.0]);
      G6   : constant Grid := Make_Grid
        ([Ones, Ones, Ones, Ones, Ones, Twos]);
      R    : constant Result := Minimize (Sphere'Access, G6);
   begin
      Check (G6.Dim = 6, "6-D grid dim");
      Check (Cardinality (G6) = 2, "6-D card = 2");
      Check (R.Evaluations = 2, "6-D two evals");
      Check (Near (R.Best_F, 0.0), "6-D sphere picks zeros");
   end;

   declare
      A : constant Axis := Build_Linspace_Axis (0.0, 1.0, 16);
      G : constant Grid := Make_Grid ([A]);
   begin
      Check (Axis_Length (A) = 16, "max points per axis 16");
      Check (Cardinality (G) = 16, "1-D max axis card");
      Check (Near (Get_Value (A, 1), 0.0), "max-axis lo");
      Check (Near (Get_Value (A, 16), 1.0), "max-axis hi");
   end;

   ---------------------------------------------------------------------
   Section ("17. Search vs Minimize / Maximize aliases");
   ---------------------------------------------------------------------
   declare
      G : constant Grid := Make_Grid
        ([Build_Linspace_Axis (-1.0, 1.0, 7)]);
      Rm : constant Result := Minimize (Sphere'Access, G);
      Rs : constant Result :=
        Search (Sphere'Access, G, Default_Config (Minimize_Sense));
      Rx : constant Result := Maximize (Neg_Sphere'Access, G);
      Ry : constant Result :=
        Search (Neg_Sphere'Access, G, Default_Config (Maximize_Sense));
   begin
      Check (Near (Rm.Best_F, Rs.Best_F), "Minimize ≡ Search(min)");
      Check (Near (Rm.Best_X (1), Rs.Best_X (1)), "Minimize x ≡ Search x");
      Check (Rm.Best_Rank = Rs.Best_Rank, "Minimize rank ≡ Search rank");
      Check (Near (Rx.Best_F, Ry.Best_F), "Maximize ≡ Search(max)");
      Check (Near (Rx.Best_X (1), Ry.Best_X (1)), "Maximize x ≡ Search x");
   end;

   ---------------------------------------------------------------------
   Section ("18. Extra linspace / axis edge cases");
   ---------------------------------------------------------------------
   declare
      A : constant Axis := Build_Linspace_Axis (-3.5, 3.5, 8);
      B : constant Axis := Build_Axis ([1.0, 1.0, 1.0]);
      C : constant Axis := Build_Axis ([9.0, 8.0, 7.0, 6.0]);
   begin
      Check (Axis_Length (A) = 8, "linspace 8");
      Check (Near (Get_Value (A, 1), -3.5), "linspace -3.5");
      Check (Near (Get_Value (A, 8), 3.5), "linspace 3.5");
      Check (Axis_Length (B) = 1, "all-equal dedupe to 1");
      Check (Near (Get_Value (B, 1), 1.0), "all-equal value");
      Check (Axis_Length (C) = 4, "reverse sorted length");
      Check (Near (Get_Value (C, 1), 6.0), "reverse → sorted first");
      Check (Near (Get_Value (C, 4), 9.0), "reverse → sorted last");
   end;

   ---------------------------------------------------------------------
   Section ("19. 1-D exhaustive identity");
   ---------------------------------------------------------------------
   declare
      Vals : constant Value_Array := [0.3, -0.1, 0.7, 0.0, -0.5];
      A    : constant Axis := Build_Axis (Vals);
      G    : constant Grid := Make_Grid ([A]);
      R    : constant Result := Minimize (Sphere'Access, G);
   begin
      Check (Cardinality (G) = 5, "unsorted 1-D card 5");
      Check (Near (R.Best_X (1), 0.0), "1-D sphere picks 0");
      Check (Near (R.Best_F, 0.0), "1-D sphere f=0");
      Check (R.Evaluations = 5, "1-D five evals");
   end;

   ---------------------------------------------------------------------
   Section ("20. Wikipedia SVM example sets");
   ---------------------------------------------------------------------
   --  Exactly the discrete sets from the Wikipedia Grid search section.
   declare
      C_Set : constant Axis := Build_Axis ([10.0, 100.0, 1000.0]);
      G_Set : constant Axis := Build_Axis ([0.1, 0.2, 0.5, 1.0]);
      G     : constant Grid := Make_Grid ([C_Set, G_Set]);
      Seen  : Natural := 0;
      procedure Tally
        (X : Point; Rank : Positive; Stop : in out Boolean)
      is
      begin
         pragma Unreferenced (X, Rank, Stop);
         Seen := Seen + 1;
      end Tally;
   begin
      Check (Axis_Length (C_Set) = 3, "Wiki C set size 3");
      Check (Axis_Length (G_Set) = 4, "Wiki γ set size 4");
      Check (Cardinality (G) = 12, "Wiki Cartesian |G|=12");
      declare
         procedure Run is new Enumerate (Tally);
      begin
         Run (G);
      end;
      Check (Seen = 12, "Wiki Enumerate 12 pairs");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   Put_Line ("======================================");
   if Fail_Count /= 0 then
      raise Program_Error with "tests failed";
   end if;
end Tests;
