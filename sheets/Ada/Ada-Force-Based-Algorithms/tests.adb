--  Standalone test suite for Force_Based_Algorithms (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Force_Based_Algorithms; use Force_Based_Algorithms;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Fl (X : Float) return Float is (X);
   function Iters (X : Positive) return Positive is (X);

   function Approx (A, B : Float; Tol : Float := 1.0e-2) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function All_Finite
     (Positions : Position_Array; N : Natural) return Boolean
   is
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if not Is_Finite (Positions (V)) then
            return False;
         end if;
      end loop;
      return True;
   end All_Finite;

   function Spread
     (Positions : Position_Array; N : Natural) return Float
   is
      D, M : Float := 0.0;
   begin
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            D := Euclidean
              (Positions (Vertex_Id (I)), Positions (Vertex_Id (J)));
            if D > M then
               M := D;
            end if;
         end loop;
      end loop;
      return M;
   end Spread;

   procedure Make_Path (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
   end Make_Path;

   procedure Make_Cycle (G : in out Graph; N : Natural) is
   begin
      Make_Path (G, N);
      if N >= 3 then
         Add_Edge (G, Vertex_Id (N), 1);
      end if;
   end Make_Cycle;

   procedure Make_Star (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
   end Make_Star;

   procedure Make_Complete (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Complete;

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Seed_Raises
     (G : Graph; Scale : Float; Last : Positive) return Boolean
   is
      P : Position_Array (1 .. Vertex_Id (Last));
   begin
      Seed_Positions (G, 1, Scale, P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Seed_Raises;

   function Layout_Raises
     (G : Graph; K, T0, Gamma : Float; Last : Positive;
      Sched : Temperature_Schedule) return Boolean
   is
      P : Position_Array (1 .. Vertex_Id (Last));
   begin
      for V in P'Range loop
         P (V) := (0.0, 0.0);
      end loop;
      Layout (G, 5, K, T0, Sched, Gamma, P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Layout_Raises;

   function Compute_Raises
     (G : Graph; K, T0, Gamma : Float; Last : Positive;
      Sched : Temperature_Schedule) return Boolean
   is
      P : Position_Array (1 .. Vertex_Id (Last));
   begin
      Compute (G, 5, K, T0, Sched, Gamma, 1, P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

   function Mean_Raises
     (G : Graph; Last : Positive) return Boolean
   is
      P : Position_Array (1 .. Vertex_Id (Last));
      X : Float;
   begin
      for V in P'Range loop
         P (V) := (0.0, 0.0);
      end loop;
      X := Mean_Edge_Length (G, P);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Mean_Raises;

   function Position_Of_Raises
     (Positions : Position_Array; V : Vertex_Id) return Boolean
   is
      Q : Point2D;
   begin
      Q := Position_Of (Positions, V);
      pragma Unreferenced (Q);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Position_Of_Raises;

   G    : Graph;
   Pos  : Position_Array (Vertex_Id);
   Pos2 : Position_Array (Vertex_Id);
   N    : Natural;
   D0   : Float;
   D1   : Float;
   D2   : Float;
   P0   : Point2D;
   Q    : Point2D;

begin
   -------------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "Clear(0) => V=0");
   Check (Edge_Count (G) = 0, "Clear(0) => E=0");

   Clear (G, Nat (5));
   Check (Vertex_Count (G) = 5, "Clear(5) => V=5");
   Check (Edge_Count (G) = 0, "Clear(5) => E=0");
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 3);
   Check (Edge_Count (G) = 3, "three undirected edges");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 4, "parallel edge allowed");
   Add_Edge (G, 4, 4);
   Check (Edge_Count (G) = 5, "self-loop allowed");
   Check (Vertex_Count (G) = 5, "V unchanged by Add_Edge");

   Clear (G, Nat (2));
   Check (Edge_Count (G) = 0, "Clear drops edges");
   Check (Vertex_Count (G) = 2, "Clear(2) => V=2");

   -------------------------------------------------------------------------
   Section ("2. Invalid_Argument on construction");
   -------------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear > Max_Vertices");
   Clear (G, Nat (5));
   Check (Add_Raises (G, 1, 6), "Add_Edge V out of range");
   Check (Add_Raises (G, 6, 1), "Add_Edge U out of range");
   Clear (G, Nat (0));
   Check (Add_Raises (G, 1, 1), "Add_Edge on empty graph");
   Clear (G, Nat (3));
   Check (not Add_Raises (G, 1, 3), "Add_Edge 1-3 valid");
   Check (not Add_Raises (G, 3, 3), "self-loop valid on N=3");

   -------------------------------------------------------------------------
   Section ("3. Invalid_Argument on Seed / Layout / Compute");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Seed_Raises (G, Fl (1.0), 1), "Seed on empty graph");
   Check (Layout_Raises (G, Fl (1.0), Fl (1.0), Fl (0.95), 1, Linear),
          "Layout on empty graph");
   Check (Compute_Raises (G, Fl (1.0), Fl (1.0), Fl (0.95), 1, Linear),
          "Compute on empty graph");
   Check (Mean_Raises (G, 1), "Mean_Edge_Length on empty graph");

   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Check (Seed_Raises (G, Fl (0.0), 3), "Seed Scale = 0");
   Check (Seed_Raises (G, Fl (-1.0), 3), "Seed Scale < 0");
   Check (Seed_Raises (G, Fl (1.0), 2), "Seed Positions too short");
   Check (Layout_Raises (G, Fl (0.0), Fl (1.0), Fl (0.95), 3, Linear),
          "Layout Ideal_Length = 0");
   Check (Layout_Raises (G, Fl (-0.5), Fl (1.0), Fl (0.95), 3, Linear),
          "Layout Ideal_Length < 0");
   Check (Layout_Raises (G, Fl (1.0), Fl (-0.1), Fl (0.95), 3, Linear),
          "Layout temperature < 0");
   Check (Layout_Raises (G, Fl (1.0), Fl (1.0), Fl (0.0), 3, Exponential),
          "Layout Cooling_Factor = 0 (exp)");
   Check (Layout_Raises (G, Fl (1.0), Fl (1.0), Fl (1.1), 3, Exponential),
          "Layout Cooling_Factor > 1 (exp)");
   Check (Layout_Raises (G, Fl (1.0), Fl (1.0), Fl (-0.5), 3, Exponential),
          "Layout Cooling_Factor < 0 (exp)");
   Check (Layout_Raises (G, Fl (1.0), Fl (1.0), Fl (0.95), 2, Linear),
          "Layout Positions too short");
   Check (Compute_Raises (G, Fl (0.0), Fl (1.0), Fl (0.95), 3, Linear),
          "Compute Ideal_Length = 0");
   Check (Compute_Raises (G, Fl (1.0), Fl (-1.0), Fl (0.95), 3, Linear),
          "Compute temperature < 0");
   Check (Compute_Raises (G, Fl (1.0), Fl (1.0), Fl (0.0), 3, Exponential),
          "Compute Cooling_Factor = 0 (exp)");
   Check (Compute_Raises (G, Fl (1.0), Fl (1.0), Fl (0.95), 2, Linear),
          "Compute Positions too short");

   -------------------------------------------------------------------------
   Section ("4. Position_Of / Euclidean / Is_Finite");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Seed_Positions (G, Nat (1), Fl (1.0), Pos);
   Q := Position_Of (Pos, 1);
   Check (Is_Finite (Q), "Position_Of(1) finite");
   Check (Is_Finite (Position_Of (Pos, 2)), "Position_Of(2) finite");
   Check (Euclidean (Pos (1), Pos (1)) = 0.0, "Euclidean self = 0");
   Check (Euclidean (Pos (1), Pos (2)) > 0.0, "seeded pair separated");
   declare
      Short : Position_Array (1 .. 2);
   begin
      Short (1) := (0.0, 0.0);
      Short (2) := (3.0, 4.0);
      Check (Approx (Euclidean (Short (1), Short (2)), 5.0, 1.0e-5),
             "3-4-5 Euclidean");
      Check (Position_Of_Raises (Short, 3), "Position_Of out of range");
      Check (not Position_Of_Raises (Short, 1), "Position_Of in range");
   end;
   Check (Is_Finite ((0.0, 0.0)), "origin finite");
   Check (Is_Finite ((1.0e20, -1.0e20)), "large finite coords");

   -------------------------------------------------------------------------
   Section ("5. Single vertex");
   -------------------------------------------------------------------------
   Clear (G, Nat (1));
   Compute (G, Iters (40), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 7, Pos);
   Check (Is_Finite (Pos (1)), "N=1 finite");
   Check (Approx (Pos (1).X, 0.0, 1.0e-6), "N=1 at origin X");
   Check (Approx (Pos (1).Y, 0.0, 1.0e-6), "N=1 at origin Y");
   Check (Mean_Raises (G, 1), "N=1 no edges => Mean raises");
   Seed_Positions (G, Nat (99), Fl (2.0), Pos2);
   Check (Approx (Pos2 (1).X, 0.0, 1.0e-6), "N=1 seed ignores scale X");
   Check (Approx (Pos2 (1).Y, 0.0, 1.0e-6), "N=1 seed ignores scale Y");

   -------------------------------------------------------------------------
   Section ("6. K2: edge length trends toward ideal");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Seed_Positions (G, Nat (1), Fl (1.0), Pos);
   D0 := Euclidean (Pos (1), Pos (2));
   Layout (G, Iters (250), Fl (1.0), Fl (1.0), Linear, Fl (0.95), Pos);
   D1 := Euclidean (Pos (1), Pos (2));
   Check (All_Finite (Pos, 2), "K2 finite after layout");
   Check (abs (D1 - 1.0) < abs (D0 - 1.0), "K2 closer to ideal than seed");
   Check (Approx (D1, 1.0, 0.35), "K2 edge near ideal k=1");
   Check (Approx (Mean_Edge_Length (G, Pos), D1, 1.0e-5),
          "K2 mean equals the one edge");

   Compute (G, Iters (250), Fl (2.0), Fl (2.0), Linear, Fl (0.95), 3, Pos);
   D2 := Euclidean (Pos (1), Pos (2));
   Check (All_Finite (Pos, 2), "K2 k=2 finite");
   Check (Approx (D2, 2.0, 0.7), "K2 edge near ideal k=2");
   Check (D2 > D1, "larger k yields longer K2 edge");

   Compute (G, Iters (250), Fl (0.5), Fl (0.5), Linear, Fl (0.95), 3, Pos);
   D0 := Euclidean (Pos (1), Pos (2));
   Check (Approx (D0, 0.5, 0.25), "K2 edge near ideal k=0.5");

   -------------------------------------------------------------------------
   Section ("7. K3: roughly uniform edges near ideal");
   -------------------------------------------------------------------------
   Make_Complete (G, Nat (3));
   Compute (G, Iters (250), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 2, Pos);
   Check (All_Finite (Pos, 3), "K3 finite");
   D0 := Euclidean (Pos (1), Pos (2));
   D1 := Euclidean (Pos (1), Pos (3));
   D2 := Euclidean (Pos (2), Pos (3));
   Check (Approx (D0, 1.0, 0.45), "K3 e12 near ideal");
   Check (Approx (D1, 1.0, 0.45), "K3 e13 near ideal");
   Check (Approx (D2, 1.0, 0.45), "K3 e23 near ideal");
   Check (abs (D0 - D1) < 0.4, "K3 edges comparable 12 vs 13");
   Check (abs (D0 - D2) < 0.4, "K3 edges comparable 12 vs 23");
   Check (Approx (Mean_Edge_Length (G, Pos), (D0 + D1 + D2) / 3.0, 1.0e-5),
          "K3 mean of three edges");

   -------------------------------------------------------------------------
   Section ("8. Path of 3: ends farther than adjacent");
   -------------------------------------------------------------------------
   Make_Path (G, Nat (3));
   Compute (G, Iters (200), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 4, Pos);
   Check (All_Finite (Pos, 3), "P3 finite");
   D0 := Euclidean (Pos (1), Pos (2));
   D1 := Euclidean (Pos (2), Pos (3));
   D2 := Euclidean (Pos (1), Pos (3));
   Check (D2 > D0, "P3: 1--3 longer than 1--2");
   Check (D2 > D1, "P3: 1--3 longer than 2--3");
   Check (D0 > 0.0 and then D1 > 0.0, "P3 adjacent positive");
   Check (Mean_Edge_Length (G, Pos) > 0.0, "P3 mean positive");

   -------------------------------------------------------------------------
   Section ("9. Cycles C4 C5 C6 finite and positive mean");
   -------------------------------------------------------------------------
   for C in Natural range 4 .. 8 loop
      Make_Cycle (G, C);
      Compute (G, Iters (120), Fl (1.0), Fl (1.0), Linear, Fl (0.95),
               C, Pos);
      Check (All_Finite (Pos, C),
             "C" & Natural'Image (C) & " finite");
      Check (Mean_Edge_Length (G, Pos) > 0.0,
             "C" & Natural'Image (C) & " mean > 0");
      Check (Spread (Pos, C) > Mean_Edge_Length (G, Pos) * 0.5,
             "C" & Natural'Image (C) & " spread vs mean");
   end loop;

   -------------------------------------------------------------------------
   Section ("10. Star: leaves around hub");
   -------------------------------------------------------------------------
   Make_Star (G, Nat (6));
   Compute (G, Iters (180), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 5, Pos);
   Check (All_Finite (Pos, 6), "star-6 finite");
   Check (Edge_Count (G) = 5, "star-6 has 5 edges");
   D0 := Mean_Edge_Length (G, Pos);
   Check (D0 > 0.2, "star mean not collapsed");
   Check (Approx (D0, 1.0, 0.8), "star mean order of k");
   --  Leaves should not all sit on the hub.
   D1 := Euclidean (Pos (2), Pos (3));
   Check (D1 > 0.05, "two leaves separated");
   D2 := Euclidean (Pos (1), Pos (2));
   Check (D2 > 0.05, "hub-leaf separated");

   -------------------------------------------------------------------------
   Section ("11. Determinism: same seed => same positions");
   -------------------------------------------------------------------------
   Make_Path (G, Nat (7));
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 11, Pos);
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 11, Pos2);
   Check (All_Finite (Pos, 7), "det A finite");
   Check (All_Finite (Pos2, 7), "det B finite");
   for V in Vertex_Id range 1 .. 7 loop
      Check (Approx (Pos (V).X, Pos2 (V).X, 1.0e-6)
             and then Approx (Pos (V).Y, Pos2 (V).Y, 1.0e-6),
             "same seed vertex" & Vertex_Id'Image (V));
   end loop;

   -------------------------------------------------------------------------
   Section ("12. Different seeds differ (N>=2)");
   -------------------------------------------------------------------------
   Make_Cycle (G, Nat (5));
   Compute (G, Iters (60), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 1, Pos);
   Compute (G, Iters (60), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 2, Pos2);
   declare
      Differ : Boolean := False;
   begin
      for V in Vertex_Id range 1 .. 5 loop
         if abs (Pos (V).X - Pos2 (V).X) > 1.0e-4
           or else abs (Pos (V).Y - Pos2 (V).Y) > 1.0e-4
         then
            Differ := True;
         end if;
      end loop;
      Check (Differ, "seed 1 vs 2 produces different coords");
   end;
   Seed_Positions (G, Nat (0), Fl (1.0), Pos);
   Seed_Positions (G, Nat (1), Fl (1.0), Pos2);
   Check (abs (Pos (1).X - Pos2 (1).X) > 1.0e-6
          or else abs (Pos (1).Y - Pos2 (1).Y) > 1.0e-6
          or else abs (Pos (2).X - Pos2 (2).X) > 1.0e-6,
          "raw seeds 0 vs 1 differ");

   -------------------------------------------------------------------------
   Section ("13. Layout reuses positions (temperature 0 frozen)");
   -------------------------------------------------------------------------
   Make_Path (G, Nat (4));
   Seed_Positions (G, Nat (3), Fl (1.0), Pos);
   P0 := Pos (2);
   Layout (G, Iters (30), Fl (1.0), Fl (0.0), Linear, Fl (0.95), Pos);
   Check (Approx (Pos (2).X, P0.X, 1.0e-6), "T=0 freezes X");
   Check (Approx (Pos (2).Y, P0.Y, 1.0e-6), "T=0 freezes Y");
   Check (All_Finite (Pos, 4), "T=0 still finite");
   --  Continue from a Compute result with extra iterations.
   Compute (G, Iters (40), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 8, Pos);
   D0 := Mean_Edge_Length (G, Pos);
   Layout (G, Iters (40), Fl (1.0), Fl (0.4), Linear, Fl (0.95), Pos);
   D1 := Mean_Edge_Length (G, Pos);
   Check (All_Finite (Pos, 4), "continued layout finite");
   Check (D0 > 0.0, "pre-continue mean positive");
   Check (D1 > 0.0, "continued mean positive");

   -------------------------------------------------------------------------
   Section ("14. Linear vs exponential cooling");
   -------------------------------------------------------------------------
   Make_Complete (G, Nat (4));
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 6, Pos);
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Exponential, Fl (0.9), 6, Pos2);
   Check (All_Finite (Pos, 4), "linear K4 finite");
   Check (All_Finite (Pos2, 4), "exp K4 finite");
   Check (Mean_Edge_Length (G, Pos) > 0.0, "linear K4 mean > 0");
   Check (Mean_Edge_Length (G, Pos2) > 0.0, "exp K4 mean > 0");
   Check (not Layout_Raises
            (G, Fl (1.0), Fl (1.0), Fl (1.0), 4, Exponential),
          "Cooling_Factor = 1 allowed (no decay)");
   Check (not Layout_Raises
            (G, Fl (1.0), Fl (1.0), Fl (-5.0), 4, Linear),
          "Linear ignores bogus Cooling_Factor");

   -------------------------------------------------------------------------
   Section ("15. Connected paths finite (battery)");
   -------------------------------------------------------------------------
   for K in Natural range 2 .. 16 loop
      Make_Path (G, K);
      Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95),
               K * 3, Pos);
      Check (All_Finite (Pos, K),
             "path" & Natural'Image (K) & " finite");
      Check (Mean_Edge_Length (G, Pos) > 0.0,
             "path" & Natural'Image (K) & " mean > 0");
      Check (Vertex_Count (G) = K,
             "path" & Natural'Image (K) & " V");
      Check (Edge_Count (G) = K - 1,
             "path" & Natural'Image (K) & " E=N-1");
   end loop;

   -------------------------------------------------------------------------
   Section ("16. Connected cycles / stars finite (battery)");
   -------------------------------------------------------------------------
   for K in Natural range 3 .. 12 loop
      Make_Cycle (G, K);
      Compute (G, Iters (70), Fl (1.0), Fl (1.0), Linear, Fl (0.95),
               K + 10, Pos);
      Check (All_Finite (Pos, K),
             "cycle" & Natural'Image (K) & " finite");
      Check (Edge_Count (G) = K,
             "cycle" & Natural'Image (K) & " E=N");
   end loop;
   for K in Natural range 2 .. 12 loop
      Make_Star (G, K);
      Compute (G, Iters (70), Fl (1.0), Fl (1.0), Linear, Fl (0.95),
               K + 4, Pos);
      Check (All_Finite (Pos, K),
             "star" & Natural'Image (K) & " finite");
      Check (Edge_Count (G) = K - 1,
             "star" & Natural'Image (K) & " E");
   end loop;

   -------------------------------------------------------------------------
   Section ("17. Complete graphs Kn mean near ideal");
   -------------------------------------------------------------------------
   for K in Natural range 2 .. 8 loop
      Make_Complete (G, K);
      Compute (G, Iters (200), Fl (1.0), Fl (1.0), Linear, Fl (0.95),
               K, Pos);
      Check (All_Finite (Pos, K),
             "K" & Natural'Image (K) & " finite");
      Check (Approx (Mean_Edge_Length (G, Pos), 1.0, 0.55),
             "K" & Natural'Image (K) & " mean near k=1");
      Check (Edge_Count (G) = K * (K - 1) / 2,
             "K" & Natural'Image (K) & " edge count");
   end loop;

   -------------------------------------------------------------------------
   Section ("18. Self-loop skipped; parallel edges stored");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop counted in E");
   Check (Mean_Raises (G, 2), "only self-loop => Mean raises");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 2, "loop + real edge");
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 1, Pos);
   Check (All_Finite (Pos, 2), "loop+edge finite");
   Check (Mean_Edge_Length (G, Pos) > 0.0, "mean ignores loop");

   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Check (Edge_Count (G) = 3, "three parallel undirected records");
   Compute (G, Iters (120), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 2, Pos);
   Check (All_Finite (Pos, 2), "parallels finite");
   Check (Approx (Mean_Edge_Length (G, Pos),
                  Euclidean (Pos (1), Pos (2)), 1.0e-5),
          "parallel mean equals the geometric edge");

   -------------------------------------------------------------------------
   Section ("19. More iterations closer to ideal on K2");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Compute (G, Iters (20), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 9, Pos);
   D0 := abs (Euclidean (Pos (1), Pos (2)) - 1.0);
   Compute (G, Iters (300), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 9, Pos);
   D1 := abs (Euclidean (Pos (1), Pos (2)) - 1.0);
   Check (All_Finite (Pos, 2), "long K2 finite");
   Check (D1 <= D0 + 0.05, "more iters not worse (slack)");
   Check (D1 < 0.4, "long run reasonably near k");

   -------------------------------------------------------------------------
   Section ("20. Disconnected vertices stay finite");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   --  Two disjoint edges.
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Compute (G, Iters (80), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 13, Pos);
   Check (All_Finite (Pos, 4), "2+2 finite");
   Check (Mean_Edge_Length (G, Pos) > 0.0, "2+2 mean > 0");
   Clear (G, Nat (5));
   --  Isolated vertices only.
   Compute (G, Iters (40), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 4, Pos);
   Check (All_Finite (Pos, 5), "5 isolated finite");
   Check (Spread (Pos, 5) > 0.0, "isolated still spread by repulsion");
   Check (Mean_Raises (G, 5), "isolated Mean raises (no edges)");

   -------------------------------------------------------------------------
   Section ("21. Grid 3x3 tree-like and path-tree");
   -------------------------------------------------------------------------
   Clear (G, Nat (9));
   --  3x3 grid edges (row-major).
   for R in 0 .. 2 loop
      for C in 0 .. 2 loop
         N := R * 3 + C + 1;
         if C < 2 then
            Add_Edge (G, Vertex_Id (N), Vertex_Id (N + 1));
         end if;
         if R < 2 then
            Add_Edge (G, Vertex_Id (N), Vertex_Id (N + 3));
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "3x3 grid has 12 edges");
   Compute (G, Iters (100), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 15, Pos);
   Check (All_Finite (Pos, 9), "grid finite");
   Check (Mean_Edge_Length (G, Pos) > 0.15, "grid mean not collapsed");
   Check (Spread (Pos, 9) > Mean_Edge_Length (G, Pos),
          "grid spread exceeds mean edge");

   -------------------------------------------------------------------------
   Section ("22. Edge capacity overflow");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   declare
      Overflowed : Boolean := False;
      Count      : Natural := 0;
   begin
      begin
         for I in 1 .. Max_Edges + 1 loop
            Add_Edge (G, 1, 2);
            Count := Count + 1;
         end loop;
      exception
         when Invalid_Argument =>
            Overflowed := True;
      end;
      Check (Overflowed, "Add_Edge overflow at Max_Edges");
      Check (Edge_Count (G) = Max_Edges, "E sits at Max_Edges");
      Check (Count = Max_Edges, "exactly Max_Edges inserted");
   end;

   -------------------------------------------------------------------------
   Section ("23. Seed extra slots zeroed; Compute writes full out-array");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   for V in Pos'Range loop
      Pos (V) := (99.0, -99.0);
   end loop;
   Seed_Positions (G, Nat (5), Fl (1.0), Pos);
   Check (Approx (Pos (4).X, 0.0, 1.0e-6), "extra slot X zeroed");
   Check (Approx (Pos (4).Y, 0.0, 1.0e-6), "extra slot Y zeroed");
   Check (Is_Finite (Pos (1)) and then Is_Finite (Pos (2))
          and then Is_Finite (Pos (3)),
          "seeded 1..3 finite");
   Compute (G, Iters (50), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 1, Pos);
   Check (Approx (Pos (Vertex_Id (Max_Vertices)).X, 0.0, 1.0e-6),
          "Compute extra last X zero");
   Check (Approx (Pos (Vertex_Id (Max_Vertices)).Y, 0.0, 1.0e-6),
          "Compute extra last Y zero");

   -------------------------------------------------------------------------
   Section ("24. Exponential Cooling_Factor extremes that are valid");
   -------------------------------------------------------------------------
   Make_Path (G, Nat (5));
   Compute (G, Iters (40), Fl (1.0), Fl (1.0), Exponential, Fl (0.5), 2, Pos);
   Check (All_Finite (Pos, 5), "gamma=0.5 finite");
   Compute (G, Iters (40), Fl (1.0), Fl (1.0), Exponential, Fl (1.0), 2, Pos);
   Check (All_Finite (Pos, 5), "gamma=1.0 finite (constant T)");
   Compute (G, Iters (40), Fl (1.0), Fl (0.2), Exponential, Fl (0.8), 2, Pos);
   Check (All_Finite (Pos, 5), "small T0 exp finite");
   Check (Mean_Edge_Length (G, Pos) > 0.0, "exp path mean > 0");

   -------------------------------------------------------------------------
   Section ("25. Mixed graph: tree plus extra chord");
   -------------------------------------------------------------------------
   Clear (G, Nat (6));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 4, 6);
   Add_Edge (G, 2, 5);  -- chord
   Compute (G, Iters (100), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 21, Pos);
   Check (All_Finite (Pos, 6), "tree+chord finite");
   Check (Edge_Count (G) = 6, "tree+chord E=6");
   Check (Mean_Edge_Length (G, Pos) > 0.1, "tree+chord mean");
   Check (Spread (Pos, 6) > 0.5, "tree+chord spread");

   -------------------------------------------------------------------------
   Section ("26. Scale of seed vs layout");
   -------------------------------------------------------------------------
   Make_Path (G, Nat (4));
   Seed_Positions (G, Nat (1), Fl (1.0), Pos);
   Seed_Positions (G, Nat (1), Fl (3.0), Pos2);
   D0 := Spread (Pos, 4);
   D1 := Spread (Pos2, 4);
   Check (D1 > D0, "larger Scale => larger seed spread");
   Check (All_Finite (Pos, 4), "scale-1 seed finite");
   Check (All_Finite (Pos2, 4), "scale-3 seed finite");

   -------------------------------------------------------------------------
   Section ("27. Wheel-like and complete bipartite K(2,3)");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   --  Wheel W4: hub 1, rim 2-3-4-5.
   for I in 2 .. 5 loop
      Add_Edge (G, 1, Vertex_Id (I));
   end loop;
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 2);
   Compute (G, Iters (120), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 8, Pos);
   Check (All_Finite (Pos, 5), "wheel finite");
   Check (Edge_Count (G) = 8, "wheel E=8");
   Check (Mean_Edge_Length (G, Pos) > 0.15, "wheel mean");

   Clear (G, Nat (5));
   --  K(2,3): {1,2} x {3,4,5}
   for A in 1 .. 2 loop
      for B in 3 .. 5 loop
         Add_Edge (G, Vertex_Id (A), Vertex_Id (B));
      end loop;
   end loop;
   Compute (G, Iters (120), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 12, Pos);
   Check (All_Finite (Pos, 5), "K2,3 finite");
   Check (Edge_Count (G) = 6, "K2,3 E=6");
   Check (Mean_Edge_Length (G, Pos) > 0.15, "K2,3 mean");

   -------------------------------------------------------------------------
   Section ("28. Positions'Last > N is allowed");
   -------------------------------------------------------------------------
   declare
      Wide : Position_Array (1 .. 10);
   begin
      Make_Path (G, Nat (4));
      Compute (G, Iters (40), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 1, Wide);
      Check (All_Finite (Wide, 4), "wide buffer 1..4 finite");
      Check (Approx (Wide (5).X, 0.0, 1.0e-6), "wide extra zero X");
      Check (Approx (Wide (10).Y, 0.0, 1.0e-6), "wide last zero Y");
   end;

   -------------------------------------------------------------------------
   Section ("29. Ideal length scaling on K3");
   -------------------------------------------------------------------------
   Make_Complete (G, Nat (3));
   Compute (G, Iters (220), Fl (1.0), Fl (1.0), Linear, Fl (0.95), 4, Pos);
   Compute (G, Iters (220), Fl (2.0), Fl (2.0), Linear, Fl (0.95), 4, Pos2);
   D0 := Mean_Edge_Length (G, Pos);
   D1 := Mean_Edge_Length (G, Pos2);
   Check (All_Finite (Pos, 3), "K3 k=1 finite");
   Check (All_Finite (Pos2, 3), "K3 k=2 finite");
   Check (D1 > D0, "K3 larger k => larger mean edge");
   Check (Approx (D0, 1.0, 0.5), "K3 k=1 mean order");
   Check (Approx (D1, 2.0, 1.0), "K3 k=2 mean order");

   -------------------------------------------------------------------------
   -- Summary
   -------------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
