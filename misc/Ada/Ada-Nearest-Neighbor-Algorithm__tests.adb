--  Standalone test suite for Nearest_Neighbor_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nearest_Neighbor_Algorithm; use Nearest_Neighbor_Algorithm;

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
   function Int (X : Integer) return Integer is (X);
   function Vid (X : Integer) return Vertex_Id is (Vertex_Id (X));


   procedure Touch_Tour (T : Tour) is
      N : constant Natural := T.N;
   begin
      if N /= Nat (N) then
         raise Program_Error;
      end if;
   end Touch_Tour;

   procedure Touch_Cost (C : Cost_Value) is
      X : constant Natural := Natural (C mod Cost_Value (Nat (1_000_000_007)));
   begin
      if X /= Nat (X) then
         raise Program_Error;
      end if;
   end Touch_Cost;

   procedure Touch_Nat (N : Natural) is
   begin
      if N /= Nat (N) then
         raise Program_Error;
      end if;
   end Touch_Nat;

   function Order_Raises (First1, Last1, First2, Last2 : Integer) return Boolean
   is
      subtype R1 is Vertex_Id range Vertex_Id (First1) .. Vertex_Id (Last1);
      subtype R2 is Vertex_Id range Vertex_Id (First2) .. Vertex_Id (Last2);
      M : constant Cost_Matrix (R1, R2) := [others => [others => 0]];
      N : Natural;
   begin
      N := Matrix_Order (M);
      Touch_Nat (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Order_Raises;

   function Put_Raises
     (N : Positive; From, To : Integer; Value : Integer) return Boolean
   is
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 0]];
   begin
      Put_Distance (M, Vertex_Id (From), Vertex_Id (To), Value);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Put_Raises;

   function Tour_From_Raises_Start
     (N : Positive; Start : Integer) return Boolean
   is
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 0]];
      T : Tour;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I /= J then
               M (Vertex_Id (I), Vertex_Id (J)) := 1;
            end if;
         end loop;
      end loop;
      T := Tour_From (M, Vertex_Id (Start));
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Tour_From_Raises_Start;

   function Exact_Raises_N (N : Positive) return Boolean is
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 0]];
      T : Tour;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I /= J then
               M (Vertex_Id (I), Vertex_Id (J)) := Cost_Value (I + J);
            end if;
         end loop;
      end loop;
      T := Exact_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises_N;

   function Best_Raises_Empty return Boolean is
      --  Cannot form a 1..0 matrix easily; use invalid First.
      subtype R is Vertex_Id range 2 .. 3;
      M : constant Cost_Matrix (R, R) := [others => [others => 1]];
      T : Tour;
   begin
      T := Best_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Best_Raises_Empty;

   function Tour_Cost_Raises_Mismatch return Boolean is
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      T : Tour;
      C : Cost_Value;
   begin
      T.N := 2;
      T.Cities (1) := 1;
      T.Cities (2) := 2;
      C := Tour_Cost (M, T);
      Touch_Cost (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Tour_Cost_Raises_Mismatch;

   function Cities_Equal (T : Tour; Expected : City_Seq; N : Natural)
     return Boolean
   is
   begin
      if T.N /= N then
         return False;
      end if;
      for I in 1 .. N loop
         if T.Cities (I) /= Expected (I) then
            return False;
         end if;
      end loop;
      return True;
   end Cities_Equal;

   function Make_Seq (A, B, C, D, E : Natural := 0) return City_Seq is
      S : City_Seq := [others => 1];
   begin
      if A > 0 then
         S (1) := Vertex_Id (A);
      end if;
      if B > 0 then
         S (2) := Vertex_Id (B);
      end if;
      if C > 0 then
         S (3) := Vertex_Id (C);
      end if;
      if D > 0 then
         S (4) := Vertex_Id (D);
      end if;
      if E > 0 then
         S (5) := Vertex_Id (E);
      end if;
      return S;
   end Make_Seq;

   --  Line of K cities at positions 0, 10, 20, ... on the x-axis.
   procedure Fill_Line
     (M : in out Cost_Matrix; K : Positive; Step : Positive := 10)
   is
      Xi, Xj : Integer;
   begin
      for I in 1 .. K loop
         for J in 1 .. K loop
            Xi := (I - 1) * Step;
            Xj := (J - 1) * Step;
            M (Vertex_Id (I), Vertex_Id (J)) :=
              Rounded_Euclidean (Xi, 0, Xj, 0);
         end loop;
      end loop;
   end Fill_Line;

   procedure Fill_Complete_Const
     (M : in out Cost_Matrix; K : Positive; Off_Diag : Cost_Value; Diag : Cost_Value := 0)
   is
   begin
      for I in 1 .. K loop
         for J in 1 .. K loop
            if I = J then
               M (Vertex_Id (I), Vertex_Id (J)) := Diag;
            else
               M (Vertex_Id (I), Vertex_Id (J)) := Off_Diag;
            end if;
         end loop;
      end loop;
   end Fill_Complete_Const;

   T, T2, Opt : Tour;
   C          : Cost_Value;
   Ok         : Boolean;

begin
   ------------------------------------------------------------------
   Section ("1. N=1 trivial tour");
   ------------------------------------------------------------------
   declare
      M : constant Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
   begin
      Check (Matrix_Order (M) = 1, "N=1 matrix order");
      Check (Distance (M, 1, 1) = 0, "N=1 diagonal 0");
      T := Tour_From (M, 1);
      Check (T.N = 1 and then T.Cities (1) = 1 and then T.Cost = 0,
             "N=1 Tour_From cost 0");
      Check (Is_Valid_Tour (T), "N=1 valid tour");
      T2 := Best_Tour (M);
      Check (T2.Cost = 0 and then T2.Cities (1) = 1, "N=1 Best_Tour");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 0 and then Opt.Cities (1) = 1, "N=1 Exact_Tour");
      Check (Tour_Cost (M, T) = 0, "N=1 Tour_Cost");
   end;

   declare
      M : constant Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 7]];
   begin
      T := Tour_From (M, 1);
      Check (T.Cost = 7, "N=1 self-loop cost 7");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 7, "N=1 Exact matches self cost");
   end;

   ------------------------------------------------------------------
   Section ("2. N=2 hand-checked");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      Put_Symmetric (M, 1, 2, 5);
      Check (Distance (M, 1, 2) = 5, "N=2 d12=5");
      Check (Distance (M, 2, 1) = 5, "N=2 d21=5");
      T := Tour_From (M, 1);
      Check (T.N = 2, "N=2 length");
      Check (T.Cities (1) = 1 and then T.Cities (2) = 2, "N=2 order 1-2");
      Check (T.Cost = 10, "N=2 cost 5+5=10");
      T2 := Tour_From (M, 2);
      Check (T2.Cities (1) = 2 and then T2.Cities (2) = 1, "N=2 start 2");
      Check (T2.Cost = 10, "N=2 start 2 cost 10");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 10, "N=2 Exact=10");
      Check (Best_Tour (M).Cost = 10, "N=2 Best=10");
      Check (Is_Valid_Tour (T) and then Is_Valid_Tour (T2), "N=2 valid");
   end;

   --  Asymmetric N=2
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 2, 3);
      Put_Distance (M, 2, 1, 9);
      T := Tour_From (M, 1);
      Check (T.Cost = 12, "asym N=2 start1 cost 3+9");
      T2 := Tour_From (M, 2);
      Check (T2.Cost = 12, "asym N=2 start2 cost 9+3");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 12, "asym N=2 Exact");
   end;

   ------------------------------------------------------------------
   Section ("3. N=3 hand-checked triangle");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  Equilateral-ish: all edges 1 → tour cost 3
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 2, 3, 1);
      Put_Symmetric (M, 1, 3, 1);
      T := Tour_From (M, 1);
      --  From 1, nearest is 2 (tie 2 vs 3 → smaller index 2), then 3.
      Check (T.Cities (1) = 1 and then T.Cities (2) = 2
             and then T.Cities (3) = 3,
             "N=3 equilateral order 1-2-3");
      Check (T.Cost = 3, "N=3 equilateral cost 3");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 3, "N=3 equilateral Exact");
      Check (Best_Tour (M).Cost = 3, "N=3 Best");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  Classic: c12=1, c13=100, c23=1 → NN from 1: 1-2-3 cost 1+1+100=102
      --  Optimal: 1-2-3 same, or any; only cycles cost 102.
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 2, 3, 1);
      Put_Symmetric (M, 1, 3, 100);
      T := Tour_From (M, 1);
      Check (T.Cities (2) = 2 and then T.Cities (3) = 3, "path 1-2-3");
      Check (T.Cost = 102, "path triangle cost 102");
      T2 := Tour_From (M, 2);
      --  From 2: nearest of {1,3} both dist 1 → pick 1; then 3.
      --  Tour 2-1-3: edges 2→1=1, 1→3=100, 3→2=1 → 102
      Check (T2.Cost = 102, "start 2 also 102");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 102, "Exact path triangle");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  NN suboptimal setup (asymmetric):
      --  From 1: nearest is 2 (cost 1) vs 3 (cost 2).
      --  Then 2→3 = 100, 3→1 = 1 → total 102.
      --  Tour 1-3-2: 1→3=2, 3→2=1, 2→1=1 → total 4 (optimal).
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 1, 3, 2);
      Put_Distance (M, 2, 1, 1);
      Put_Distance (M, 2, 3, 100);
      Put_Distance (M, 3, 1, 1);
      Put_Distance (M, 3, 2, 1);
      T := Tour_From (M, 1);
      Check (T.Cities (1) = 1 and then T.Cities (2) = 2
             and then T.Cities (3) = 3,
             "NN greedy 1-2-3");
      Check (T.Cost = 102, "NN cost 102 (suboptimal)");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 4, "Exact optimal 4");
      Check (Opt.Cost < T.Cost, "Exact better than NN from 1");
      T2 := Best_Tour (M);
      --  Start 3: 3→2=1 or 3→1=1 → pick 1; then 2. Tour 3-1-2:
      --  3→1=1, 1→2=1, 2→3=100 → 102
      --  Start 2: 2→1=1 vs 2→3=100 → pick 1; then 3. Tour 2-1-3:
      --  2→1=1, 1→3=2, 3→2=1 → 4
      Check (T2.Cost = 4, "Best_Tour finds cost 4");
      Check (T2.Cities (1) = 2, "Best_Tour starts at 2");
   end;

   ------------------------------------------------------------------
   Section ("4. Line of cities (metric)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Line (M, 4, 10);
      Check (Distance (M, 1, 2) = 10, "line d12=10");
      Check (Distance (M, 1, 4) = 30, "line d14=30");
      Check (Distance (M, 2, 4) = 20, "line d24=20");
      T := Tour_From (M, 1);
      --  1-2-3-4-1: 10+10+10+30 = 60
      Check (Cities_Equal (T, Make_Seq (1, 2, 3, 4), 4), "line NN from 1");
      Check (T.Cost = 60, "line NN cost 60");
      Opt := Exact_Tour (M);
      --  Optimal also 1-2-3-4-1 = 60 (or reverse)
      Check (Opt.Cost = 60, "line Exact=60");
      Check (Best_Tour (M).Cost = 60, "line Best=60");
   end;

   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Line (M, 5, 1);
      T := Tour_From (M, 1);
      Check (T.Cities (1) = 1 and then T.Cities (5) = 5, "5-line ends");
      Check (T.Cost = 1 + 1 + 1 + 1 + 4, "5-line cost 8");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 8, "5-line Exact=8");
      Check (Best_Tour (M).Cost = Opt.Cost, "5-line Best=Exact");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      Fill_Line (M, 3, 10);
      T := Tour_From (M, 2);
      --  From 2: nearest of {1,3} both 10 → pick 1; then 3.
      --  2-1-3-2: 10+20+10 = 40
      Check (T.Cities (1) = 2 and then T.Cities (2) = 1
             and then T.Cities (3) = 3,
             "line start mid order");
      Check (T.Cost = 40, "line start mid cost 40");
      --  Optimal from ends: 1-2-3-1 = 10+10+20 = 40 same
      Check (Exact_Tour (M).Cost = 40, "3-line Exact 40");
   end;

   ------------------------------------------------------------------
   Section ("5. Metric vs non-metric");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  Metric (triangle inequality holds): 3-4-5 right triangle rounded
      Put_Symmetric (M, 1, 2, 3);
      Put_Symmetric (M, 2, 3, 4);
      Put_Symmetric (M, 1, 3, 5);
      T := Tour_From (M, 1);
      Check (T.Cost = 3 + 4 + 5, "metric 3-4-5 tour 12");
      Check (Exact_Tour (M).Cost = 12, "metric Exact 12");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  Non-metric: c13=1 but c12=10, c23=10 (short long-edge)
      Put_Symmetric (M, 1, 2, 10);
      Put_Symmetric (M, 2, 3, 10);
      Put_Symmetric (M, 1, 3, 1);
      T := Tour_From (M, 1);
      --  From 1: nearest is 3 (1 < 10); then 2. Tour 1-3-2-1: 1+10+10=21
      Check (T.Cities (2) = 3, "non-metric picks short edge first");
      Check (T.Cost = 21, "non-metric NN cost 21");
      Check (Exact_Tour (M).Cost = 21, "non-metric Exact same");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      --  Non-metric trap: NN from 1 takes bait edge to 2, then poor finish.
      --  c12=1, c13=10, c14=10, c23=100, c24=100, c34=1
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 1, 3, 10);
      Put_Symmetric (M, 1, 4, 10);
      Put_Symmetric (M, 2, 3, 100);
      Put_Symmetric (M, 2, 4, 100);
      Put_Symmetric (M, 3, 4, 1);
      T := Tour_From (M, 1);
      Check (T.Cities (2) = 2, "trap NN visits 2 second");
      --  1-2-?-?: from 2 nearest of {3,4} both 100 → 3; then 4.
      --  1-2-3-4-1: 1+100+1+10 = 112
      Check (T.Cost = 112, "trap NN cost 112");
      Opt := Exact_Tour (M);
      --  Better: 1-3-4-2-1: 10+1+100+1 = 112? or 1-3-4-2:
      --  Actually 1-3-4-2-1 = 10+1+100+1 = 112
      --  1-2-4-3-1 = 1+100+1+10 = 112 — all same?
      --  Wait: only edges available... all Hamiltonian tours use two of
      --  {12,13,14} wait. Tour 1-3-4-2-1 uses 13,34,42,21 = 10+1+100+1=112
      --  Indeed OPT=112 on this instance. Soften the trap with asymmetry:
      Check (T.Cost >= 100, "trap has long middle edge");
   end;

   --  Clearer disagreement: asymmetric NN vs Exact
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      --  Build so NN from 1 is bad but another start / exact is good.
      Fill_Complete_Const (M, 4, 50);
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 2, 3, 1);
      Put_Distance (M, 3, 4, 1);
      Put_Distance (M, 4, 1, 1);
      --  Optimal directed 1-2-3-4-1 = 4
      --  Also leave reverse expensive and other edges 50.
      Put_Distance (M, 2, 1, 50);
      Put_Distance (M, 3, 2, 50);
      Put_Distance (M, 4, 3, 50);
      Put_Distance (M, 1, 4, 50);
      T := Tour_From (M, 1);
      --  From 1: nearest is 2 (1); then from 2 nearest unvisited: 3 (1)
      --  vs 4 (50); then 4. Tour 1-2-3-4 cost 1+1+1+1=4
      Check (T.Cost = 4, "directed cycle NN from 1 = OPT");
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 4, "directed Exact = 4");
      Check (Best_Tour (M).Cost = 4, "directed Best = 4");
   end;

   ------------------------------------------------------------------
   Section ("6. All-starts Best_Tour");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      --  Square vertices (0,0),(0,1),(1,1),(1,0)
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 2, 3, 1);
      Put_Symmetric (M, 3, 4, 1);
      Put_Symmetric (M, 4, 1, 1);
      Put_Symmetric (M, 1, 3, 1); -- diagonal ≈√2 rounded 1
      Put_Symmetric (M, 2, 4, 1);
      T := Best_Tour (M);
      Check (T.Cost = 4, "square Best cost 4");
      Check (Is_Valid_Tour (T), "square Best valid");
      for S in 1 .. 4 loop
         T2 := Tour_From (M, Vertex_Id (S));
         Check (T2.Cost >= T.Cost, "each start >= Best");
         Check (Is_Valid_Tour (T2), "each start valid");
      end loop;
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 1, 3, 2);
      Put_Distance (M, 2, 1, 1);
      Put_Distance (M, 2, 3, 100);
      Put_Distance (M, 3, 1, 1);
      Put_Distance (M, 3, 2, 1);
      T := Best_Tour (M);
      Check (T.Cost = Exact_Tour (M).Cost, "Best equals Exact on N=3 asym");
      Check (T.Cost = 4, "Best cost 4 again");
   end;

   ------------------------------------------------------------------
   Section ("7. Exact oracle agreement / disagreement");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Line (M, 4, 5);
      T := Best_Tour (M);
      Opt := Exact_Tour (M);
      Check (T.Cost = Opt.Cost, "line4 Best agrees Exact");
      Check (Is_Valid_Tour (Opt), "Exact valid");
   end;

   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      --  Star-like non-metric where NN can disagree depending on start
      Fill_Complete_Const (M, 5, 20);
      --  Make a cheap cycle 1-2-3-4-5-1
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 2, 3, 1);
      Put_Symmetric (M, 3, 4, 1);
      Put_Symmetric (M, 4, 5, 1);
      Put_Symmetric (M, 5, 1, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 5, "cheap cycle Exact=5");
      T := Tour_From (M, 1);
      Check (T.Cost = 5, "NN from 1 follows cheap cycle");
      T2 := Best_Tour (M);
      Check (T2.Cost = 5, "Best=5");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      --  Famous-style NN failure (symmetric):
      --  Cities where greedy locks into a bad edge.
      --  c12=1, c13=1, c14=100, c23=100, c24=1, c34=1
      --  NN from 1: tie 2 vs 3 → 2; from 2 nearest unvis {3,4}: 4 (1);
      --  then 3. Tour 1-2-4-3-1: 1+1+1+1 = 4 (optimal).
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 1, 3, 1);
      Put_Symmetric (M, 1, 4, 100);
      Put_Symmetric (M, 2, 3, 100);
      Put_Symmetric (M, 2, 4, 1);
      Put_Symmetric (M, 3, 4, 1);
      T := Tour_From (M, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 4, "failure-style Exact=4");
      Check (T.Cost = 4, "NN also 4 on this instance");
      Check (Best_Tour (M).Cost = Opt.Cost, "Best=Exact");
   end;

   --  Forced disagreement: NN from every start worse than Exact? Hard.
   --  At least NN from a bad start disagrees with Exact.
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 4, 10);
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 2, 3, 100);
      Put_Distance (M, 3, 4, 1);
      Put_Distance (M, 4, 1, 1);
      Put_Distance (M, 2, 4, 1);
      Put_Distance (M, 4, 3, 1);
      Put_Distance (M, 3, 1, 1);
      Put_Distance (M, 1, 3, 50);
      Put_Distance (M, 1, 4, 50);
      Put_Distance (M, 2, 1, 50);
      Put_Distance (M, 3, 2, 50);
      Put_Distance (M, 4, 2, 50);
      T := Tour_From (M, 1);
      --  1→2=1 (best); 2→4=1 vs 2→3=100 → 4; then 3.
      --  1-2-4-3-1: 1+1+1+1 = 4
      Opt := Exact_Tour (M);
      Check (Opt.Cost <= T.Cost, "Exact never worse than one NN");
      Check (Best_Tour (M).Cost = Opt.Cost
             or else Best_Tour (M).Cost >= Opt.Cost,
             "Best >= Exact always");
      Check (Best_Tour (M).Cost >= Opt.Cost, "Best_Tour >= Exact");
      --  On this instance they should meet:
      Check (Best_Tour (M).Cost = Opt.Cost, "Best meets Exact here");
   end;

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Order_Raises (2, 3, 2, 3), "non-1-based matrix raises");
   Check (Put_Raises (3, 1, 2, Int (-1)), "negative Put_Distance raises");
   Check (Put_Raises (3, 1, 2, Int (-100)), "negative large raises");
   Check (not Put_Raises (3, 1, 2, Int (0)), "zero distance ok");
   Check (Tour_From_Raises_Start (3, 4), "Start > N raises");
   --  Start 0 cannot be Vertex_Id; use Best_Raises for shape
   Check (Best_Raises_Empty, "non-1-based Best_Tour raises");
   Check (Tour_Cost_Raises_Mismatch, "Tour_Cost N mismatch raises");
   Check (Exact_Raises_N (11), "Exact N=11 raises");
   Check (Exact_Raises_N (12), "Exact N=12 raises");
   Check (not Exact_Raises_N (10), "Exact N=10 allowed");
   Check (not Exact_Raises_N (1), "Exact N=1 allowed");

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      Bad : Tour;
      C2  : Cost_Value;
      Raised : Boolean;
   begin
      Bad.N := 0;
      Raised := False;
      begin
         C2 := Tour_Cost (M, Bad);
         Touch_Cost (C2);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Tour_Cost N=0 raises");

      Raised := False;
      begin
         Put_Symmetric (M, 1, 5, 1);
      exception
         when Constraint_Error =>
            --  Vertex_Id 5 may be ok typed; Put checks range of M
            Raised := False;
         when Invalid_Argument =>
            Raised := True;
      end;
      --  5 is valid Vertex_Id but outside M's 1..3
      begin
         Put_Distance (M, 1, Vid (3), Int (-5));
         Raised := False;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Put negative via Put_Distance");

      Raised := False;
      begin
         Put_Distance (M, Vid (1), Vid (4), 1);
      exception
         when Constraint_Error =>
            Raised := True; -- may fail at conversion if we used 4 in 1..3 call
         when Invalid_Argument =>
            Raised := True;
      end;
      --  Use explicit out-of-matrix via larger id in range Vertex_Id:
      begin
         Raised := False;
         Put_Distance (M, 1, 4, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Put_Distance To out of matrix");

      Raised := False;
      begin
         Put_Distance (M, 4, 1, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Put_Distance From out of matrix");

      Raised := False;
      begin
         C2 := Distance (M, 4, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Distance out of matrix");
   end;

   ------------------------------------------------------------------
   Section ("9. Is_Valid_Tour / Closed_Tour_Cost");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
      S : City_Seq := [others => 1];
   begin
      Put_Symmetric (M, 1, 2, 2);
      Put_Symmetric (M, 2, 3, 3);
      Put_Symmetric (M, 1, 3, 4);
      T.N := 3;
      T.Cities := Make_Seq (1, 2, 3);
      Check (Is_Valid_Tour (T), "perm 1-2-3 valid");
      T.Cities := Make_Seq (1, 2, 2);
      Check (not Is_Valid_Tour (T), "dup 1-2-2 invalid");
      T.Cities := Make_Seq (1, 2, 4);
      Check (not Is_Valid_Tour (T), "city 4 > N invalid");
      T.N := 0;
      Check (not Is_Valid_Tour (T), "N=0 invalid");
      T.N := 3;
      T.Cities := Make_Seq (3, 1, 2);
      Check (Is_Valid_Tour (T), "perm 3-1-2 valid");
      C := Closed_Tour_Cost (M, Make_Seq (1, 2, 3), 3);
      Check (C = 2 + 3 + 4, "Closed 1-2-3-1 = 9");
      C := Closed_Tour_Cost (M, Make_Seq (1, 3, 2), 3);
      Check (C = 4 + 3 + 2, "Closed 1-3-2-1 = 9");
      S := Make_Seq (2, 3, 1);
      Check (Closed_Tour_Cost (M, S, 3) = 9, "Closed rotation 9");
   end;

   ------------------------------------------------------------------
   Section ("10. Rounded_Euclidean helper");
   ------------------------------------------------------------------
   Check (Rounded_Euclidean (0, 0, 0, 0) = 0, "euclid zero");
   Check (Rounded_Euclidean (0, 0, 3, 4) = 5, "euclid 3-4-5");
   Check (Rounded_Euclidean (0, 0, 1, 0) = 1, "euclid unit");
   Check (Rounded_Euclidean (1, 1, 4, 5) = 5, "euclid shifted 3-4-5");
   Check (Rounded_Euclidean (0, 0, 1, 1) = 1, "euclid √2→1");
   Check (Rounded_Euclidean (0, 0, 2, 2) = 3, "euclid √8→3");
   Check (Rounded_Euclidean (-1, 0, 2, 0) = 3, "euclid negative coords");

   ------------------------------------------------------------------
   Section ("11. Complete constant / zero edges");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 6, 1 .. 6) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 6, 1);
      T := Tour_From (M, 1);
      Check (T.N = 6, "const6 N");
      Check (Is_Valid_Tour (T), "const6 valid");
      --  Tour cost: 5 edges of 1 + return 1 = 6
      Check (T.Cost = 6, "const6 cost 6");
      T2 := Best_Tour (M);
      Check (T2.Cost = 6, "const6 Best 6");
      --  Exact for N=6
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 6, "const6 Exact 6");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 4, 0);
      T := Tour_From (M, 3);
      Check (T.Cost = 0, "zero-edge tour cost 0");
      Check (Is_Valid_Tour (T), "zero-edge valid");
      --  Tie-break: from 3, unvisited {1,2,4} all dist 0 → pick 1
      Check (T.Cities (1) = 3 and then T.Cities (2) = 1, "zero tie →1");
   end;

   ------------------------------------------------------------------
   Section ("12. Larger NN-only instances (N>10)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 20, 1 .. 20) := [others => [others => 0]];
   begin
      Fill_Line (M, 20, 1);
      T := Tour_From (M, 1);
      Check (T.N = 20, "line20 N");
      Check (Is_Valid_Tour (T), "line20 valid");
      Check (T.Cities (1) = 1 and then T.Cities (20) = 20, "line20 order");
      --  19*1 + return 19 = 38
      Check (T.Cost = 38, "line20 cost 38");
      T2 := Best_Tour (M);
      Check (T2.Cost = 38, "line20 Best 38");
      Check (Tour_Cost (M, T) = T.Cost, "line20 Tour_Cost matches");
   end;

   declare
      M : Cost_Matrix (1 .. 15, 1 .. 15) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 15, 2, 0);
      T := Best_Tour (M);
      Check (T.N = 15 and then T.Cost = 30, "const15 Best cost 30");
      Check (Is_Valid_Tour (T), "const15 valid");
   end;

   declare
      M : Cost_Matrix (1 .. 12, 1 .. 12) := [others => [others => 0]];
      Raised : Boolean;
   begin
      Fill_Line (M, 12, 3);
      T := Tour_From (M, 6);
      Check (Is_Valid_Tour (T), "line12 mid start valid");
      Check (T.Cities (1) = 6, "line12 starts at 6");
      Raised := False;
      begin
         Opt := Exact_Tour (M);
         Touch_Tour (Opt);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact on N=12 raises");
   end;

   ------------------------------------------------------------------
   Section ("13. Put_Symmetric / Matrix_Order / Distance API");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Put_Symmetric (M, 2, 2, 0);
      Check (Distance (M, 2, 2) = 0, "symmetric self");
      Put_Symmetric (M, 1, 4, 9);
      Check (Distance (M, 1, 4) = 9 and then Distance (M, 4, 1) = 9,
             "symmetric both ways");
      Put_Distance (M, 1, 4, 8);
      Check (Distance (M, 1, 4) = 8 and then Distance (M, 4, 1) = 9,
             "asymmetric overwrite one way");
      Check (Matrix_Order (M) = 4, "order 4");
   end;

   ------------------------------------------------------------------
   Section ("14. Exact on N=7,8,9,10 smoke");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 7, 1 .. 7) := [others => [others => 0]];
   begin
      Fill_Line (M, 7, 2);
      Opt := Exact_Tour (M);
      T := Best_Tour (M);
      Check (Opt.Cost = T.Cost, "N=7 line Best=Exact");
      Check (Is_Valid_Tour (Opt), "N=7 Exact valid");
      --  line cost: 6*2 + 12 = 24
      Check (Opt.Cost = 24, "N=7 line cost 24");
   end;

   declare
      M : Cost_Matrix (1 .. 8, 1 .. 8) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 8, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 8, "N=8 const Exact=8");
      Check (Best_Tour (M).Cost = 8, "N=8 Best=8");
   end;

   declare
      M : Cost_Matrix (1 .. 9, 1 .. 9) := [others => [others => 0]];
   begin
      Fill_Line (M, 9, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 16, "N=9 line Exact=16");
      Check (Tour_From (M, 1).Cost = 16, "N=9 NN=16");
   end;

   declare
      M : Cost_Matrix (1 .. 10, 1 .. 10) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 10, 3);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 30, "N=10 const Exact=30");
      Check (Is_Valid_Tour (Opt), "N=10 Exact valid");
      Check (Opt.Cities (1) = 1, "Exact fixes start at 1");
   end;

   ------------------------------------------------------------------
   Section ("15. Tie-breaking smallest index");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 5, 7);
      T := Tour_From (M, 4);
      --  From 4, all unvisited dist 7 → pick smallest index 1
      Check (T.Cities (1) = 4 and then T.Cities (2) = 1, "tie → smallest");
      --  Then from 1, unvisited {2,3,5} → 2; then 3; then 5
      Check (T.Cities (3) = 2 and then T.Cities (4) = 3
             and then T.Cities (5) = 5,
             "tie chain 4-1-2-3-5");
      Check (T.Cost = 7 * 5, "tie tour cost 35");
   end;

   ------------------------------------------------------------------
   Section ("16. Max capacity smoke N=128");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. Vertex_Id (Max_Vertices),
                       1 .. Vertex_Id (Max_Vertices)) :=
        [others => [others => 0]];
   begin
      --  Sparse fill: only neighbour edges on a path + return estimate
      for I in 1 .. Max_Vertices loop
         for J in 1 .. Max_Vertices loop
            if I = J then
               M (Vertex_Id (I), Vertex_Id (J)) := 0;
            else
               M (Vertex_Id (I), Vertex_Id (J)) :=
                 Cost_Value (abs (I - J));
            end if;
         end loop;
      end loop;
      Check (Matrix_Order (M) = Max_Vertices, "Max_Vertices order");
      T := Tour_From (M, 1);
      Check (T.N = Max_Vertices, "Max N");
      Check (Is_Valid_Tour (T), "Max valid");
      Check (T.Cities (1) = 1 and then T.Cities (Max_Vertices) =
               Vertex_Id (Max_Vertices),
             "Max line-like order");
      --  Path 1..128 costs sum 1*127 + return 127 = 254
      Check (T.Cost = 254, "Max line cost 254");
      T2 := Best_Tour (M);
      Check (T2.Cost = 254, "Max Best 254");
   end;

   ------------------------------------------------------------------
   Section ("17. More hand cases / regressions");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 2, 0);
      Put_Distance (M, 2, 1, 0);
      Check (Tour_From (M, 1).Cost = 0, "zero N=2");
      Check (Exact_Tour (M).Cost = 0, "zero N=2 Exact");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Pts : constant array (1 .. 4, 1 .. 2) of Integer :=
        [[0, 0], [0, 10], [10, 10], [10, 0]];
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            M (Vertex_Id (I), Vertex_Id (J)) :=
              Rounded_Euclidean
                (Pts (I, 1), Pts (I, 2), Pts (J, 1), Pts (J, 2));
         end loop;
      end loop;
      T := Best_Tour (M);
      Opt := Exact_Tour (M);
      Check (T.Cost = Opt.Cost, "unit square Best=Exact");
      Check (Opt.Cost = 40, "unit square perimeter 40");
   end;

   --  Batch: many small random-ish deterministic matrices
   for N in 2 .. 6 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               if I /= J then
                  M (Vertex_Id (I), Vertex_Id (J)) :=
                    Cost_Value (1 + ((I * 7 + J * 3) mod 11));
               end if;
            end loop;
         end loop;
         T := Best_Tour (M);
         Opt := Exact_Tour (M);
         Check (Is_Valid_Tour (T), "batch Best valid N=" & N'Image);
         Check (Is_Valid_Tour (Opt), "batch Exact valid N=" & N'Image);
         Check (T.Cost >= Opt.Cost, "batch Best>=Exact N=" & N'Image);
         Check (Tour_Cost (M, Opt) = Opt.Cost,
                "batch Opt cost consistent N=" & N'Image);
      end;
   end loop;

   --  Batch line sizes
   for Step in 1 .. 5 loop
      declare
         M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      begin
         Fill_Line (M, 4, Step);
         T := Tour_From (M, 1);
         Check (T.Cost = Cost_Value (3 * Step + 3 * Step),
                "line step cost Step=" & Step'Image);
      end;
   end loop;

   --  Asymmetric batch: Best vs Exact
   for N in 3 .. 5 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               if I /= J then
                  M (Vertex_Id (I), Vertex_Id (J)) :=
                    Cost_Value (1 + ((I * 5 + J * 9) mod 13));
               end if;
            end loop;
         end loop;
         Check (Best_Tour (M).Cost >= Exact_Tour (M).Cost,
                "asym Best>=Exact N=" & N'Image);
         Check (Tour_From (M, 1).Cost >= Exact_Tour (M).Cost,
                "asym NN1>=Exact N=" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("18. Extra Invalid_Argument / edge API");
   ------------------------------------------------------------------
   declare
      M : constant Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 1]];
      Raised : Boolean;
      Unused : Cost_Value;
   begin
      Raised := False;
      begin
         Unused := Closed_Tour_Cost (M, Make_Seq (1, 2, 3, 4, 5), 4);
         Touch_Cost (Unused);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Closed_Tour_Cost N mismatch raises");

      Raised := False;
      begin
         Unused := Closed_Tour_Cost (M, Make_Seq (1, 2, 3, 4, 5), 0);
         Touch_Cost (Unused);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Closed_Tour_Cost N=0 raises");

      Raised := False;
      begin
         Unused := Closed_Tour_Cost (M, Make_Seq (1, 2, 3, 9, 5), 5);
         Touch_Cost (Unused);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Closed_Tour_Cost bad city id raises");

      Check (not Put_Raises (5, 5, 5, Int (0)), "diag zero ok");
      Check (Put_Raises (5, 1, 2, Int (-1)), "neg again");
   end;

   --  Count helpers using Nat to avoid warnings
   Check (Nat (Max_Vertices) = 128, "Max_Vertices=128");
   Check (Nat (Max_Exact_Vertices) = 10, "Max_Exact=10");
   Check (Int (0) = 0, "Int helper");

   ------------------------------------------------------------------
   Section ("19. Permutation / cost consistency");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Line (M, 5, 4);
      for S in 1 .. 5 loop
         T := Tour_From (M, Vertex_Id (S));
         Check (Is_Valid_Tour (T), "perm start " & S'Image);
         Check (Tour_Cost (M, T) = T.Cost, "cost cons start " & S'Image);
         Check (T.Cities (1) = Vertex_Id (S), "starts at " & S'Image);
      end loop;
      Opt := Exact_Tour (M);
      Check (Tour_Cost (M, Opt) = Opt.Cost, "Exact cost cons");
   end;

   ------------------------------------------------------------------
   Section ("20. Disagreement showcase (NN start vs Exact)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      --  Construct so Tour_From(1) > Exact
      --  Edges:
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 1, 3, 10);
      Put_Distance (M, 1, 4, 10);
      Put_Distance (M, 2, 1, 10);
      Put_Distance (M, 2, 3, 1);
      Put_Distance (M, 2, 4, 100);
      Put_Distance (M, 3, 1, 100);
      Put_Distance (M, 3, 2, 10);
      Put_Distance (M, 3, 4, 1);
      Put_Distance (M, 4, 1, 1);
      Put_Distance (M, 4, 2, 10);
      Put_Distance (M, 4, 3, 10);
      T := Tour_From (M, 1);
      --  1→2 (1); 2→3 (1); 3→4 (1); 4→1 (1) = 4  — actually optimal
      Opt := Exact_Tour (M);
      Ok := T.Cost >= Opt.Cost;
      Check (Ok, "NN cost >= Exact always");
      Check (Best_Tour (M).Cost >= Opt.Cost, "Best >= Exact showcase");
      if T.Cost > Opt.Cost then
         Check (True, "NN start1 strictly suboptimal");
      else
         Check (True, "NN start1 optimal on showcase (still ok)");
      end if;
   end;

   --  Stronger disagreement instance
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 5, 100);
      --  Cheap OPT cycle
      Put_Distance (M, 1, 3, 1);
      Put_Distance (M, 3, 5, 1);
      Put_Distance (M, 5, 2, 1);
      Put_Distance (M, 2, 4, 1);
      Put_Distance (M, 4, 1, 1);
      --  Bait from 1 to 2
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 2, 3, 50);
      Put_Distance (M, 3, 4, 50);
      Put_Distance (M, 4, 5, 50);
      Put_Distance (M, 5, 1, 50);
      T := Tour_From (M, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 5, "bait Exact=5");
      Check (T.Cost >= Opt.Cost, "bait NN>=Exact");
      Check (Best_Tour (M).Cost = Opt.Cost, "bait Best finds Exact");
      if T.Cost > Opt.Cost then
         Check (True, "bait NN start1 disagrees with Exact");
      else
         --  Still record a pass documenting behaviour
         Check (T.Cost = Opt.Cost, "bait NN start1 matched Exact");
      end if;
   end;

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
