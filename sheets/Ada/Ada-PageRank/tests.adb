--  Standalone test suite for PageRank (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with PageRank; use PageRank;

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

   function Approx (A, B : Float; Tol : Float := 1.0e-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Sum_Scores (Scores : Score_Array; N : Natural) return Float is
      S : Float := 0.0;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         S := S + Scores (V);
      end loop;
      return S;
   end Sum_Scores;

   function All_Nonneg (Scores : Score_Array; N : Natural) return Boolean is
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Scores (V) < 0.0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Nonneg;

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
     (G : in out Graph; From, To : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, From, To);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Compute_Raises
     (G : Graph; Damping, Tolerance : Float;
      Scores_Last : Positive) return Boolean
   is
      Scores : Score_Array (1 .. Vertex_Id (Scores_Last));
      Iters  : Natural;
   begin
      Compute (G, Damping, 50, Tolerance, Scores, Iters);
      pragma Unreferenced (Iters);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

   function Teleport_Raises
     (G : in out Graph; Mass_Last : Positive; Negate : Boolean)
      return Boolean
   is
      Mass : Teleport_Array (1 .. Vertex_Id (Mass_Last));
   begin
      for V in Mass'Range loop
         Mass (V) := 0.0;
      end loop;
      if Negate then
         Mass (Mass'First) := -1.0;
      else
         Mass (Mass'First) := 1.0;
      end if;
      Set_Teleport (G, Mass);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Teleport_Raises;

   function Score_Of_Raises
     (Scores : Score_Array; V : Vertex_Id) return Boolean
   is
      X : Float;
   begin
      X := Score_Of (Scores, V);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Score_Of_Raises;

   G      : Graph;
   Scores : Score_Array (Vertex_Id);
   Iters  : Natural;
   Mass   : Teleport_Array (Vertex_Id);
   N      : Natural;

begin
   -------------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "Clear(0) => V=0");
   Check (Edge_Count (G) = 0, "Clear(0) => E=0");
   Check (not Has_Custom_Teleport (G), "Clear(0) => uniform teleport");

   Clear (G, Nat (5));
   Check (Vertex_Count (G) = 5, "Clear(5) => V=5");
   Check (Edge_Count (G) = 0, "Clear(5) => E=0");
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 3);
   Check (Edge_Count (G) = 3, "three edges");
   Add_Edge (G, 1, 2);  -- parallel
   Check (Edge_Count (G) = 4, "parallel edge allowed");
   Add_Edge (G, 4, 4);  -- self-loop
   Check (Edge_Count (G) = 5, "self-loop allowed");
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear > Max_Vertices");
   Check (Add_Raises (G, 1, 6), "Add_Edge To out of range");
   Check (Add_Raises (G, 6, 1), "Add_Edge From out of range");

   Clear (G, Nat (0));
   Check (Add_Raises (G, 1, 1), "Add_Edge on empty graph");

   -------------------------------------------------------------------------
   Section ("2. Teleport helpers");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Check (not Has_Custom_Teleport (G), "not custom initially");
   for V in Vertex_Id range 1 .. 4 loop
      Mass (V) := 0.0;
   end loop;
   Mass (2) := 2.0;
   Mass (4) := 6.0;
   Set_Teleport (G, Mass);
   Check (Has_Custom_Teleport (G), "Has_Custom_Teleport");
   Clear_Teleport (G);
   Check (not Has_Custom_Teleport (G), "Clear_Teleport restores uniform");

   Clear (G, Nat (3));
   Check (Teleport_Raises (G, 2, False), "Set_Teleport short array");
   Check (Teleport_Raises (G, 3, True), "negative teleport mass");
   for V in Vertex_Id range 1 .. 3 loop
      Mass (V) := 0.0;
   end loop;
   declare
      Raised : Boolean := False;
   begin
      begin
         Set_Teleport (G, Mass (1 .. 3));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "zero total teleport mass");
   end;

   Clear (G, Nat (0));
   declare
      Raised : Boolean := False;
      M      : Teleport_Array (1 .. 1);
   begin
      M (1) := 1.0;
      begin
         Set_Teleport (G, M);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Set_Teleport on empty graph");
   end;

   -------------------------------------------------------------------------
   Section ("3. Invalid_Argument on Compute");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Compute_Raises (G, Fl (0.85), Fl (1.0e-6), 1),
          "Compute on empty graph");

   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Check (Compute_Raises (G, Fl (-0.1), Fl (1.0e-6), 3),
          "damping < 0");
   Check (Compute_Raises (G, Fl (1.1), Fl (1.0e-6), 3),
          "damping > 1");
   Check (Compute_Raises (G, Fl (0.85), Fl (-1.0), 3),
          "tolerance < 0");
   Check (Compute_Raises (G, Fl (0.85), Fl (1.0e-6), 2),
          "Scores array too short");

   -------------------------------------------------------------------------
   Section ("4. Uniform: damping alpha=0 recovers 1/N");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Compute (G, Fl (0.0), 20, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 0.25), "alpha=0 r1 = 1/4");
   Check (Approx (Scores (2), 0.25), "alpha=0 r2 = 1/4");
   Check (Approx (Scores (3), 0.25), "alpha=0 r3 = 1/4");
   Check (Approx (Scores (4), 0.25), "alpha=0 r4 = 1/4");
   Check (Iters >= 1, "alpha=0 ran >=1 iter");
   Check (Approx (Sum_Scores (Scores, 4), 1.0), "alpha=0 sum=1");

   -------------------------------------------------------------------------
   Section ("5. Classic small graph (Wikipedia-style)");
   -------------------------------------------------------------------------
   --  A=1, B=2, C=3, D=4
   --  B→C, B→A; C→A; D→A, D→B, D→C  (no A outbound → dangling)
   Clear (G, Nat (4));
   Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 4, 1);
   Add_Edge (G, 4, 2);
   Add_Edge (G, 4, 3);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) > Scores (2), "wiki: A > B (most inbound)");
   Check (Scores (1) > Scores (3), "wiki: A > C");
   Check (Scores (1) > Scores (4), "wiki: A > D");
   Check (All_Nonneg (Scores, 4), "wiki nonneg");
   Check (Approx (Sum_Scores (Scores, 4), 1.0, 1.0e-3), "wiki sum~1");
   Check (Iters <= 200, "wiki converged within budget");

   -------------------------------------------------------------------------
   Section ("6. Personalized teleport");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   for V in Vertex_Id range 1 .. 3 loop
      Mass (V) := 0.0;
   end loop;
   Mass (1) := 1.0;
   Mass (3) := 3.0;
   Set_Teleport (G, Mass (1 .. 3));
   Compute (G, Fl (0.0), 10, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 0.25), "personal alpha0: 1/(1+3)");
   Check (Approx (Scores (3), 0.75), "personal alpha0: 3/(1+3)");
   Check (Approx (Scores (2), 0.0), "personal alpha0: middle 0");

   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (3) > Scores (2), "personal: heavier teleport 3 visible");
   Check (All_Nonneg (Scores, 3), "personal nonneg");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "personal sum~1");

   -------------------------------------------------------------------------
   Section ("7. Dangling-node handling");
   -------------------------------------------------------------------------
   --  Single dangling vertex
   Clear (G, Nat (1));
   Compute (G, Fl (0.85), 20, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 1.0), "single dangling score=1");

   --  Two isolated (all dangling); uniform → equal
   Clear (G, Nat (2));
   Compute (G, Fl (0.85), 50, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), 0.5, 1.0e-3), "all dangling: r1~0.5");
   Check (Approx (Scores (2), 0.5, 1.0e-3), "all dangling: r2~0.5");
   Check (Approx (Sum_Scores (Scores, 2), 1.0), "all dangling sum=1");

   --  Chain ending in dangling: mass redistributes via teleport
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   --  3 is dangling
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (All_Nonneg (Scores, 3), "chain+dangling nonneg");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "chain+dangling sum~1");
   Check (Scores (3) > 0.0, "dangling sink gets mass");

   --  Personalized dangling: all mass teleports to node 1
   Clear (G, Nat (3));
   for V in Vertex_Id range 1 .. 3 loop
      Mass (V) := 0.0;
   end loop;
   Mass (1) := 1.0;
   Set_Teleport (G, Mass (1 .. 3));
   Compute (G, Fl (0.85), 100, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), 1.0, 1.0e-3),
          "personal dangling: all mass at teleport support");
   Check (Approx (Scores (2), 0.0, 1.0e-3), "personal dangling: r2~0");
   Check (Approx (Scores (3), 0.0, 1.0e-3), "personal dangling: r3~0");

   -------------------------------------------------------------------------
   Section ("8. Damping extremes");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   for I in 1 .. 4 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   --  close the cycle so no dangling
   Add_Edge (G, 5, 1);

   declare
      S_Low  : Score_Array (1 .. 5);
      S_High : Score_Array (1 .. 5);
      It     : Natural;
   begin
      Compute (G, Fl (0.2), 200, Fl (1.0e-8), S_Low, It);
      Compute (G, Fl (0.9), 200, Fl (1.0e-8), S_High, It);
      Check (Approx (Sum_Scores (S_Low, 5), 1.0, 1.0e-3), "low sum~1");
      Check (Approx (Sum_Scores (S_High, 5), 1.0, 1.0e-3), "high sum~1");
      Check (All_Nonneg (S_Low, 5), "low nonneg");
      Check (All_Nonneg (S_High, 5), "high nonneg");
   end;

   Compute (G, Fl (1.0), 300, Fl (1.0e-8), Scores, Iters);
   Check (All_Nonneg (Scores, 5), "alpha=1 nonneg");
   Check (Approx (Sum_Scores (Scores, 5), 1.0, 1.0e-2), "alpha=1 sum~1");
   --  On a directed 5-cycle with alpha=1, stationary is uniform
   Check (Approx (Scores (1), 0.2, 1.0e-2), "alpha=1 cycle r1~1/5");
   Check (Approx (Scores (3), 0.2, 1.0e-2), "alpha=1 cycle r3~1/5");

   -------------------------------------------------------------------------
   Section ("9. Small hand graphs");
   -------------------------------------------------------------------------
   --  Star: center → leaves; center has all out, leaves dangling
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (2), Scores (3), 1.0e-4), "star: leaves 2~3");
   Check (Approx (Scores (3), Scores (4), 1.0e-4), "star: leaves 3~4");
   Check (Approx (Sum_Scores (Scores, 4), 1.0, 1.0e-3), "star sum~1");
   Check (All_Nonneg (Scores, 4), "star nonneg");

   --  Bidirected K3: should be nearly uniform
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3); Add_Edge (G, 3, 2);
   Add_Edge (G, 1, 3); Add_Edge (G, 3, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), Scores (2), 1.0e-3), "K3: 1~2");
   Check (Approx (Scores (2), Scores (3), 1.0e-3), "K3: 2~3");
   Check (Approx (Scores (1), 1.0 / 3.0, 1.0e-2), "K3: ~1/3");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "K3 sum~1");

   --  Cycle of 3
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), Scores (2), 1.0e-3), "cycle: uniform 1~2");
   Check (Approx (Scores (2), Scores (3), 1.0e-3), "cycle: uniform 2~3");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "cycle sum~1");

   --  Hub with many inbound
   Clear (G, Nat (5));
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 4, 1);
   Add_Edge (G, 5, 1);
   --  give sources self-loops so they are not dangling sinks only
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 3);
   Add_Edge (G, 4, 4);
   Add_Edge (G, 5, 5);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) > Scores (2), "hub: sink > source");
   Check (Approx (Scores (2), Scores (3), 1.0e-4), "hub: sources equal");
   Check (Approx (Sum_Scores (Scores, 5), 1.0, 1.0e-3), "hub sum~1");

   -------------------------------------------------------------------------
   Section ("10. Score_Of accessor");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Compute (G, Fl (0.5), 50, Fl (1.0e-6), Scores, Iters);
   Check (Approx (Score_Of (Scores, 1), Scores (1)), "Score_Of matches");
   Check (Score_Of_Raises (Scores (1 .. 2), 3), "Score_Of out of range");

   -------------------------------------------------------------------------
   Section ("11. Volume: paths of various lengths");
   -------------------------------------------------------------------------
   for Len in 2 .. 20 loop
      Clear (G, Nat (Len));
      for I in 1 .. Len - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      --  close cycle to avoid pure dangling sink bias dominating
      Add_Edge (G, Vertex_Id (Len), 1);
      Compute (G, Fl (0.85), 300, Fl (1.0e-7), Scores, Iters);
      Check (Approx (Sum_Scores (Scores, Len), 1.0, 5.0e-3),
             "path len" & Integer'Image (Len) & " sum~1");
      Check (All_Nonneg (Scores, Len),
             "path len" & Integer'Image (Len) & " nonneg");
      Check (Iters >= 1,
             "path len" & Integer'Image (Len) & " iters>=1");
   end loop;

   -------------------------------------------------------------------------
   Section ("12. Volume: star graphs");
   -------------------------------------------------------------------------
   for Arms in 2 .. 15 loop
      N := Arms + 1;
      Clear (G, Nat (N));
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
         --  leaf self-loop so not all dangling
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I));
      end loop;
      Compute (G, Fl (0.85), 200, Fl (1.0e-7), Scores, Iters);
      Check (Approx (Scores (2), Scores (Vertex_Id (N)), 1.0e-4),
             "star arms" & Integer'Image (Arms) & " leaves equal");
      Check (Approx (Sum_Scores (Scores, N), 1.0, 5.0e-3),
             "star arms" & Integer'Image (Arms) & " sum~1");
      Check (All_Nonneg (Scores, N),
             "star arms" & Integer'Image (Arms) & " nonneg");
   end loop;

   -------------------------------------------------------------------------
   Section ("13. Volume: complete digraphs Kn");
   -------------------------------------------------------------------------
   for Size in 2 .. 8 loop
      Clear (G, Nat (Size));
      for I in 1 .. Size loop
         for J in 1 .. Size loop
            if I /= J then
               Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
            end if;
         end loop;
      end loop;
      Compute (G, Fl (0.85), 200, Fl (1.0e-7), Scores, Iters);
      Check (Approx (Scores (1), 1.0 / Float (Size), 1.0e-2),
             "Kn" & Integer'Image (Size) & " ~uniform");
      Check (Approx (Sum_Scores (Scores, Size), 1.0, 1.0e-3),
             "Kn" & Integer'Image (Size) & " sum~1");
      Check (All_Nonneg (Scores, Size),
             "Kn" & Integer'Image (Size) & " nonneg");
   end loop;

   -------------------------------------------------------------------------
   Section ("14. Random-ish digraphs (deterministic)");
   -------------------------------------------------------------------------
   for Trial in 1 .. 12 loop
      N := 8 + (Trial mod 5);
      Clear (G, Nat (N));
      for I in 1 .. N loop
         declare
            From : constant Vertex_Id := Vertex_Id (I);
            To1  : constant Vertex_Id :=
              Vertex_Id (1 + (I * 3 + Trial) mod N);
            To2  : constant Vertex_Id :=
              Vertex_Id (1 + (I * 5 + Trial * 2) mod N);
         begin
            Add_Edge (G, From, To1);
            if To2 /= To1 then
               Add_Edge (G, From, To2);
            end if;
         end;
      end loop;
      Compute (G, Fl (0.85), 250, Fl (1.0e-7), Scores, Iters);
      Check (All_Nonneg (Scores, N),
             "rand" & Integer'Image (Trial) & " nonneg");
      Check (Approx (Sum_Scores (Scores, N), 1.0, 5.0e-3),
             "rand" & Integer'Image (Trial) & " sum~1");
      Check (Scores (1) > 0.0,
             "rand" & Integer'Image (Trial) & " positive");
      Check (Iters >= 1,
             "rand" & Integer'Image (Trial) & " iters>=1");
   end loop;

   -------------------------------------------------------------------------
   Section ("15. Idempotent Clear and recompute");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   Compute (G, Fl (0.7), 100, Fl (1.0e-7), Scores, Iters);
   declare
      A1 : constant Float := Scores (1);
      A2 : constant Float := Scores (2);
      A3 : constant Float := Scores (3);
      A4 : constant Float := Scores (4);
      It : Natural;
   begin
      Compute (G, Fl (0.7), 100, Fl (1.0e-7), Scores, It);
      Check (Approx (Scores (1), A1, 1.0e-5), "recompute r1 stable");
      Check (Approx (Scores (2), A2, 1.0e-5), "recompute r2 stable");
      Check (Approx (Scores (3), A3, 1.0e-5), "recompute r3 stable");
      Check (Approx (Scores (4), A4, 1.0e-5), "recompute r4 stable");
   end;

   Clear (G, Nat (4));
   Check (Vertex_Count (G) = 4, "Clear resets V");
   Check (Edge_Count (G) = 0, "Clear resets E");
   Check (not Has_Custom_Teleport (G), "Clear resets teleport");

   -------------------------------------------------------------------------
   Section ("16. Boundary damping with custom teleport");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   for V in Vertex_Id range 1 .. 4 loop
      Mass (V) := Float (V);
   end loop;
   Set_Teleport (G, Mass (1 .. 4));
   Compute (G, Fl (0.0), 5, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 1.0 / 10.0), "custom a0 w1");
   Check (Approx (Scores (2), 2.0 / 10.0), "custom a0 w2");
   Check (Approx (Scores (3), 3.0 / 10.0), "custom a0 w3");
   Check (Approx (Scores (4), 4.0 / 10.0), "custom a0 w4");

   Compute (G, Fl (1.0), 300, Fl (1.0e-8), Scores, Iters);
   Check (All_Nonneg (Scores, 4), "custom a1 nonneg");
   Check (Approx (Sum_Scores (Scores, 4), 1.0, 1.0e-2), "custom a1 sum");

   -------------------------------------------------------------------------
   Section ("17. Many parallel edges");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   declare
      K : Natural := 0;
   begin
      while K < Nat (10) loop
         Add_Edge (G, 1, 2);
         K := K + 1;
      end loop;
   end;
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Compute (G, Fl (0.85), 100, Fl (1.0e-7), Scores, Iters);
   Check (Edge_Count (G) = 12, "10 parallel + 2");
   Check (All_Nonneg (Scores, 3), "parallel nonneg");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "parallel sum");

   -------------------------------------------------------------------------
   Section ("18. Self-loops only");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   --  3 is dangling
   Compute (G, Fl (0.85), 100, Fl (1.0e-7), Scores, Iters);
   Check (Approx (Scores (1), Scores (2), 1.0e-3), "self-loop: 1~2");
   Check (Scores (3) > 0.0, "self-loop: dangling gets teleport");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "self-loop sum");

   -------------------------------------------------------------------------
   Section ("19. Disconnected components");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 3);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), Scores (2), 1.0e-3), "disc: pair1 equal");
   Check (Approx (Scores (3), Scores (4), 1.0e-3), "disc: pair2 equal");
   Check (Approx (Scores (1), Scores (3), 1.0e-3), "disc: comps equal");
   Check (Approx (Sum_Scores (Scores, 4), 1.0, 1.0e-3), "disc sum~1");

   -------------------------------------------------------------------------
   Section ("20. Personalized vs uniform contrast");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   declare
      Uni : Score_Array (1 .. 4);
      Pers : Score_Array (1 .. 4);
      It   : Natural;
   begin
      Compute (G, Fl (0.85), 200, Fl (1.0e-8), Uni, It);
      for V in Vertex_Id range 1 .. 4 loop
         Mass (V) := 0.0;
      end loop;
      Mass (1) := 1.0;
      Set_Teleport (G, Mass (1 .. 4));
      Compute (G, Fl (0.85), 200, Fl (1.0e-8), Pers, It);
      Check (Pers (1) > Uni (1), "personal raises teleport support");
      Check (Approx (Sum_Scores (Pers, 4), 1.0, 1.0e-3), "personal contrast sum");
   end;

   -------------------------------------------------------------------------
   Section ("21. Tolerance and iteration count");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   for I in 1 .. 5 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (1 + I mod 5));
   end loop;
   declare
      It_Loose : Natural;
      It_Tight : Natural;
      S1, S2   : Score_Array (1 .. 5);
   begin
      Compute (G, Fl (0.85), 500, Fl (1.0e-3), S1, It_Loose);
      Compute (G, Fl (0.85), 500, Fl (1.0e-8), S2, It_Tight);
      Check (It_Loose >= 1, "loose tol ran");
      Check (It_Tight >= It_Loose, "tight tol needs >= loose iters");
      Check (Approx (Sum_Scores (S1, 5), 1.0, 1.0e-2), "loose sum");
      Check (Approx (Sum_Scores (S2, 5), 1.0, 1.0e-3), "tight sum");
   end;

   -------------------------------------------------------------------------
   Section ("22. Max_Iters cap");
   -------------------------------------------------------------------------
   --  Asymmetric digraph so the first few iterates are not already
   --  stationary; a tight tolerance forces the Max_Iters ceiling.
   Clear (G, Nat (6));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 1);
   Compute (G, Fl (0.85), 3, Fl (1.0e-20), Scores, Iters);
   Check (Iters = 3, "Max_Iters=3 respected");
   Check (All_Nonneg (Scores, 6), "capped nonneg");
   Check (Approx (Sum_Scores (Scores, 6), 1.0, 5.0e-2), "capped sum~1");

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
