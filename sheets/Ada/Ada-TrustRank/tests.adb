--  Standalone test suite for TrustRank (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with TrustRank; use TrustRank;

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

   function Mark_Raises
     (G : in out Graph; V : Vertex_Id) return Boolean
   is
   begin
      Mark_Seed (G, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Mark_Raises;

   function Is_Seed_Raises (G : Graph; V : Vertex_Id) return Boolean is
      B : Boolean;
   begin
      B := Is_Seed (G, V);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Is_Seed_Raises;

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

   function Dist_Raises
     (G : in out Graph; Mass_Last : Positive; Negate : Boolean)
      return Boolean
   is
      Mass : Seed_Mass_Array (1 .. Vertex_Id (Mass_Last));
   begin
      for V in Mass'Range loop
         Mass (V) := 0.0;
      end loop;
      if Negate then
         Mass (Mass'First) := -1.0;
      else
         Mass (Mass'First) := 1.0;
      end if;
      Set_Seed_Distribution (G, Mass);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

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
   Mass   : Seed_Mass_Array (Vertex_Id);
   N      : Natural;

begin
   -------------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "Clear(0) => V=0");
   Check (Edge_Count (G) = 0, "Clear(0) => E=0");
   Check (Seed_Count (G) = 0, "Clear(0) => seeds=0");

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
   Section ("2. Seed helpers");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Check (Seed_Count (G) = 0, "no seeds initially");
   Check (not Has_Custom_Seeds (G), "not custom initially");
   Check (Mark_Raises (G, 5), "Mark_Seed out of range");
   Check (Is_Seed_Raises (G, 5), "Is_Seed out of range");
   Mark_Seed (G, 1);
   Mark_Seed (G, 3);
   Check (Seed_Count (G) = 2, "two seeds");
   Check (Is_Seed (G, 1), "1 is seed");
   Check (Is_Seed (G, 3), "3 is seed");
   Check (not Is_Seed (G, 2), "2 not seed");
   Mark_Seed (G, 1);  -- idempotent
   Check (Seed_Count (G) = 2, "idempotent Mark_Seed");
   Clear_Seeds (G);
   Check (Seed_Count (G) = 0, "Clear_Seeds");
   Check (not Is_Seed (G, 1), "after Clear_Seeds");

   for V in Vertex_Id range 1 .. 4 loop
      Mass (V) := 0.0;
   end loop;
   Mass (2) := 2.0;
   Mass (4) := 6.0;
   Set_Seed_Distribution (G, Mass);
   Check (Has_Custom_Seeds (G), "Has_Custom_Seeds");
   Check (Seed_Count (G) = 2, "custom positive support size");
   Check (Is_Seed (G, 2), "custom seed 2");
   Check (Is_Seed (G, 4), "custom seed 4");
   Check (not Is_Seed (G, 1), "custom non-seed 1");

   Mark_Seed (G, 1);  -- switches back to mark mode
   Check (not Has_Custom_Seeds (G), "Mark_Seed clears custom mode");
   Check (Is_Seed (G, 1), "mark after custom");
   Check (Seed_Count (G) = 1, "only new mark remains");

   Clear (G, Nat (3));
   Check (Dist_Raises (G, 2, False), "Set_Seed_Distribution short array");
   Check (Dist_Raises (G, 3, True), "negative seed mass");
   --  zero total
   for V in Vertex_Id range 1 .. 3 loop
      Mass (V) := 0.0;
   end loop;
   declare
      Raised : Boolean := False;
   begin
      begin
         Set_Seed_Distribution (G, Mass (1 .. 3));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "zero total seed mass");
   end;

   Clear (G, Nat (0));
   Check (Mark_Raises (G, 1), "Mark_Seed on empty");

   -------------------------------------------------------------------------
   Section ("3. Invalid_Argument on Compute");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Compute_Raises (G, Fl (0.85), Fl (1.0e-6), 1),
          "Compute on empty graph");

   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Check (Compute_Raises (G, Fl (0.85), Fl (1.0e-6), 3),
          "Compute with no seeds");
   Mark_Seed (G, 1);
   Check (Compute_Raises (G, Fl (-0.1), Fl (1.0e-6), 3),
          "damping < 0");
   Check (Compute_Raises (G, Fl (1.1), Fl (1.0e-6), 3),
          "damping > 1");
   Check (Compute_Raises (G, Fl (0.85), Fl (-1.0), 3),
          "tolerance < 0");
   Check (Compute_Raises (G, Fl (0.85), Fl (1.0e-6), 2),
          "Scores array too short");

   -------------------------------------------------------------------------
   Section ("4. Damping alpha=0 recovers seed");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Mark_Seed (G, 1);
   Mark_Seed (G, 2);
   Compute (G, Fl (0.0), 20, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 0.5), "alpha=0 seed1 = 1/2");
   Check (Approx (Scores (2), 0.5), "alpha=0 seed2 = 1/2");
   Check (Approx (Scores (3), 0.0), "alpha=0 nonseed3 = 0");
   Check (Approx (Scores (4), 0.0), "alpha=0 nonseed4 = 0");
   Check (Iters >= 1, "alpha=0 ran >=1 iter");
   Check (Approx (Sum_Scores (Scores, 4), 1.0), "alpha=0 sum=1");

   -------------------------------------------------------------------------
   Section ("5. Chain: trust concentrates near seed");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) > Scores (2), "chain seed1: r1 > r2");
   Check (Scores (2) > Scores (3), "chain seed1: r2 > r3");
   Check (Scores (3) > Scores (4), "chain seed1: r3 > r4");
   Check (Scores (4) > 0.0, "chain seed1: r4 > 0");
   Check (All_Nonneg (Scores, 4), "chain seed1 nonneg");
   Check (Approx (Sum_Scores (Scores, 4), 1.0, 1.0e-3), "chain seed1 sum~1");
   Check (Iters <= 200, "chain converged within budget");

   Clear_Seeds (G);
   Mark_Seed (G, 4);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (4) > Scores (1), "chain seed4: r4 > r1");
   Check (Scores (4) > Scores (2), "chain seed4: r4 > r2");
   Check (Scores (4) > Scores (3), "chain seed4: r4 > r3");
   --  Upstream nodes only get teleport mass via dangling? Actually on a
   --  one-way chain seeded at 4, node 4 is dangling (no out), so all mass
   --  teleports to 4; nodes 1..3 get zero from links. With alpha<1 they
   --  still get 0 from s. So r1=r2=r3=0, r4=1.
   Check (Approx (Scores (4), 1.0, 1.0e-3), "chain seed4: almost all at 4");
   Check (Approx (Scores (1), 0.0, 1.0e-3), "chain seed4: r1~0");

   -------------------------------------------------------------------------
   Section ("6. Custom seed distribution");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   for V in Vertex_Id range 1 .. 3 loop
      Mass (V) := 0.0;
   end loop;
   Mass (1) := 1.0;
   Mass (3) := 3.0;
   Set_Seed_Distribution (G, Mass (1 .. 3));
   Compute (G, Fl (0.0), 10, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 0.25), "custom alpha0: 1/(1+3)");
   Check (Approx (Scores (3), 0.75), "custom alpha0: 3/(1+3)");
   Check (Approx (Scores (2), 0.0), "custom alpha0: middle 0");

   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (3) > Scores (1), "custom: heavier seed 3 > 1");
   Check (All_Nonneg (Scores, 3), "custom nonneg");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "custom sum~1");

   -------------------------------------------------------------------------
   Section ("7. Damping extremes and monotonic spread");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   for I in 1 .. 4 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Mark_Seed (G, 1);

   declare
      S_Low  : Score_Array (1 .. 5);
      S_High : Score_Array (1 .. 5);
      It     : Natural;
   begin
      Compute (G, Fl (0.2), 200, Fl (1.0e-8), S_Low, It);
      Compute (G, Fl (0.9), 200, Fl (1.0e-8), S_High, It);
      Check (S_Low (1) > S_High (1),
             "low alpha keeps more mass at seed than high alpha");
      Check (S_High (5) > S_Low (5),
             "high alpha pushes more mass to far node");
      Check (Approx (Sum_Scores (S_Low, 5), 1.0, 1.0e-3), "low sum~1");
      Check (Approx (Sum_Scores (S_High, 5), 1.0, 1.0e-3), "high sum~1");
   end;

   --  alpha = 1 still defined (no teleport); dangling uses s
   Compute (G, Fl (1.0), 200, Fl (1.0e-8), Scores, Iters);
   Check (All_Nonneg (Scores, 5), "alpha=1 nonneg");
   Check (Approx (Sum_Scores (Scores, 5), 1.0, 1.0e-2), "alpha=1 sum~1");

   -------------------------------------------------------------------------
   Section ("8. Small hand graphs");
   -------------------------------------------------------------------------
   --  Two hubs: seeds at 1, links 1->2, 1->3, 2->4, 3->4
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) > Scores (4), "diamond: seed > sink");
   Check (Approx (Scores (2), Scores (3), 1.0e-4), "diamond: symmetric 2~3");
   Check (Scores (2) > 0.0 and then Scores (4) > 0.0, "diamond positive");

   --  Cycle of 3, one seed
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) >= Scores (2), "cycle: seed >= next");
   Check (Scores (1) >= Scores (3), "cycle: seed >= prev");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "cycle sum~1");

   --  Disconnected: seed component vs other
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) + Scores (2) > Scores (3) + Scores (4),
          "disconnected: mass stays in seed component");
   Check (Scores (3) = 0.0 and then Scores (4) = 0.0,
          "disconnected: other component zero (no teleport there)");

   --  Complete bidirected K3
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3); Add_Edge (G, 3, 2);
   Add_Edge (G, 1, 3); Add_Edge (G, 3, 1);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   Check (Scores (1) > Scores (2), "K3: seed > peer");
   Check (Approx (Scores (2), Scores (3), 1.0e-4), "K3: peers equal");

   -------------------------------------------------------------------------
   Section ("9. Score_Of accessor");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.5), 50, Fl (1.0e-6), Scores, Iters);
   Check (Approx (Score_Of (Scores, 1), Scores (1)), "Score_Of matches");
   Check (Score_Of_Raises (Scores (1 .. 2), 3), "Score_Of out of range");

   -------------------------------------------------------------------------
   Section ("10. Single vertex / dangling");
   -------------------------------------------------------------------------
   Clear (G, Nat (1));
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 20, Fl (1.0e-9), Scores, Iters);
   Check (Approx (Scores (1), 1.0), "single vertex score=1");

   Clear (G, Nat (2));
   --  no edges; both dangling; seed at 1
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 50, Fl (1.0e-8), Scores, Iters);
   Check (Approx (Scores (1), 1.0, 1.0e-3), "all dangling: mass at seed");
   Check (Approx (Scores (2), 0.0, 1.0e-3), "all dangling: other 0");

   -------------------------------------------------------------------------
   Section ("11. Volume: paths of various lengths");
   -------------------------------------------------------------------------
   for Len in 2 .. 20 loop
      Clear (G, Nat (Len));
      for I in 1 .. Len - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Mark_Seed (G, 1);
      Compute (G, Fl (0.85), 300, Fl (1.0e-7), Scores, Iters);
      Check (Scores (1) >= Scores (Vertex_Id (Len)),
             "path len" & Integer'Image (Len) & " seed>=far");
      Check (Approx (Sum_Scores (Scores, Len), 1.0, 5.0e-3),
             "path len" & Integer'Image (Len) & " sum~1");
      Check (All_Nonneg (Scores, Len),
             "path len" & Integer'Image (Len) & " nonneg");
   end loop;

   -------------------------------------------------------------------------
   Section ("12. Volume: star graphs");
   -------------------------------------------------------------------------
   for Arms in 2 .. 15 loop
      N := Arms + 1;
      Clear (G, Nat (N));
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
      Mark_Seed (G, 1);
      Compute (G, Fl (0.85), 200, Fl (1.0e-7), Scores, Iters);
      Check (Scores (1) > Scores (2),
             "star arms" & Integer'Image (Arms) & " center>leaf");
      Check (Approx (Scores (2), Scores (Vertex_Id (N)), 1.0e-4),
             "star arms" & Integer'Image (Arms) & " leaves equal");
      Check (Approx (Sum_Scores (Scores, N), 1.0, 5.0e-3),
             "star arms" & Integer'Image (Arms) & " sum~1");
   end loop;

   -------------------------------------------------------------------------
   Section ("13. Volume: multi-seed vs single");
   -------------------------------------------------------------------------
   Clear (G, Nat (6));
   for I in 1 .. 5 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, Iters);
   declare
      Single_Far : constant Float := Scores (6);
      Multi_Far  : Float;
      It         : Natural;
   begin
      Clear_Seeds (G);
      Mark_Seed (G, 1);
      Mark_Seed (G, 6);
      Compute (G, Fl (0.85), 200, Fl (1.0e-8), Scores, It);
      Multi_Far := Scores (6);
      Check (Multi_Far > Single_Far,
             "seeding far end raises its score");
      Check (Approx (Sum_Scores (Scores, 6), 1.0, 1.0e-3),
             "multi-seed sum~1");
   end;

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
      Mark_Seed (G, 1);
      if Trial mod 2 = 0 then
         Mark_Seed (G, Vertex_Id (N));
      end if;
      Compute (G, Fl (0.85), 250, Fl (1.0e-7), Scores, Iters);
      Check (All_Nonneg (Scores, N),
             "rand" & Integer'Image (Trial) & " nonneg");
      Check (Approx (Sum_Scores (Scores, N), 1.0, 5.0e-3),
             "rand" & Integer'Image (Trial) & " sum~1");
      Check (Scores (1) > 0.0,
             "rand" & Integer'Image (Trial) & " seed positive");
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
   Mark_Seed (G, 2);
   Compute (G, Fl (0.7), 100, Fl (1.0e-7), Scores, Iters);
   declare
      A1 : constant Float := Scores (1);
      A2 : constant Float := Scores (2);
      A3 : constant Float := Scores (3);
      It : Natural;
   begin
      Compute (G, Fl (0.7), 100, Fl (1.0e-7), Scores, It);
      Check (Approx (Scores (1), A1, 1.0e-5), "recompute r1 stable");
      Check (Approx (Scores (2), A2, 1.0e-5), "recompute r2 stable");
      Check (Approx (Scores (3), A3, 1.0e-5), "recompute r3 stable");
   end;

   Clear (G, Nat (4));
   Check (Vertex_Count (G) = 4, "Clear resets V");
   Check (Edge_Count (G) = 0, "Clear resets E");
   Check (Seed_Count (G) = 0, "Clear resets seeds");

   -------------------------------------------------------------------------
   Section ("16. Boundary damping 0 and 1 with custom seeds");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   for V in Vertex_Id range 1 .. 4 loop
      Mass (V) := Float (V);
   end loop;
   Set_Seed_Distribution (G, Mass (1 .. 4));
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
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 100, Fl (1.0e-7), Scores, Iters);
   Check (Edge_Count (G) = 11, "10 parallel + 1");
   Check (Scores (1) > Scores (3), "parallel: seed > far");
   Check (Approx (Sum_Scores (Scores, 3), 1.0, 1.0e-3), "parallel sum");

   -------------------------------------------------------------------------
   Section ("18. Self-loops only");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Mark_Seed (G, 1);
   Compute (G, Fl (0.85), 100, Fl (1.0e-7), Scores, Iters);
   Check (Scores (1) > Scores (2), "self-loop: seed > other loop");
   Check (Approx (Scores (3), 0.0, 1.0e-3), "self-loop: isolated ~0");

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
