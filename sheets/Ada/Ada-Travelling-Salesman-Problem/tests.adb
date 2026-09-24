--  Standalone test suite for Travelling_Salesman_Problem (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Travelling_Salesman_Problem; use Travelling_Salesman_Problem;

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
      Touch_Cost (M (Vertex_Id (From), Vertex_Id (To)));
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Put_Raises;

   function Exact_Raises (N : Positive) return Boolean is
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 1]];
      T : Tour;
   begin
      for I in 1 .. N loop
         M (Vertex_Id (I), Vertex_Id (I)) := 0;
      end loop;
      T := Exact_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   function Brute_Raises (N : Positive) return Boolean is
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 1]];
      T : Tour;
   begin
      for I in 1 .. N loop
         M (Vertex_Id (I), Vertex_Id (I)) := 0;
      end loop;
      T := Brute_Force_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Brute_Raises;

   function DT_Raises (N : Positive) return Boolean is
      M : constant Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 1]];
      T : Tour;
   begin
      T := Double_Tree_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DT_Raises;

   function NN_Start_Raises (N : Positive; Start : Integer) return Boolean is
      M : constant Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 1]];
      T : Tour;
   begin
      T := Nearest_Neighbor_From (M, Vertex_Id (Start));
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end NN_Start_Raises;

   function Two_Opt_Raises_Invalid_Seed return Boolean is
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      Seed : Tour;
      T : Tour;
   begin
      Seed.N := 3;
      Seed.Cities (1) := 1;
      Seed.Cities (2) := 1;  -- duplicate → invalid
      Seed.Cities (3) := 2;
      Seed.Cost := 0;
      T := Improve_Two_Opt (M, Seed);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Two_Opt_Raises_Invalid_Seed;

   procedure Fill_Complete_Const
     (M : in out Cost_Matrix; N : Positive; Val : Integer)
   is
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Put_Distance (M, Vid (I), Vid (J), 0);
            else
               Put_Distance (M, Vid (I), Vid (J), Val);
            end if;
         end loop;
      end loop;
   end Fill_Complete_Const;

   procedure Fill_Path_Metric (M : in out Cost_Matrix; N : Positive) is
      --  Cities on a line 1-2-...-N with unit spacing; c_ij = |i-j|.
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            declare
               D : constant Integer := abs (I - J);
            begin
               Put_Symmetric (M, Vid (I), Vid (J), D);
            end;
         end loop;
      end loop;
   end Fill_Path_Metric;

   procedure Fill_Euclidean_Square (M : in out Cost_Matrix) is
      --  Unit square corners: (0,0),(1,0),(1,1),(0,1) → N=4.
      Xs : constant array (1 .. 4) of Integer := [0, 1, 1, 0];
      Ys : constant array (1 .. 4) of Integer := [0, 0, 1, 1];
      D  : Cost_Value;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            D := Rounded_Euclidean (Xs (I), Ys (I), Xs (J), Ys (J));
            Put_Distance (M, Vid (I), Vid (J), Integer (D));
         end loop;
      end loop;
   end Fill_Euclidean_Square;

   T, Opt, NN, DT, Imp : Tour;
   C  : Cost_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Caps and API constants");
   ------------------------------------------------------------------
   Check (Max_Vertices = Nat (64), "Max_Vertices=64");
   Check (Max_Brute_Force_Vertices = Nat (10), "Max_Brute_Force=10");
   Check (Max_Held_Karp_Vertices = Nat (16), "Max_Held_Karp=16");
   Check (Nat (Max_Held_Karp_Vertices) >= Nat (Max_Brute_Force_Vertices),
          "HK cap >= brute cap");

   ------------------------------------------------------------------
   Section ("2. Matrix builders / queries");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      Check (Matrix_Order (M) = Nat (3), "order 3");
      Put_Distance (M, 1, 2, 5);
      Check (Distance (M, 1, 2) = 5, "Put_Distance 1→2");
      Put_Symmetric (M, 2, 3, 7);
      Check (Distance (M, 2, 3) = 7 and then Distance (M, 3, 2) = 7,
             "Put_Symmetric both ways");
      Put_Symmetric (M, 1, 1, 0);
      Check (Distance (M, 1, 1) = 0, "diagonal via Put_Symmetric");
      Check (Undirected_Weight (M, 1, 2) = 5
             or else Undirected_Weight (M, 1, 2) = Distance (M, 2, 1),
             "Undirected_Weight defined");
      Put_Distance (M, 2, 1, 9);
      Check (Undirected_Weight (M, 1, 2) = 5, "Undirected min(5,9)=5");
   end;

   Check (Put_Raises (3, 1, 2, Int (-1)), "negative Put_Distance raises");
   Check (Order_Raises (1, 3, 1, 2), "non-square raises");
   Check (Order_Raises (2, 4, 2, 4), "non-1-based raises");

   ------------------------------------------------------------------
   Section ("3. Rounded_Euclidean");
   ------------------------------------------------------------------
   Check (Rounded_Euclidean (0, 0, 3, 4) = 5, "3-4-5 triangle");
   Check (Rounded_Euclidean (0, 0, 0, 0) = 0, "zero distance");
   Check (Rounded_Euclidean (0, 0, 1, 0) = 1, "unit axis");
   Check (Rounded_Euclidean (0, 0, 1, 1) = 1
          or else Rounded_Euclidean (0, 0, 1, 1) = 2,
          "diag √2 rounds to 1 or 2");
   --  √2 ≈ 1.414 → rounds to 1
   Check (Rounded_Euclidean (0, 0, 1, 1) = 1, "√2 → 1 by Rounding");

   ------------------------------------------------------------------
   Section ("4. N=1 edge cases");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 1, 0);
      T := Exact_Tour (M);
      Check (Is_Valid_Tour (T), "N=1 Exact valid");
      Check (T.N = Nat (1), "N=1 Exact.N");
      Check (T.Cities (1) = 1, "N=1 city");
      Check (T.Cost = 0, "N=1 cost 0");
      Check (Tour_Cost (M, T) = T.Cost, "N=1 Tour_Cost cons");

      T := Brute_Force_Tour (M);
      Check (T.Cost = 0 and then Is_Valid_Tour (T), "N=1 Brute");

      T := Nearest_Neighbor_From (M, 1);
      Check (T.Cost = 0 and then Is_Valid_Tour (T), "N=1 NN");
      T := Best_Nearest_Neighbor (M);
      Check (T.Cost = 0, "N=1 Best NN");

      Imp := Improve_Two_Opt (M, T);
      Check (Imp.Cost = 0 and then Is_Valid_Tour (Imp), "N=1 2-opt noop");

      Check (DT_Raises (1), "N=1 Double_Tree raises");
   end;

   declare
      M : Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 1, 42);
      T := Exact_Tour (M);
      Check (T.Cost = 42, "N=1 diagonal cost 42");
   end;

   ------------------------------------------------------------------
   Section ("5. N=2 edge cases");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 2, 3);
      Put_Distance (M, 2, 1, 4);
      Put_Distance (M, 1, 1, 0);
      Put_Distance (M, 2, 2, 0);
      Opt := Exact_Tour (M);
      Check (Is_Valid_Tour (Opt), "N=2 Exact valid");
      Check (Opt.Cost = 7, "N=2 Exact cost 3+4");
      Check (Brute_Force_Tour (M).Cost = 7, "N=2 Brute=Exact");
      NN := Nearest_Neighbor_From (M, 1);
      Check (NN.Cost = 7 and then Is_Valid_Tour (NN), "N=2 NN");
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT), "N=2 DT valid");
      Check (DT.Cost = 7, "N=2 DT cost");
      Imp := Improve_Two_Opt (M, NN);
      Check (Imp.Cost = 7, "N=2 2-opt noop");
   end;

   ------------------------------------------------------------------
   Section ("6. N=3 triangle");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      Put_Symmetric (M, 1, 2, 1);
      Put_Symmetric (M, 2, 3, 1);
      Put_Symmetric (M, 1, 3, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 3, "equilateral Exact=3");
      Check (Brute_Force_Tour (M).Cost = 3, "equilateral Brute=3");
      Check (Best_Nearest_Neighbor (M).Cost = 3, "equilateral Best NN=3");
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT) and then DT.Cost = 3, "equilateral DT=3");
      Check (Held_Karp_Tour (M).Cost = Opt.Cost, "HK=Exact alias");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      --  Path metric: c12=1,c23=1,c13=2 → OPT = 1+1+2 = 4
      Fill_Path_Metric (M, 3);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 4, "path3 Exact=4");
      Check (Brute_Force_Tour (M).Cost = 4, "path3 Brute=4");
      NN := Nearest_Neighbor_From (M, 1);
      Check (NN.Cost = 4, "path3 NN from 1 = OPT");
      Check (Best_Nearest_Neighbor (M).Cost = 4, "path3 Best=OPT");
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT), "path3 DT valid");
      Check (DT.Cost >= Opt.Cost, "path3 DT >= OPT");
      Check (DT.Cost <= 2 * Opt.Cost, "path3 DT <= 2 OPT");
   end;

   ------------------------------------------------------------------
   Section ("7. Closed_Tour_Cost / Is_Valid_Tour");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Seq : City_Seq := [others => 1];
      Bad : Tour;
   begin
      Fill_Path_Metric (M, 4);
      Seq (1) := 1;
      Seq (2) := 2;
      Seq (3) := 3;
      Seq (4) := 4;
      C := Closed_Tour_Cost (M, Seq, 4);
      --  1→2→3→4→1 = 1+1+1+3 = 6
      Check (C = 6, "path4 closed cost 6");

      T.N := 4;
      T.Cities := Seq;
      T.Cost := C;
      Check (Is_Valid_Tour (T), "valid perm");

      Bad.N := 0;
      Check (not Is_Valid_Tour (Bad), "N=0 invalid");
      Bad.N := 3;
      Bad.Cities (1) := 1;
      Bad.Cities (2) := 2;
      Bad.Cities (3) := 2;
      Check (not Is_Valid_Tour (Bad), "duplicate invalid");
      Bad.Cities (3) := 4;
      Check (not Is_Valid_Tour (Bad), "out of 1..N invalid");
   end;

   ------------------------------------------------------------------
   Section ("8. Exact vs Brute agreement (N=4..8)");
   ------------------------------------------------------------------
   for N in 4 .. 8 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         E, B : Tour;
      begin
         Fill_Path_Metric (M, N);
         E := Exact_Tour (M);
         B := Brute_Force_Tour (M);
         Check (E.Cost = B.Cost,
                "path Exact=Brute N=" & N'Image);
         Check (Is_Valid_Tour (E) and then Is_Valid_Tour (B),
                "path tours valid N=" & N'Image);
         --  OPT on a path: go 1..N then return = (N-1) + (N-1) = 2(N-1)
         Check (E.Cost = Cost_Value (2 * (N - 1)),
                "path OPT formula N=" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("9. Asymmetric exact");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 4, 50);
      --  Cheap directed cycle 1→2→3→4→1
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 2, 3, 1);
      Put_Distance (M, 3, 4, 1);
      Put_Distance (M, 4, 1, 1);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 4, "asymmetric Exact=4");
      Check (Brute_Force_Tour (M).Cost = 4, "asymmetric Brute=4");
      Check (Is_Valid_Tour (Opt), "asymmetric valid");
   end;

   ------------------------------------------------------------------
   Section ("10. Nearest neighbour vs Exact");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 5);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 8, "path5 OPT=8");
      for S in 1 .. 5 loop
         NN := Nearest_Neighbor_From (M, Vid (S));
         Check (Is_Valid_Tour (NN), "NN valid start " & S'Image);
         Check (Tour_Cost (M, NN) = NN.Cost, "NN cost cons " & S'Image);
         Check (NN.Cost >= Opt.Cost, "NN >= OPT start " & S'Image);
         Check (NN.Cities (1) = Vid (S), "NN starts at " & S'Image);
      end loop;
      Check (Best_Nearest_Neighbor (M).Cost = Opt.Cost,
             "path5 Best NN finds OPT");
   end;

   --  Bait where a single NN start is suboptimal
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Complete_Const (M, 5, 100);
      Put_Distance (M, 1, 3, 1);
      Put_Distance (M, 3, 5, 1);
      Put_Distance (M, 5, 2, 1);
      Put_Distance (M, 2, 4, 1);
      Put_Distance (M, 4, 1, 1);
      Put_Distance (M, 1, 2, 1);
      Put_Distance (M, 2, 3, 50);
      Put_Distance (M, 3, 4, 50);
      Put_Distance (M, 4, 5, 50);
      Put_Distance (M, 5, 1, 50);
      Opt := Exact_Tour (M);
      Check (Opt.Cost = 5, "bait Exact=5");
      NN := Nearest_Neighbor_From (M, 1);
      Check (NN.Cost >= Opt.Cost, "bait NN>=Exact");
      Check (Best_Nearest_Neighbor (M).Cost = Opt.Cost,
             "bait Best finds Exact");
      if NN.Cost > Opt.Cost then
         Check (True, "bait NN start1 disagrees with Exact");
      else
         Check (NN.Cost = Opt.Cost, "bait NN start1 matched Exact");
      end if;
   end;

   ------------------------------------------------------------------
   Section ("11. 2-opt improvement");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 6, 1 .. 6) := [others => [others => 0]];
      Seed : Tour;
   begin
      Fill_Path_Metric (M, 6);
      --  Deliberately bad seed: 1,3,5,2,4,6
      Seed.N := 6;
      Seed.Cities (1) := 1;
      Seed.Cities (2) := 3;
      Seed.Cities (3) := 5;
      Seed.Cities (4) := 2;
      Seed.Cities (5) := 4;
      Seed.Cities (6) := 6;
      Seed.Cost := Closed_Tour_Cost (M, Seed.Cities, 6);
      Check (Is_Valid_Tour (Seed), "2-opt seed valid");
      Opt := Exact_Tour (M);
      Imp := Improve_Two_Opt (M, Seed);
      Check (Is_Valid_Tour (Imp), "2-opt result valid");
      Check (Imp.Cost <= Seed.Cost, "2-opt Cost <= seed");
      Check (Imp.Cost >= Opt.Cost, "2-opt >= OPT");
      Check (Tour_Cost (M, Imp) = Imp.Cost, "2-opt cost cons");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Euclidean_Square (M);
      Opt := Exact_Tour (M);
      NN := Best_Nearest_Neighbor (M);
      Imp := Improve_Two_Opt (M, NN);
      Check (Imp.Cost <= NN.Cost, "square 2-opt <= NN");
      Check (Imp.Cost >= Opt.Cost, "square 2-opt >= OPT");
      Check (Opt.Cost = 4, "unit square OPT=4");
   end;

   Check (Two_Opt_Raises_Invalid_Seed, "2-opt invalid seed raises");

   ------------------------------------------------------------------
   Section ("12. Double-tree 2-approx");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 6, 1 .. 6) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 6);
      Opt := Exact_Tour (M);
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT), "DT path6 valid");
      Check (DT.Cities (1) = 1, "DT starts at 1");
      Check (DT.Cost >= Opt.Cost, "DT >= OPT");
      Check (DT.Cost <= 2 * Opt.Cost, "DT <= 2 OPT (metric)");
      Check (Tour_Cost (M, DT) = DT.Cost, "DT cost cons");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
      Fill_Euclidean_Square (M);
      Opt := Exact_Tour (M);
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT), "DT square valid");
      Check (DT.Cost >= Opt.Cost, "DT square >= OPT");
      Check (DT.Cost <= 2 * Opt.Cost, "DT square <= 2 OPT");
   end;

   for N in 2 .. 8 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
      begin
         Fill_Path_Metric (M, N);
         DT := Double_Tree_Tour (M);
         Opt := Exact_Tour (M);
         Check (Is_Valid_Tour (DT), "DT valid N=" & N'Image);
         Check (DT.Cost <= 2 * Opt.Cost, "DT bound N=" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("13. Heuristics vs Exact survey (N=7)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 7, 1 .. 7) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 7);
      Opt := Exact_Tour (M);
      NN  := Best_Nearest_Neighbor (M);
      DT  := Double_Tree_Tour (M);
      Imp := Improve_Two_Opt (M, Nearest_Neighbor_From (M, 1));
      Check (Opt.Cost = 12, "survey OPT=12");
      Check (NN.Cost >= Opt.Cost, "survey BestNN >= OPT");
      Check (DT.Cost >= Opt.Cost, "survey DT >= OPT");
      Check (Imp.Cost >= Opt.Cost, "survey 2opt >= OPT");
      Check (DT.Cost <= 2 * Opt.Cost, "survey DT <= 2 OPT");
      Check (Is_Valid_Tour (Opt) and then Is_Valid_Tour (NN)
             and then Is_Valid_Tour (DT) and then Is_Valid_Tour (Imp),
             "survey all valid");
   end;

   ------------------------------------------------------------------
   Section ("14. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Exact_Raises (17), "Exact N=17 raises");
   Check (Brute_Raises (11), "Brute N=11 raises");
   Check (not Exact_Raises (8), "Exact N=8 ok");
   Check (not Brute_Raises (8), "Brute N=8 ok");
   Check (NN_Start_Raises (3, 4), "NN bad start raises");
   Check (Put_Raises (2, 1, 2, Int (-5)), "neg distance raises");
   Check (DT_Raises (1), "DT N=1 raises");

   declare
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      Seed : Tour;
      Raised : Boolean := False;
   begin
      Seed.N := 2;  -- mismatch with matrix order 3
      Seed.Cities (1) := 1;
      Seed.Cities (2) := 2;
      Seed.Cost := 0;
      begin
         Imp := Improve_Two_Opt (M, Seed);
         Touch_Tour (Imp);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "2-opt size mismatch raises");
   end;

   declare
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      Bad : Tour;
      Raised : Boolean := False;
   begin
      Bad.N := 4;
      Bad.Cities (1) := 1;
      Bad.Cities (2) := 2;
      Bad.Cities (3) := 3;
      Bad.Cities (4) := 1;
      begin
         C := Tour_Cost (M, Bad);
         Touch_Cost (C);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Tour_Cost size mismatch raises");
   end;

   ------------------------------------------------------------------
   Section ("15. Held–Karp on denser random-like tables");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 9, 1 .. 9) := [others => [others => 0]];
      --  Pseudo-random-ish but deterministic distances.
   begin
      for I in 1 .. 9 loop
         for J in 1 .. 9 loop
            if I = J then
               Put_Distance (M, Vid (I), Vid (J), 0);
            else
               Put_Distance
                 (M, Vid (I), Vid (J),
                  1 + ((I * 17 + J * 13) mod 23));
            end if;
         end loop;
      end loop;
      Opt := Exact_Tour (M);
      Check (Is_Valid_Tour (Opt), "dense9 Exact valid");
      Check (Brute_Force_Tour (M).Cost = Opt.Cost, "dense9 Brute=HK");
      Check (Best_Nearest_Neighbor (M).Cost >= Opt.Cost, "dense9 NN>=OPT");
      --  Not necessarily metric — DT still returns a valid tour
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT), "dense9 DT valid (may be non-metric)");
   end;

   ------------------------------------------------------------------
   Section ("16. Metric Euclidean cloud");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 8, 1 .. 8) := [others => [others => 0]];
      Xs : constant array (1 .. 8) of Integer :=
        [0, 2, 4, 6, 1, 3, 5, 7];
      Ys : constant array (1 .. 8) of Integer :=
        [0, 1, 0, 1, 3, 4, 3, 4];
      D  : Cost_Value;
   begin
      for I in 1 .. 8 loop
         for J in 1 .. 8 loop
            D := Rounded_Euclidean (Xs (I), Ys (I), Xs (J), Ys (J));
            Put_Distance (M, Vid (I), Vid (J), Integer (D));
         end loop;
      end loop;
      Opt := Exact_Tour (M);
      NN  := Best_Nearest_Neighbor (M);
      DT  := Double_Tree_Tour (M);
      Imp := Improve_Two_Opt (M, Nearest_Neighbor_From (M, 1));
      Check (Is_Valid_Tour (Opt), "euclid8 Exact valid");
      Check (NN.Cost >= Opt.Cost, "euclid8 NN>=OPT");
      Check (DT.Cost >= Opt.Cost, "euclid8 DT>=OPT");
      Check (DT.Cost <= 2 * Opt.Cost, "euclid8 DT<=2OPT");
      Check (Imp.Cost <= Nearest_Neighbor_From (M, 1).Cost,
             "euclid8 2opt improves or equal");
      Check (Imp.Cost >= Opt.Cost, "euclid8 2opt>=OPT");
      Check (Brute_Force_Tour (M).Cost = Opt.Cost, "euclid8 Brute=HK");
   end;

   ------------------------------------------------------------------
   Section ("17. All-starts NN bookkeeping");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Best_C : Cost_Value := Cost_Value'Last;
      Cand_C : Cost_Value;
   begin
      Fill_Path_Metric (M, 4);
      for S in 1 .. 4 loop
         Cand_C := Nearest_Neighbor_From (M, Vid (S)).Cost;
         if Cand_C < Best_C then
            Best_C := Cand_C;
         end if;
      end loop;
      Check (Best_Nearest_Neighbor (M).Cost = Best_C,
             "Best equals min over starts");
   end;

   ------------------------------------------------------------------
   Section ("18. Capacity smoke (heuristics at larger N)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix
        (1 .. Vertex_Id (20), 1 .. Vertex_Id (20)) :=
        [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 20);
      NN := Best_Nearest_Neighbor (M);
      Check (Is_Valid_Tour (NN) and then NN.N = Nat (20), "N=20 Best NN");
      DT := Double_Tree_Tour (M);
      Check (Is_Valid_Tour (DT) and then DT.N = Nat (20), "N=20 DT");
      declare
         Seed20 : constant Tour := Nearest_Neighbor_From (M, 1);
      begin
         Imp := Improve_Two_Opt (M, Seed20);
         Check (Is_Valid_Tour (Imp), "N=20 2-opt valid");
         Check (Imp.Cost <= Seed20.Cost, "N=20 2-opt <= seed");
      end;
      Check (Exact_Raises (20), "Exact N=20 > HK cap raises");
      Check (Brute_Raises (20), "Brute N=20 raises");
   end;

   ------------------------------------------------------------------
   Section ("19. Held–Karp at cap-ish size N=12");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 12, 1 .. 12) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 12);
      Opt := Held_Karp_Tour (M);
      Check (Is_Valid_Tour (Opt), "HK12 valid");
      Check (Opt.Cost = Cost_Value (2 * 11), "HK12 OPT=22");
      Check (Exact_Tour (M).Cost = Opt.Cost, "Exact alias HK12");
      NN := Best_Nearest_Neighbor (M);
      Check (NN.Cost >= Opt.Cost, "HK12 NN>=OPT");
      DT := Double_Tree_Tour (M);
      Check (DT.Cost <= 2 * Opt.Cost, "HK12 DT<=2OPT");
   end;

   ------------------------------------------------------------------
   Section ("20. Symmetric Put and Distance edge checks");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
      Raised : Boolean;
   begin
      Put_Symmetric (M, 1, 5, 11);
      Check (Distance (M, 1, 5) = 11 and then Distance (M, 5, 1) = 11,
             "sym 1↔5");
      Raised := False;
      begin
         C := Distance (M, Vid (6), Vid (1));
         Touch_Cost (C);
      exception
         when Constraint_Error =>
            Raised := True;  -- Vertex_Id range may catch first
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Distance out of Vertex_Id or matrix raises");

      Raised := False;
      begin
         C := Closed_Tour_Cost (M, [others => 1], Nat (0));
         Touch_Cost (C);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Closed_Tour_Cost N=0 raises");
   end;

   ------------------------------------------------------------------
   Section ("21. Tour permutation exhaust for N=4");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Best_Manual : Cost_Value := Cost_Value'Last;
      Cand : Cost_Value;
      Seq : City_Seq := [others => 1];
   begin
      Fill_Complete_Const (M, 4, 10);
      Put_Symmetric (M, 1, 2, 2);
      Put_Symmetric (M, 2, 3, 2);
      Put_Symmetric (M, 3, 4, 2);
      Put_Symmetric (M, 4, 1, 2);
      Put_Symmetric (M, 1, 3, 5);
      Put_Symmetric (M, 2, 4, 5);
      --  Explicit 6 perms with start 1
      declare
         type P3 is array (1 .. 3) of Vertex_Id;
         Perms : constant array (1 .. 6) of P3 :=
           [[2, 3, 4], [2, 4, 3], [3, 2, 4],
            [3, 4, 2], [4, 2, 3], [4, 3, 2]];
      begin
         for K in Perms'Range loop
            Seq (1) := 1;
            Seq (2) := Perms (K)(1);
            Seq (3) := Perms (K)(2);
            Seq (4) := Perms (K)(3);
            Cand := Closed_Tour_Cost (M, Seq, 4);
            if Cand < Best_Manual then
               Best_Manual := Cand;
            end if;
         end loop;
      end;
      Opt := Exact_Tour (M);
      Check (Opt.Cost = Best_Manual, "N=4 Exact matches manual OPT");
      Check (Brute_Force_Tour (M).Cost = Best_Manual, "N=4 Brute matches");
   end;

   ------------------------------------------------------------------
   Section ("22. 2-opt on already optimal");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 5);
      Opt := Exact_Tour (M);
      Imp := Improve_Two_Opt (M, Opt);
      Check (Imp.Cost = Opt.Cost, "2-opt on OPT stays OPT");
      Check (Is_Valid_Tour (Imp), "2-opt OPT still valid");
   end;

   ------------------------------------------------------------------
   Section ("23. NN + 2-opt pipeline");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 8, 1 .. 8) := [others => [others => 0]];
   begin
      Fill_Path_Metric (M, 8);
      Opt := Exact_Tour (M);
      NN  := Nearest_Neighbor_From (M, 4);
      Imp := Improve_Two_Opt (M, NN);
      Check (Imp.Cost <= NN.Cost, "pipeline 2opt <= NN");
      Check (Imp.Cost >= Opt.Cost, "pipeline >= OPT");
      Check (Best_Nearest_Neighbor (M).Cost = Opt.Cost,
             "path8 Best NN = OPT");
   end;

   ------------------------------------------------------------------
   Section ("24. Exact vs heuristics contrast table instances");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 6, 1 .. 6) := [others => [others => 0]];
      Xs : constant array (1 .. 6) of Integer := [0, 5, 5, 0, 2, 3];
      Ys : constant array (1 .. 6) of Integer := [0, 0, 5, 5, 2, 3];
   begin
      for I in 1 .. 6 loop
         for J in 1 .. 6 loop
            Put_Distance
              (M, Vid (I), Vid (J),
               Integer (Rounded_Euclidean
                 (Xs (I), Ys (I), Xs (J), Ys (J))));
         end loop;
      end loop;
      Opt := Exact_Tour (M);
      NN  := Best_Nearest_Neighbor (M);
      DT  := Double_Tree_Tour (M);
      Imp := Improve_Two_Opt (M, Best_Nearest_Neighbor (M));
      Check (Is_Valid_Tour (Opt), "contrast Exact valid");
      Check (NN.Cost >= Opt.Cost, "contrast NN");
      Check (DT.Cost >= Opt.Cost and then DT.Cost <= 2 * Opt.Cost,
             "contrast DT bound");
      Check (Imp.Cost >= Opt.Cost and then Imp.Cost <= NN.Cost,
             "contrast 2opt between OPT and NN");
   end;

   ------------------------------------------------------------------
   Section ("25. More Invalid_Argument / shape");
   ------------------------------------------------------------------
   Check (Order_Raises (1, 2, 1, 3), "rect matrix raises");
   Check (Put_Raises (3, 1, 2, Int (-100)), "large neg raises");

   declare
      Raised : Boolean := False;
      M : constant Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      begin
         T := Nearest_Neighbor_From (M, Vid (3));
         Touch_Tour (T);
      exception
         when Constraint_Error =>
            Raised := True;
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "NN start 3 on N=2 raises");
   end;

   ------------------------------------------------------------------
   Section ("26. Cost consistency bulk");
   ------------------------------------------------------------------
   for N in 3 .. 7 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
      begin
         Fill_Path_Metric (M, N);
         T := Exact_Tour (M);
         Check (Tour_Cost (M, T) = T.Cost, "bulk Exact cons N=" & N'Image);
         T := Best_Nearest_Neighbor (M);
         Check (Tour_Cost (M, T) = T.Cost, "bulk NN cons N=" & N'Image);
         T := Double_Tree_Tour (M);
         Check (Tour_Cost (M, T) = T.Cost, "bulk DT cons N=" & N'Image);
         T := Improve_Two_Opt (M, Nearest_Neighbor_From (M, 1));
         Check (Tour_Cost (M, T) = T.Cost, "bulk 2opt cons N=" & N'Image);
         T := Brute_Force_Tour (M);
         Check (Tour_Cost (M, T) = T.Cost, "bulk Brute cons N=" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("27. Asymmetric NN / Exact");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
   begin
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
      Opt := Exact_Tour (M);
      NN := Nearest_Neighbor_From (M, 1);
      Check (NN.Cost >= Opt.Cost, "asym showcase NN>=OPT");
      Check (Best_Nearest_Neighbor (M).Cost >= Opt.Cost,
             "asym showcase Best>=OPT");
      Check (Is_Valid_Tour (Opt), "asym showcase Exact valid");
   end;

   ------------------------------------------------------------------
   Section ("28. Double-tree starts at 1 after rotation");
   ------------------------------------------------------------------
   for N in 3 .. 9 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
      begin
         Fill_Path_Metric (M, N);
         DT := Double_Tree_Tour (M);
         Check (DT.Cities (1) = 1, "DT rot start1 N=" & N'Image);
         Check (Is_Valid_Tour (DT), "DT rot valid N=" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("29. Held_Karp_Tour == Exact_Tour identity");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 6, 1 .. 6) := [others => [others => 0]];
      A, B : Tour;
   begin
      Fill_Path_Metric (M, 6);
      A := Held_Karp_Tour (M);
      B := Exact_Tour (M);
      Check (A.Cost = B.Cost, "HK cost = Exact cost");
      Check (Is_Valid_Tour (A) and then Is_Valid_Tour (B),
             "HK and Exact both valid");
   end;

   ------------------------------------------------------------------
   Section ("30. Zero-warning helper touch");
   ------------------------------------------------------------------
   Check (Nat (Max_Vertices) = Max_Vertices, "Nat identity");
   Check (Int (0) = 0, "Int identity");
   Check (Vid (1) = 1, "Vid identity");
   Touch_Nat (Pass_Count);
   Touch_Cost (0);
   declare
      Z : Tour;
   begin
      Z.N := 1;
      Z.Cities (1) := 1;
      Z.Cost := 0;
      Touch_Tour (Z);
      Check (Is_Valid_Tour (Z), "touch trivial tour");
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
