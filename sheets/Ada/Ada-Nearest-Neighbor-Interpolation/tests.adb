--  Standalone test suite for Nearest_Neighbor_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Nearest_Neighbor_Interpolation; use Nearest_Neighbor_Interpolation;

procedure Tests is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line ("Nearest_Neighbor_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=========================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Dist / Make_Site / Round_Index");
   ---------------------------------------------------------------------
   declare
      A1 : constant Site_1D := Make_Site_1D (1.0);
      B1 : constant Site_1D := Make_Site_1D (1.0 + 1.0E-8);
      C1 : constant Site_1D := Make_Site_1D (4.0);
      A2 : constant Site_2D := Make_Site_2D (0.0, 0.0);
      B2 : constant Site_2D := Make_Site_2D (3.0, 4.0);
      A3 : constant Site_3D := Make_Site_3D (0.0, 0.0, 0.0);
      B3 : constant Site_3D := Make_Site_3D (1.0, 2.0, 2.0);
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      Check (Near (A1, B1), "Near Site_1D");
      Check (not Near (A1, C1), "Near rejects Site_1D");
      Check (Near (A2, Make_Site_2D (0.0, 0.0)), "Near Site_2D");
      Check (Approx (Dist (A1, C1), 3.0), "Dist 1D");
      Check (Approx (Dist (A1, C1, Manhattan), 3.0), "Dist 1D Manhattan");
      Check (Approx (Dist (A2, B2, Euclidean), 5.0), "Dist 2D Euclidean 3-4-5");
      Check (Approx (Dist (A2, B2, Manhattan), 7.0), "Dist 2D Manhattan");
      Check (Approx (Dist (A3, B3, Euclidean), 3.0), "Dist 3D Euclidean");
      Check (Approx (Dist (A3, B3, Manhattan), 5.0), "Dist 3D Manhattan");
      Check (Round_Index (0.0, 4) = 0, "Round 0.0 → 0");
      Check (Round_Index (0.4, 4) = 0, "Round 0.4 → 0");
      Check (Round_Index (0.5, 4) = 0, "Round 0.5 tie → lower 0");
      Check (Round_Index (0.50001, 4) = 1, "Round just over 0.5 → 1");
      Check (Round_Index (1.5, 4) = 1, "Round 1.5 tie → lower 1");
      Check (Round_Index (1.6, 4) = 2, "Round 1.6 → 2");
      Check (Round_Index (4.0, 4) = 4, "Round last");
      Check (Round_Index (2.0, 0) = 0, "Round Last=0");
      Check (Approx (Make_Site_3D (1.0, 2.0, 3.0).Z, 3.0), "Make_Site_3D");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / Get / Set / examples");
   ---------------------------------------------------------------------
   declare
      L  : constant Grid_1D := Make_Linear_1D (5, 0.0, 8.0);
      Cb : Grid_2D := Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      R3 : constant Grid_3D := Make_Ramp_3D (3, 3, 3);
      S1 : constant Scattered_1D :=
        Make_Scattered_1D_Linear (5, 0.0, 4.0, 0.0, 8.0);
      S2 : constant Scattered_2D := Make_Scattered_Cloud_2D (8);
      E1 : constant Grid_1D := Make_Example_Grid_1D;
      E2 : constant Grid_2D := Make_Example_Grid_2D;
      E3 : constant Grid_3D := Make_Example_Grid_3D;
      Es : constant Scattered_2D := Make_Example_Scattered_2D;
   begin
      Check (Is_Valid_Grid (L) and L.N = 5, "Linear_1D dims");
      Check (Approx (Get (L, 0), 0.0), "Linear get 0");
      Check (Approx (Get (L, 4), 8.0), "Linear get last");
      Check (Approx (Get (L, 2), 4.0), "Linear get mid");
      Check (Is_Valid_Grid (Cb) and Cb.Nx = 4 and Cb.Ny = 4,
             "Checkerboard dims");
      Check (Approx (Get (Cb, 0, 0), 1.0), "Checker Hi at (0,0)");
      Check (Approx (Get (Cb, 0, 1), 0.0), "Checker Lo at (0,1)");
      Check (Approx (Get (Cb, 1, 0), 0.0), "Checker Lo at (1,0)");
      Check (Approx (Get (Cb, 1, 1), 1.0), "Checker Hi at (1,1)");
      Set (Cb, 2, 3, 9.0);
      Check (Approx (Get (Cb, 2, 3), 9.0), "Set/Get 2D roundtrip");
      Check (Approx (Get (R3, 1, 2, 0), 1.0 + 4.0), "Ramp (1,2,0)=5");
      Check (Approx (Get (R3, 2, 2, 2), 2.0 + 4.0 + 6.0), "Ramp (2,2,2)=12");
      Check (Is_Valid_Scattered (S1) and S1.Count = 5, "Scattered 1D count");
      Check (Approx (S1.Sites (0).X, 0.0) and Approx (S1.Values (0), 0.0),
             "Scattered 1D start");
      Check (Approx (S1.Sites (4).X, 4.0) and Approx (S1.Values (4), 8.0),
             "Scattered 1D end");
      Check (Is_Valid_Scattered (S2) and S2.Count = 8, "Cloud count 8");
      Check (Approx (S2.Sites (0).X, 1.0) and Approx (S2.Sites (0).Y, 0.0),
             "Cloud site 0 at (1,0)");
      Check (Approx (S2.Values (3), 3.0), "Cloud value 3");
      Check (E1.N = 5 and Approx (Get (E1, 4), 8.0), "Example grid 1D");
      Check (E2.Nx = 4 and Approx (Get (E2, 0, 0), 1.0), "Example grid 2D");
      Check (Es.Count = 8, "Example scattered 2D");
      Check (E3.Nx = 4 and Approx (Get (E3, 1, 1, 1), 6.0),
             "Example grid 3D (1,1,1)=6");
      Check (not Is_Valid_Scattered (Make_Empty_Scattered_1D),
             "Empty scattered 1D invalid");
      Check (not Is_Valid_Scattered (Make_Empty_Scattered_2D),
             "Empty scattered 2D invalid");
      Check (Is_Valid_Grid (Make_Empty_Grid_1D (3)), "Empty grid 1D valid");
      Check (Is_Valid_Grid (Make_Empty_Grid_2D (2, 2)), "Empty grid 2D valid");
      Check (Is_Valid_Grid (Make_Empty_Grid_3D (2, 2, 2)),
             "Empty grid 3D valid");
   end;

   ---------------------------------------------------------------------
   Section ("3. Scattered 1D: exact at sites / midpoints / ties");
   ---------------------------------------------------------------------
   declare
      S : Scattered_1D := Make_Scattered_1D_Linear (5, 0.0, 4.0, 0.0, 40.0);
      R : Eval_Result;
      N : Nearest_Result;
   begin
      --  Sites at 0,1,2,3,4 with values 0,10,20,30,40
      for I in 0 .. 4 loop
         R := Evaluate_Scattered (S, Float (I));
         Check
           (R.Success and Approx (R.Value, Float (I) * 10.0)
            and R.Index = I,
            "Scattered1D exact site" & Integer'Image (I));
      end loop;
      --  Midpoint 0.5 → tie between 0 and 1 → lower index 0
      R := Evaluate_Scattered (S, 0.5);
      Check
        (R.Success and R.Index = 0 and Approx (R.Value, 0.0),
         "Scattered1D midpoint 0.5 → idx 0");
      R := Evaluate_Scattered (S, 1.5);
      Check
        (R.Success and R.Index = 1 and Approx (R.Value, 10.0),
         "Scattered1D midpoint 1.5 → idx 1");
      R := Evaluate_Scattered (S, 2.4);
      Check
        (R.Success and R.Index = 2 and Approx (R.Value, 20.0),
         "Scattered1D 2.4 → idx 2");
      R := Evaluate_Scattered (S, 2.6);
      Check
        (R.Success and R.Index = 3 and Approx (R.Value, 30.0),
         "Scattered1D 2.6 → idx 3");
      N := Nearest_Index (S, Make_Site_1D (3.0));
      Check (N.Success and N.Index = 3 and Approx (N.Dist, 0.0),
             "Nearest_Index at site 3");
      --  Duplicate-distance tie: two sites equidistant → lower index
      S.Count := 2;
      S.Sites (0)  := Make_Site_1D (-1.0);
      S.Sites (1)  := Make_Site_1D (1.0);
      S.Values (0) := 100.0;
      S.Values (1) := 200.0;
      R := Evaluate_Scattered (S, 0.0);
      Check
        (R.Success and R.Index = 0 and Approx (R.Value, 100.0),
         "Scattered1D equidistant tie → lower");
   end;

   ---------------------------------------------------------------------
   Section ("4. Scattered 2D: Voronoi cells / corners / Manhattan");
   ---------------------------------------------------------------------
   declare
      S : Scattered_2D;
      R : Eval_Result;
      N : Nearest_Result;
   begin
      S.Count := 4;
      S.Valid := True;
      --  Unit square corners: values encode index
      S.Sites (0)  := Make_Site_2D (0.0, 0.0);  S.Values (0) := 0.0;
      S.Sites (1)  := Make_Site_2D (1.0, 0.0);  S.Values (1) := 1.0;
      S.Sites (2)  := Make_Site_2D (0.0, 1.0);  S.Values (2) := 2.0;
      S.Sites (3)  := Make_Site_2D (1.0, 1.0);  S.Values (3) := 3.0;

      R := Evaluate_Scattered (S, 0.0, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "Voronoi at (0,0)");
      R := Evaluate_Scattered (S, 1.0, 0.0);
      Check (R.Success and Approx (R.Value, 1.0), "Voronoi at (1,0)");
      R := Evaluate_Scattered (S, 0.0, 1.0);
      Check (R.Success and Approx (R.Value, 2.0), "Voronoi at (0,1)");
      R := Evaluate_Scattered (S, 1.0, 1.0);
      Check (R.Success and Approx (R.Value, 3.0), "Voronoi at (1,1)");

      --  Cell interiors
      R := Evaluate_Scattered (S, 0.2, 0.2);
      Check (R.Success and R.Index = 0, "Voronoi cell of site 0");
      R := Evaluate_Scattered (S, 0.8, 0.1);
      Check (R.Success and R.Index = 1, "Voronoi cell of site 1");
      R := Evaluate_Scattered (S, 0.1, 0.8);
      Check (R.Success and R.Index = 2, "Voronoi cell of site 2");
      R := Evaluate_Scattered (S, 0.9, 0.9);
      Check (R.Success and R.Index = 3, "Voronoi cell of site 3");

      --  Center of square: equidistant to all four → lowest index 0
      R := Evaluate_Scattered (S, 0.5, 0.5);
      Check
        (R.Success and R.Index = 0 and Approx (R.Value, 0.0),
         "Voronoi center tie → idx 0");

      --  Mid-edge (0.5, 0): equidistant to 0 and 1 → lower 0
      R := Evaluate_Scattered (S, 0.5, 0.0);
      Check (R.Success and R.Index = 0, "Voronoi edge mid → lower");

      --  Manhattan changes the metric ball
      R := Evaluate_Scattered (S, 0.6, 0.1, Manhattan);
      Check (R.Success and R.Index = 1,
             "Manhattan prefers site 1 near (0.6,0.1)");
      N := Nearest_Index (S, Make_Site_2D (0.1, 0.6), Manhattan);
      Check (N.Success and N.Index = 2, "Manhattan Nearest_Index site 2");

      --  Cloud example: query near angle π/2 → site 2 (for Count=8)
      declare
         C : constant Scattered_2D := Make_Scattered_Cloud_2D (8);
         Qc : constant Float := Ada.Numerics.Pi / 2.0;
      begin
         R := Evaluate_Scattered (C, Math.Cos (Qc), Math.Sin (Qc));
         Check
           (R.Success and R.Index = 2 and Approx (R.Value, 2.0),
            "Cloud query at π/2 → site 2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Grid 1D rounding / exact / midpoints / domain");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_1D := Make_Linear_1D (5, 0.0, 40.0);
      --  values 0,10,20,30,40 at indices 0..4
      R : Eval_Result;
   begin
      Check (In_Domain (G, 0.0), "Grid1D domain 0");
      Check (In_Domain (G, 4.0), "Grid1D domain last");
      Check (In_Domain (G, 2.5), "Grid1D domain mid");
      Check (not In_Domain (G, -0.01), "Grid1D reject <0");
      Check (not In_Domain (G, 4.01), "Grid1D reject >last");

      for I in 0 .. 4 loop
         R := Evaluate_Grid_1D (G, Float (I));
         Check
           (R.Success and Approx (R.Value, Float (I) * 10.0)
            and R.I = I,
            "Grid1D exact" & Integer'Image (I));
      end loop;

      R := Evaluate_Grid_1D (G, 0.5);
      Check
        (R.Success and R.I = 0 and Approx (R.Value, 0.0),
         "Grid1D 0.5 → lower 0");
      R := Evaluate_Grid_1D (G, 1.5);
      Check
        (R.Success and R.I = 1 and Approx (R.Value, 10.0),
         "Grid1D 1.5 → lower 1");
      R := Evaluate_Grid_1D (G, 2.49);
      Check (R.Success and R.I = 2, "Grid1D 2.49 → 2");
      R := Evaluate_Grid_1D (G, 2.51);
      Check (R.Success and R.I = 3, "Grid1D 2.51 → 3");
      R := Evaluate_Grid_1D (G, 3.9);
      Check
        (R.Success and R.I = 4 and Approx (R.Value, 40.0),
         "Grid1D 3.9 → 4");

      R := Evaluate_Grid_1D (G, -1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Grid1D Out_Of_Domain low");
      R := Evaluate_Grid_1D (G, 5.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Grid1D Out_Of_Domain high");
   end;

   ---------------------------------------------------------------------
   Section ("6. Grid 2D checkerboard / rounding / corners");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      R : Eval_Result;
   begin
      Check (In_Domain (G, 0.0, 0.0), "Grid2D domain origin");
      Check (In_Domain (G, 3.0, 3.0), "Grid2D domain max");
      Check (not In_Domain (G, 3.1, 1.0), "Grid2D reject x");
      Check (not In_Domain (G, 1.0, -0.1), "Grid2D reject y");

      R := Evaluate_Grid_2D (G, 0.0, 0.0);
      Check
        (R.Success and Approx (R.Value, 1.0) and R.I = 0 and R.J = 0,
         "Grid2D exact (0,0)=Hi");
      R := Evaluate_Grid_2D (G, 1.0, 0.0);
      Check
        (R.Success and Approx (R.Value, 0.0) and R.I = 1 and R.J = 0,
         "Grid2D exact (1,0)=Lo");
      R := Evaluate_Grid_2D (G, 2.0, 2.0);
      Check
        (R.Success and Approx (R.Value, 1.0),
         "Grid2D exact (2,2)=Hi");

      --  Midpoint ties per axis → lower
      R := Evaluate_Grid_2D (G, 0.5, 0.5);
      Check
        (R.Success and R.I = 0 and R.J = 0 and Approx (R.Value, 1.0),
         "Grid2D (0.5,0.5) → (0,0)");
      R := Evaluate_Grid_2D (G, 1.5, 0.4);
      Check
        (R.Success and R.I = 1 and R.J = 0,
         "Grid2D (1.5,0.4) → (1,0)");
      R := Evaluate_Grid_2D (G, 1.6, 2.6);
      Check
        (R.Success and R.I = 2 and R.J = 3,
         "Grid2D (1.6,2.6) → (2,3)");

      --  Voronoi-cell style corners of unit cells
      R := Evaluate_Grid_2D (G, 0.49, 0.49);
      Check (R.Success and R.I = 0 and R.J = 0, "Cell corner near 0");
      R := Evaluate_Grid_2D (G, 0.51, 0.51);
      Check (R.Success and R.I = 1 and R.J = 1, "Cell corner past mid");

      R := Evaluate_Grid_2D (G, -0.5, 1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Grid2D Out_Of_Domain");
   end;

   ---------------------------------------------------------------------
   Section ("7. Grid 3D ramp / rounding");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Ramp_3D (4, 4, 4);
      R : Eval_Result;
   begin
      Check (In_Domain (G, 1.0, 2.0, 3.0), "Grid3D domain");
      Check (not In_Domain (G, 0.0, 0.0, 4.0), "Grid3D reject z");

      R := Evaluate_Grid_3D (G, 1.0, 1.0, 1.0);
      Check
        (R.Success and Approx (R.Value, 6.0)
         and R.I = 1 and R.J = 1 and R.K = 1,
         "Grid3D exact (1,1,1)=6");
      R := Evaluate_Grid_3D (G, 0.0, 0.0, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "Grid3D origin");
      R := Evaluate_Grid_3D (G, 3.0, 2.0, 1.0);
      Check
        (R.Success and Approx (R.Value, 3.0 + 4.0 + 3.0),
         "Grid3D (3,2,1)=10");

      R := Evaluate_Grid_3D (G, 1.5, 0.5, 2.5);
      Check
        (R.Success and R.I = 1 and R.J = 0 and R.K = 2,
         "Grid3D midpoints → lower");
      R := Evaluate_Grid_3D (G, 1.51, 0.51, 2.51);
      Check
        (R.Success and R.I = 2 and R.J = 1 and R.K = 3,
         "Grid3D past midpoints");

      R := Evaluate_Grid_3D (G, 5.0, 0.0, 0.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Grid3D Out_Of_Domain");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty / Ill_Started rejects");
   ---------------------------------------------------------------------
   declare
      Bad_S1 : constant Scattered_1D := Make_Empty_Scattered_1D;
      Bad_S2 : constant Scattered_2D := Make_Empty_Scattered_2D;
      Bad_G1 : Grid_1D;
      Bad_G2 : Grid_2D;
      Bad_G3 : Grid_3D;
      Zero   : Scattered_1D;
      R      : Eval_Result;
      N      : Nearest_Result;
   begin
      R := Evaluate_Scattered (Bad_S1, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Empty scattered1D → Ill_Started");
      R := Evaluate_Scattered (Bad_S2, 0.0, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Empty scattered2D → Ill_Started");
      N := Nearest_Index (Bad_S1, Make_Site_1D (0.0));
      Check (not N.Success and N.Stat = Ill_Started,
             "Nearest empty → Ill_Started");

      --  Valid flag but Count=0
      Zero.Valid := True;
      Zero.Count := 0;
      R := Evaluate_Scattered (Zero, 1.0);
      Check (not R.Success and R.Stat = Empty,
             "Count=0 → Empty");
      N := Nearest_Index (Zero, Make_Site_1D (1.0));
      Check (not N.Success and N.Stat = Empty,
             "Nearest Count=0 → Empty");

      R := Evaluate_Grid_1D (Bad_G1, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Unset grid1D → Ill_Started");
      R := Evaluate_Grid_2D (Bad_G2, 0.0, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Unset grid2D → Ill_Started");
      R := Evaluate_Grid_3D (Bad_G3, 0.0, 0.0, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Unset grid3D → Ill_Started");

      Check (not In_Domain (Bad_G1, 0.0), "In_Domain rejects bad 1D");
      Check (not In_Domain (Bad_G2, 0.0, 0.0), "In_Domain rejects bad 2D");
      Check (not In_Domain (Bad_G3, 0.0, 0.0, 0.0),
             "In_Domain rejects bad 3D");
   end;

   ---------------------------------------------------------------------
   Section ("9. Single-sample / Set 1D 3D / status fields");
   ---------------------------------------------------------------------
   declare
      G1 : Grid_1D := Make_Linear_1D (1, 7.0, 99.0);
      G3 : Grid_3D := Make_Empty_Grid_3D (2, 2, 2);
      S  : constant Scattered_1D :=
        Make_Scattered_1D_Linear (1, 3.0, 3.0, 42.0, 42.0);
      R  : Eval_Result;
   begin
      Check (Approx (Get (G1, 0), 7.0), "N=1 linear uses Y0");
      R := Evaluate_Grid_1D (G1, 0.0);
      Check (R.Success and Approx (R.Value, 7.0), "Grid1D N=1 eval");
      Set (G1, 0, 11.0);
      Check (Approx (Get (G1, 0), 11.0), "Set/Get 1D");
      Set (G3, 1, 0, 1, 5.5);
      Check (Approx (Get (G3, 1, 0, 1), 5.5), "Set/Get 3D");
      R := Evaluate_Scattered (S, 100.0);
      Check
        (R.Success and Approx (R.Value, 42.0) and R.Index = 0,
         "Single scattered site anywhere");
      R := Evaluate_Scattered (S, 3.0);
      Check (R.Success and Approx (R.Dist, 0.0), "Exact site Dist=0");
      Check (R.Stat = Ok, "Stat Ok on success");
   end;

   ---------------------------------------------------------------------
   Section ("10. Extra midpoint / lexicographic grid ties");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Checkerboard_2D (3, 3, -1.0, 2.0);
      R : Eval_Result;
      Pts : constant array (1 .. 6, 1 .. 2) of Float :=
        [[0.5, 0.0],
         [0.0, 0.5],
         [0.5, 0.5],
         [1.5, 1.5],
         [2.0, 0.5],
         [0.5, 2.0]];
      Expect_I : constant array (1 .. 6) of Natural :=
        [0, 0, 0, 1, 2, 0];
      Expect_J : constant array (1 .. 6) of Natural :=
        [0, 0, 0, 1, 0, 2];
   begin
      for P in 1 .. 6 loop
         R := Evaluate_Grid_2D (G, Pts (P, 1), Pts (P, 2));
         Check
           (R.Success
            and R.I = Expect_I (P)
            and R.J = Expect_J (P),
            "Lexico tie case" & Integer'Image (P));
      end loop;
      --  Values match checkerboard at those indices
      R := Evaluate_Grid_2D (G, 0.5, 0.5);
      Check (Approx (R.Value, 2.0), "Tie (0,0) value Hi=2");
      R := Evaluate_Grid_2D (G, 1.5, 1.5);
      Check (Approx (R.Value, 2.0), "Tie (1,1) value Hi=2");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
