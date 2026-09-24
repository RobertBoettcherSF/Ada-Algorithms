--  Standalone test suite for Hyperlink_Induced_Topic_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;
with Hyperlink_Induced_Topic_Search; use Hyperlink_Induced_Topic_Search;

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

   function L2_Norm (Scores : Score_Array; N : Natural) return Float is
      S : Float := 0.0;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         S := S + Scores (V) * Scores (V);
      end loop;
      return Sqrt (S);
   end L2_Norm;

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
     (G : Graph; Tolerance : Float; Auth_Last, Hub_Last : Positive)
      return Boolean
   is
      Auth : Score_Array (1 .. Vertex_Id (Auth_Last));
      Hub  : Score_Array (1 .. Vertex_Id (Hub_Last));
      It   : Natural;
   begin
      Compute (G, 50, Tolerance, Auth, Hub, It);
      pragma Unreferenced (It);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

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

   G     : Graph;
   Auth  : Score_Array (1 .. Vertex_Id (Max_Vertices));
   Hub   : Score_Array (1 .. Vertex_Id (Max_Vertices));
   Iters : Natural;
   N     : Natural;

begin
   -------------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "empty Vertex_Count=0");
   Check (Edge_Count (G) = 0, "empty Edge_Count=0");

   Clear (G, Nat (5));
   Check (Vertex_Count (G) = 5, "Clear N=5");
   Check (Edge_Count (G) = 0, "Clear E=0");
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
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
   Section ("2. Invalid_Argument on Compute");
   -------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Compute_Raises (G, Fl (1.0e-6), 1, 1), "Compute on empty graph");

   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Check (Compute_Raises (G, Fl (-1.0), 3, 3), "tolerance < 0");
   Check (Compute_Raises (G, Fl (1.0e-6), 2, 3), "Authorities array too short");
   Check (Compute_Raises (G, Fl (1.0e-6), 3, 2), "Hubs array too short");

   -------------------------------------------------------------------------
   Section ("3. Classic bipartite hubs -> authorities");
   -------------------------------------------------------------------------
   --  Hubs 1,2,3; authorities 4,5
   --  1->4, 1->5, 2->4, 2->5, 3->4
   Clear (G, Nat (5));
   Add_Edge (G, 1, 4);
   Add_Edge (G, 1, 5);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 4);
   Compute (G, 200, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Auth (4) > Auth (5), "bipartite: auth4 > auth5");
   Check (Hub (1) > Hub (3), "bipartite: hub1 > hub3");
   Check (Hub (2) > Hub (3), "bipartite: hub2 > hub3");
   Check (Approx (Hub (1), Hub (2), 1.0e-3), "bipartite: hub1 ~ hub2");
   Check (Auth (1) < 1.0e-6, "bipartite: hub-side auth~0");
   Check (Auth (2) < 1.0e-6, "bipartite: hub-side auth2~0");
   Check (Auth (3) < 1.0e-6, "bipartite: hub-side auth3~0");
   Check (Hub (4) < 1.0e-6, "bipartite: auth-side hub4~0");
   Check (Hub (5) < 1.0e-6, "bipartite: auth-side hub5~0");
   Check (All_Nonneg (Auth, 5), "bipartite auth nonneg");
   Check (All_Nonneg (Hub, 5), "bipartite hub nonneg");
   Check (Approx (L2_Norm (Auth, 5), 1.0, 1.0e-3), "bipartite auth L2~1");
   Check (Approx (L2_Norm (Hub, 5), 1.0, 1.0e-3), "bipartite hub L2~1");
   Check (Iters >= 1, "bipartite ran >=1");

   -------------------------------------------------------------------------
   Section ("4. Mutual reinforcement");
   -------------------------------------------------------------------------
   --  Two hubs; hub 1 points to strong auth cluster, hub 2 to weak leaf
   Clear (G, Nat (4));
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 4);
   --  also give 3 an extra inbound from a third hub-like node via self structure:
   --  keep simple: after HITS, hub1 should beat hub2
   Compute (G, 200, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Hub (1) > Hub (2), "reinforce: broader hub wins");
   Check (Auth (3) > 0.0, "reinforce: auth3 > 0");
   Check (Auth (4) > 0.0, "reinforce: auth4 > 0");
   Check (Approx (L2_Norm (Auth, 4), 1.0, 1.0e-3), "reinforce auth L2");
   Check (Approx (L2_Norm (Hub, 4), 1.0, 1.0e-3), "reinforce hub L2");

   -------------------------------------------------------------------------
   Section ("5. Single edge");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Compute (G, 50, Fl (1.0e-9), Auth, Hub, Iters);
   Check (Approx (Auth (2), 1.0, 1.0e-4), "single: auth at target=1");
   Check (Approx (Auth (1), 0.0, 1.0e-4), "single: auth at source=0");
   Check (Approx (Hub (1), 1.0, 1.0e-4), "single: hub at source=1");
   Check (Approx (Hub (2), 0.0, 1.0e-4), "single: hub at target=0");
   Check (Approx (L2_Norm (Auth, 2), 1.0, 1.0e-4), "single auth L2");
   Check (Approx (L2_Norm (Hub, 2), 1.0, 1.0e-4), "single hub L2");

   -------------------------------------------------------------------------
   Section ("6. Edgeless graph yields zeros");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Compute (G, 10, Fl (1.0e-9), Auth, Hub, Iters);
   Check (Approx (Auth (1), 0.0), "edgeless a1=0");
   Check (Approx (Auth (2), 0.0), "edgeless a2=0");
   Check (Approx (Auth (3), 0.0), "edgeless a3=0");
   Check (Approx (Hub (1), 0.0), "edgeless h1=0");
   Check (Approx (Hub (2), 0.0), "edgeless h2=0");
   Check (Approx (Hub (3), 0.0), "edgeless h3=0");
   Check (Iters >= 1, "edgeless ran");

   -------------------------------------------------------------------------
   Section ("7. Directed cycle: uniform hubs and authorities");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   Compute (G, 200, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Auth (1), Auth (2), 1.0e-3), "cycle auth 1~2");
   Check (Approx (Auth (2), Auth (3), 1.0e-3), "cycle auth 2~3");
   Check (Approx (Auth (3), Auth (4), 1.0e-3), "cycle auth 3~4");
   Check (Approx (Hub (1), Hub (2), 1.0e-3), "cycle hub 1~2");
   Check (Approx (Hub (2), Hub (3), 1.0e-3), "cycle hub 2~3");
   Check (Approx (Hub (3), Hub (4), 1.0e-3), "cycle hub 3~4");
   Check (Approx (L2_Norm (Auth, 4), 1.0, 1.0e-3), "cycle auth L2");
   Check (Approx (L2_Norm (Hub, 4), 1.0, 1.0e-3), "cycle hub L2");
   Check (Approx (Auth (1), 0.5, 5.0e-2), "cycle auth ~1/2");

   -------------------------------------------------------------------------
   Section ("8. Star: center hub, leaf authorities");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 1, 5);
   Compute (G, 100, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Hub (1), 1.0, 1.0e-3), "star: center is sole hub");
   Check (Approx (Auth (2), Auth (3), 1.0e-4), "star: leaves auth equal 2~3");
   Check (Approx (Auth (3), Auth (4), 1.0e-4), "star: leaves auth equal 3~4");
   Check (Approx (Auth (4), Auth (5), 1.0e-4), "star: leaves auth equal 4~5");
   Check (Auth (1) < 1.0e-6, "star: center auth~0");
   Check (Approx (L2_Norm (Auth, 5), 1.0, 1.0e-3), "star auth L2");
   Check (Approx (L2_Norm (Hub, 5), 1.0, 1.0e-3), "star hub L2");

   -------------------------------------------------------------------------
   Section ("9. Inbound star: leaves are hubs, center authority");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 4, 1);
   Add_Edge (G, 5, 1);
   Compute (G, 100, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Auth (1), 1.0, 1.0e-3), "in-star: center sole authority");
   Check (Approx (Hub (2), Hub (3), 1.0e-4), "in-star: hubs equal 2~3");
   Check (Approx (Hub (3), Hub (4), 1.0e-4), "in-star: hubs equal 3~4");
   Check (Approx (Hub (4), Hub (5), 1.0e-4), "in-star: hubs equal 4~5");
   Check (Hub (1) < 1.0e-6, "in-star: center hub~0");
   Check (Approx (L2_Norm (Auth, 5), 1.0, 1.0e-3), "in-star auth L2");
   Check (Approx (L2_Norm (Hub, 5), 1.0, 1.0e-3), "in-star hub L2");

   -------------------------------------------------------------------------
   Section ("10. Score_Of accessor");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Compute (G, 50, Fl (1.0e-6), Auth, Hub, Iters);
   Check (Approx (Score_Of (Auth, 2), Auth (2)), "Score_Of auth matches");
   Check (Approx (Score_Of (Hub, 1), Hub (1)), "Score_Of hub matches");
   Check (Score_Of_Raises (Auth (1 .. 2), 3), "Score_Of out of range");

   -------------------------------------------------------------------------
   Section ("11. Bidirected K3: near-uniform");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3); Add_Edge (G, 3, 2);
   Add_Edge (G, 1, 3); Add_Edge (G, 3, 1);
   Compute (G, 200, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Auth (1), Auth (2), 1.0e-3), "K3 auth 1~2");
   Check (Approx (Auth (2), Auth (3), 1.0e-3), "K3 auth 2~3");
   Check (Approx (Hub (1), Hub (2), 1.0e-3), "K3 hub 1~2");
   Check (Approx (Hub (2), Hub (3), 1.0e-3), "K3 hub 2~3");
   Check (Approx (L2_Norm (Auth, 3), 1.0, 1.0e-3), "K3 auth L2");
   Check (Approx (L2_Norm (Hub, 3), 1.0, 1.0e-3), "K3 hub L2");

   -------------------------------------------------------------------------
   Section ("12. Parallel edges amplify");
   -------------------------------------------------------------------------
   Clear (G, Nat (3));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 2);
   Compute (G, 100, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Hub (1) > Hub (3), "parallel: multi-edge hub wins");
   Check (Approx (Auth (2), 1.0, 1.0e-3), "parallel: sole authority");
   Check (All_Nonneg (Auth, 3), "parallel auth nonneg");
   Check (All_Nonneg (Hub, 3), "parallel hub nonneg");

   -------------------------------------------------------------------------
   Section ("13. Self-loop only");
   -------------------------------------------------------------------------
   Clear (G, Nat (2));
   Add_Edge (G, 1, 1);
   Compute (G, 50, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Auth (1), 1.0, 1.0e-3), "self-loop auth at 1");
   Check (Approx (Hub (1), 1.0, 1.0e-3), "self-loop hub at 1");
   Check (Approx (Auth (2), 0.0, 1.0e-4), "self-loop isolated auth=0");
   Check (Approx (Hub (2), 0.0, 1.0e-4), "self-loop isolated hub=0");

   -------------------------------------------------------------------------
   Section ("14. Disconnected bipartite components");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Compute (G, 100, Fl (1.0e-8), Auth, Hub, Iters);
   Check (Approx (Auth (2), Auth (4), 1.0e-3), "disc: authorities equal");
   Check (Approx (Hub (1), Hub (3), 1.0e-3), "disc: hubs equal");
   Check (Approx (L2_Norm (Auth, 4), 1.0, 1.0e-3), "disc auth L2");
   Check (Approx (L2_Norm (Hub, 4), 1.0, 1.0e-3), "disc hub L2");

   -------------------------------------------------------------------------
   Section ("15. Max_Iters cap");
   -------------------------------------------------------------------------
   Clear (G, Nat (6));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   Compute (G, 3, Fl (1.0e-20), Auth, Hub, Iters);
   Check (Iters = 3, "Max_Iters=3 respected");
   Check (All_Nonneg (Auth, 6), "capped auth nonneg");
   Check (All_Nonneg (Hub, 6), "capped hub nonneg");

   -------------------------------------------------------------------------
   Section ("16. Tolerance and iteration count");
   -------------------------------------------------------------------------
   Clear (G, Nat (5));
   for I in 1 .. 5 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (1 + I mod 5));
   end loop;
   declare
      It_Loose : Natural;
      It_Tight : Natural;
      A1, A2   : Score_Array (1 .. 5);
      H1, H2   : Score_Array (1 .. 5);
   begin
      Compute (G, 500, Fl (1.0e-3), A1, H1, It_Loose);
      Compute (G, 500, Fl (1.0e-8), A2, H2, It_Tight);
      Check (It_Loose >= 1, "loose tol ran");
      Check (It_Tight >= It_Loose, "tight tol needs >= loose iters");
      Check (Approx (L2_Norm (A1, 5), 1.0, 1.0e-2), "loose auth L2");
      Check (Approx (L2_Norm (A2, 5), 1.0, 1.0e-3), "tight auth L2");
   end;

   -------------------------------------------------------------------------
   Section ("17. Idempotent recompute");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 4);
   Compute (G, 100, Fl (1.0e-7), Auth, Hub, Iters);
   declare
      A1 : constant Float := Auth (1);
      A2 : constant Float := Auth (2);
      H1 : constant Float := Hub (1);
      H3 : constant Float := Hub (3);
      It : Natural;
   begin
      Compute (G, 100, Fl (1.0e-7), Auth, Hub, It);
      Check (Approx (Auth (1), A1, 1.0e-5), "recompute a1 stable");
      Check (Approx (Auth (2), A2, 1.0e-5), "recompute a2 stable");
      Check (Approx (Hub (1), H1, 1.0e-5), "recompute h1 stable");
      Check (Approx (Hub (3), H3, 1.0e-5), "recompute h3 stable");
   end;

   Clear (G, Nat (4));
   Check (Vertex_Count (G) = 4, "Clear resets V");
   Check (Edge_Count (G) = 0, "Clear resets E");

   -------------------------------------------------------------------------
   Section ("18. Volume: paths of various lengths");
   -------------------------------------------------------------------------
   for Len in 2 .. 20 loop
      Clear (G, Nat (Len));
      for I in 1 .. Len - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Compute (G, 300, Fl (1.0e-7), Auth, Hub, Iters);
      Check (All_Nonneg (Auth, Len),
             "path len" & Integer'Image (Len) & " auth nonneg");
      Check (All_Nonneg (Hub, Len),
             "path len" & Integer'Image (Len) & " hub nonneg");
      Check (Approx (L2_Norm (Auth, Len), 1.0, 5.0e-3),
             "path len" & Integer'Image (Len) & " auth L2");
      Check (Approx (L2_Norm (Hub, Len), 1.0, 5.0e-3),
             "path len" & Integer'Image (Len) & " hub L2");
      Check (Iters >= 1,
             "path len" & Integer'Image (Len) & " iters>=1");
   end loop;

   -------------------------------------------------------------------------
   Section ("19. Volume: star graphs (out-hub)");
   -------------------------------------------------------------------------
   for Arms in 2 .. 15 loop
      N := Arms + 1;
      Clear (G, Nat (N));
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
      Compute (G, 200, Fl (1.0e-7), Auth, Hub, Iters);
      Check (Approx (Hub (1), 1.0, 1.0e-3),
             "star arms" & Integer'Image (Arms) & " hub center");
      Check (Approx (Auth (2), Auth (Vertex_Id (N)), 1.0e-4),
             "star arms" & Integer'Image (Arms) & " leaves equal");
      Check (Approx (L2_Norm (Auth, N), 1.0, 5.0e-3),
             "star arms" & Integer'Image (Arms) & " auth L2");
      Check (All_Nonneg (Hub, N),
             "star arms" & Integer'Image (Arms) & " hub nonneg");
   end loop;

   -------------------------------------------------------------------------
   Section ("20. Volume: complete digraphs Kn");
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
      Compute (G, 200, Fl (1.0e-7), Auth, Hub, Iters);
      Check (Approx (Auth (1), Auth (Vertex_Id (Size)), 1.0e-2),
             "Kn" & Integer'Image (Size) & " auth uniform");
      Check (Approx (Hub (1), Hub (Vertex_Id (Size)), 1.0e-2),
             "Kn" & Integer'Image (Size) & " hub uniform");
      Check (Approx (L2_Norm (Auth, Size), 1.0, 1.0e-3),
             "Kn" & Integer'Image (Size) & " auth L2");
      Check (Approx (L2_Norm (Hub, Size), 1.0, 1.0e-3),
             "Kn" & Integer'Image (Size) & " hub L2");
   end loop;

   -------------------------------------------------------------------------
   Section ("21. Random-ish digraphs (deterministic)");
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
      Compute (G, 250, Fl (1.0e-7), Auth, Hub, Iters);
      Check (All_Nonneg (Auth, N),
             "rand" & Integer'Image (Trial) & " auth nonneg");
      Check (All_Nonneg (Hub, N),
             "rand" & Integer'Image (Trial) & " hub nonneg");
      Check (Approx (L2_Norm (Auth, N), 1.0, 5.0e-3),
             "rand" & Integer'Image (Trial) & " auth L2");
      Check (Approx (L2_Norm (Hub, N), 1.0, 5.0e-3),
             "rand" & Integer'Image (Trial) & " hub L2");
      Check (Iters >= 1,
             "rand" & Integer'Image (Trial) & " iters>=1");
   end loop;

   -------------------------------------------------------------------------
   Section ("22. Bipartite volume: varying hub/auth sizes");
   -------------------------------------------------------------------------
   for Hubs_N in 2 .. 8 loop
      for Auths_N in 2 .. 6 loop
         N := Hubs_N + Auths_N;
         Clear (G, Nat (N));
         for H in 1 .. Hubs_N loop
            for A in 1 .. Auths_N loop
               --  denser links from early hubs
               if A <= H or else (H + A) mod 2 = 0 then
                  Add_Edge (G, Vertex_Id (H),
                            Vertex_Id (Hubs_N + A));
               end if;
            end loop;
         end loop;
         if Edge_Count (G) = 0 then
            Add_Edge (G, 1, Vertex_Id (Hubs_N + 1));
         end if;
         Compute (G, 200, Fl (1.0e-7), Auth, Hub, Iters);
         Check (All_Nonneg (Auth, N),
                "bip H" & Integer'Image (Hubs_N)
                & "A" & Integer'Image (Auths_N) & " auth+");
         Check (All_Nonneg (Hub, N),
                "bip H" & Integer'Image (Hubs_N)
                & "A" & Integer'Image (Auths_N) & " hub+");
         Check (Approx (L2_Norm (Auth, N), 1.0, 5.0e-3),
                "bip H" & Integer'Image (Hubs_N)
                & "A" & Integer'Image (Auths_N) & " aL2");
         Check (Approx (L2_Norm (Hub, N), 1.0, 5.0e-3),
                "bip H" & Integer'Image (Hubs_N)
                & "A" & Integer'Image (Auths_N) & " hL2");
      end loop;
   end loop;

   -------------------------------------------------------------------------
   Section ("23. Single vertex with self-loop");
   -------------------------------------------------------------------------
   Clear (G, Nat (1));
   Add_Edge (G, 1, 1);
   Compute (G, 20, Fl (1.0e-9), Auth, Hub, Iters);
   Check (Approx (Auth (1), 1.0, 1.0e-4), "solo self auth=1");
   Check (Approx (Hub (1), 1.0, 1.0e-4), "solo self hub=1");

   Clear (G, Nat (1));
   Compute (G, 5, Fl (1.0e-9), Auth, Hub, Iters);
   Check (Approx (Auth (1), 0.0), "solo isolated auth=0");
   Check (Approx (Hub (1), 0.0), "solo isolated hub=0");

   -------------------------------------------------------------------------
   Section ("24. Chain authority concentrates downstream");
   -------------------------------------------------------------------------
   Clear (G, Nat (4));
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Compute (G, 200, Fl (1.0e-8), Auth, Hub, Iters);
   --  On a path, hub mass is at sources that reach authorities;
   --  authority mass tends toward the sink.
   Check (Auth (4) >= Auth (3), "chain: sink auth >= pred");
   Check (Hub (1) >= Hub (4), "chain: source hub >= sink hub");
   Check (All_Nonneg (Auth, 4), "chain auth nonneg");
   Check (All_Nonneg (Hub, 4), "chain hub nonneg");
   Check (Approx (L2_Norm (Auth, 4), 1.0, 1.0e-3), "chain auth L2");
   Check (Approx (L2_Norm (Hub, 4), 1.0, 1.0e-3), "chain hub L2");

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
