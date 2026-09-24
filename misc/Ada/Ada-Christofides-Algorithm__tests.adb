--  Standalone test suite for Christofides_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Christofides_Algorithm; use Christofides_Algorithm;

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

   procedure Touch_List (L : Vertex_List) is
   begin
      Touch_Nat (L.Count);
   end Touch_List;

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

   function Approx_Raises_N (N : Positive) return Boolean is
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
      T := Approximate_Tour (M);
      Touch_Tour (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Approx_Raises_N;

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

   function Matching_Raises_Odd_Count return Boolean is
      M : constant Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 1]];
      Odds : Vertex_List;
      C : Cost_Value;
   begin
      Odds.Count := 3;
      Odds.Vertices (1) := 1;
      Odds.Vertices (2) := 2;
      Odds.Vertices (3) := 3;
      C := Matching_Cost (M, Odds);
      Touch_Cost (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Matching_Raises_Odd_Count;

   function Matching_Raises_Overflow return Boolean is
      M : constant Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 1]];
      Odds : Vertex_List;
      C : Cost_Value;
   begin
      Odds.Count := Max_Matching_Odd + 2;
      if Odds.Count > Max_Vertices then
         Odds.Count := Max_Matching_Odd + 2;
      end if;
      for I in 1 .. Odds.Count loop
         Odds.Vertices (I) := Vertex_Id (((I - 1) mod 4) + 1);
      end loop;
      C := Matching_Cost (M, Odds);
      Touch_Cost (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Matching_Raises_Overflow;

   procedure Fill_Complete
     (M : in out Cost_Matrix; N : Positive; Base : Cost_Value)
   is
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               M (Vertex_Id (I), Vertex_Id (J)) := 0;
            else
               M (Vertex_Id (I), Vertex_Id (J)) := Base;
            end if;
         end loop;
      end loop;
   end Fill_Complete;

   procedure Fill_Line (M : in out Cost_Matrix; N : Positive) is
      --  Cities on a line at positions 0,1,2,...,N-1; distance |i-j|.
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               M (Vertex_Id (I), Vertex_Id (J)) := 0;
            else
               declare
                  D : constant Integer := abs (I - J);
               begin
                  Put_Symmetric (M, Vertex_Id (I), Vertex_Id (J), D);
               end;
            end if;
         end loop;
      end loop;
   end Fill_Line;

   procedure Fill_Square4 (M : in out Cost_Matrix) is
      --  Unit square: (0,0),(1,0),(1,1),(0,1) → edges 1, diagonals √2≈1.
      Xs : constant array (1 .. 4) of Integer := [0, 1, 1, 0];
      Ys : constant array (1 .. 4) of Integer := [0, 0, 1, 1];
      D  : Cost_Value;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            if I = J then
               M (Vertex_Id (I), Vertex_Id (J)) := 0;
            else
               D := Rounded_Euclidean (Xs (I), Ys (I), Xs (J), Ys (J));
               M (Vertex_Id (I), Vertex_Id (J)) := D;
            end if;
         end loop;
      end loop;
   end Fill_Square4;

   function Ratio_OK (Approx, Exact : Cost_Value) return Boolean is
   begin
      --  Approx ≤ 1.5 * Exact ⇔ 2*Approx ≤ 3*Exact (exact integer).
      return Cost_Value (2) * Approx <= Cost_Value (3) * Exact;
   end Ratio_OK;

begin
   Put_Line ("Christofides_Algorithm test suite");
   Put_Line ("Max_Vertices=" & Max_Vertices'Image
             & " Max_Matching_Odd=" & Max_Matching_Odd'Image
             & " Max_Exact_Vertices=" & Max_Exact_Vertices'Image);

   ------------------------------------------------------------------
   Section ("1. Matrix builders and queries");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
   begin
      Put_Distance (M, 1, 2, Int (5));
      Check (Distance (M, 1, 2) = 5, "Put_Distance 1→2 = 5");
      Put_Symmetric (M, 2, 3, Int (7));
      Check (Distance (M, 2, 3) = 7, "Put_Symmetric 2→3 = 7");
      Check (Distance (M, 3, 2) = 7, "Put_Symmetric 3→2 = 7");
      Check (Matrix_Order (M) = Nat (3), "Matrix_Order = 3");
      --  Reverse still 0 after Put_Distance-only; undirected uses min.
      Check (Undirected_Weight (M, 1, 2) = 0, "Undirected_Weight min with 0");
      Put_Symmetric (M, 1, 2, Int (5));
      Check (Undirected_Weight (M, 1, 2) = 5, "Undirected_Weight after symmetric");
   end;
   Check (Put_Raises (3, 1, 2, Int (-1)), "Put_Distance rejects negative");
   Check (Put_Raises (3, 1, 2, Int (-99)), "Put_Distance rejects -99");
   Check (Order_Raises (2, 3, 2, 3), "Matrix_Order rejects First/=1");
   Check (Order_Raises (1, 3, 1, 2), "Matrix_Order rejects non-square");
   Check (Rounded_Euclidean (0, 0, 3, 4) = 5, "Rounded_Euclidean 3-4-5");
   Check (Rounded_Euclidean (0, 0, 0, 0) = 0, "Rounded_Euclidean zero");
   Check (Rounded_Euclidean (0, 0, 1, 1) = 1, "Rounded_Euclidean √2→1");
   Check (Rounded_Euclidean (0, 0, 1, 0) = 1, "Rounded_Euclidean unit");

   ------------------------------------------------------------------
   Section ("2. N=2 hand check");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
      T : Tour;
      E : Tour;
      Odds : Vertex_List;
   begin
      Put_Symmetric (M, 1, 2, Int (10));
      Check (MST_Cost (M) = 10, "N=2 MST_Cost = 10");
      Odds := Odd_Vertices (M);
      Check (Odds.Count = Nat (2), "N=2 two odd vertices");
      Check (Odds.Vertices (1) = 1 and then Odds.Vertices (2) = 2,
             "N=2 odds are {1,2}");
      Check (Matching_Cost (M, Odds) = 10, "N=2 matching = 10");
      T := Approximate_Tour (M);
      Check (Is_Valid_Tour (T), "N=2 approx is valid tour");
      Check (T.N = Nat (2), "N=2 approx N=2");
      Check (T.Cost = 20, "N=2 approx cost = 2*10");
      Check (Tour_Cost (M, T) = T.Cost, "N=2 Tour_Cost agrees");
      E := Exact_Tour (M);
      Check (E.Cost = 20, "N=2 Exact = 20");
      Check (Ratio_OK (T.Cost, E.Cost), "N=2 approx ≤ 1.5 Exact");
   end;

   ------------------------------------------------------------------
   Section ("3. N=3 triangle hand check");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
      T : Tour;
      E : Tour;
      Odds : Vertex_List;
   begin
      Put_Symmetric (M, 1, 2, Int (1));
      Put_Symmetric (M, 2, 3, Int (1));
      Put_Symmetric (M, 1, 3, Int (1));
      Check (MST_Cost (M) = 2, "equilateral MST = 2");
      Odds := Odd_Vertices (M);
      Check (Odds.Count mod 2 = 0, "N=3 odd count even");
      Check (Odds.Count = Nat (2), "path MST has 2 odds");
      T := Approximate_Tour (M);
      Check (Is_Valid_Tour (T), "N=3 approx valid");
      Check (T.Cost = 3, "N=3 approx = 3 (the triangle)");
      E := Exact_Tour (M);
      Check (E.Cost = 3, "N=3 Exact = 3");
      Check (Ratio_OK (T.Cost, E.Cost), "N=3 ratio OK");
   end;

   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
      T : Tour;
      E : Tour;
   begin
      --  Path metric: c12=1, c23=1, c13=2
      Put_Symmetric (M, 1, 2, Int (1));
      Put_Symmetric (M, 2, 3, Int (1));
      Put_Symmetric (M, 1, 3, Int (2));
      Check (MST_Cost (M) = 2, "path-3 MST = 2");
      T := Approximate_Tour (M);
      E := Exact_Tour (M);
      Check (E.Cost = 4, "path-3 Exact tour = 4");
      Check (Is_Valid_Tour (T), "path-3 approx valid");
      Check (Ratio_OK (T.Cost, E.Cost), "path-3 ratio OK");
      Check (T.Cost = E.Cost, "path-3 Christofides optimal");
   end;

   ------------------------------------------------------------------
   Section ("4. N=4 square / line hand checks");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      T : Tour;
      E : Tour;
      Odds : Vertex_List;
   begin
      Fill_Square4 (M);
      Check (MST_Cost (M) = 3, "square MST = 3 (three unit edges)");
      Odds := Odd_Vertices (M);
      Check (Odds.Count mod 2 = 0, "square odd count even");
      T := Approximate_Tour (M);
      E := Exact_Tour (M);
      Check (Is_Valid_Tour (T), "square approx valid");
      Check (Is_Valid_Tour (E), "square exact valid");
      Check (E.Cost = 4, "square Exact = 4");
      Check (Ratio_OK (T.Cost, E.Cost), "square ratio ≤ 1.5");
      Check (T.Cost >= E.Cost, "square approx ≥ Exact");
   end;

   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      T : Tour;
      E : Tour;
   begin
      Fill_Line (M, 4);
      Check (MST_Cost (M) = 3, "line-4 MST = 3");
      T := Approximate_Tour (M);
      E := Exact_Tour (M);
      --  OPT on line of 4: 0-1-2-3-0 → 1+1+1+3 = 6
      Check (E.Cost = 6, "line-4 Exact = 6");
      Check (Ratio_OK (T.Cost, E.Cost), "line-4 ratio OK");
      Check (Is_Valid_Tour (T), "line-4 approx valid");
   end;

   ------------------------------------------------------------------
   Section ("5. Odd vertices always even; matching empty");
   ------------------------------------------------------------------
   for N in 2 .. 10 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         Odds : Vertex_List;
         C    : Cost_Value;
      begin
         Fill_Line (M, N);
         Odds := Odd_Vertices (M);
         Check (Odds.Count mod 2 = 0,
                "line-" & N'Image & " odd count even");
         Check (Odds.Count = Nat (2),
                "line-" & N'Image & " MST path has 2 odds");
         C := Matching_Cost (M, Odds);
         Touch_Cost (C);
         Check (True, "line-" & N'Image & " matching computed");
      end;
   end loop;

   declare
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1]];
      Empty : Vertex_List;
   begin
      Empty.Count := 0;
      Check (Matching_Cost (M, Empty) = 0, "empty matching cost 0");
   end;

   ------------------------------------------------------------------
   Section ("6. Approximate ≤ 1.5 Exact on Euclidean instances");
   ------------------------------------------------------------------
   declare
      type Pt is record X, Y : Integer; end record;
      type Pt_Arr is array (Positive range <>) of Pt;

      procedure Check_Points (Pts : Pt_Arr; Label : String) is
         N : constant Positive := Pts'Length;
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T, E : Tour;
         II, JJ : Vertex_Id;
      begin
         for I in Pts'Range loop
            for J in Pts'Range loop
               if I /= J then
                  II := Vertex_Id (I - Pts'First + 1);
                  JJ := Vertex_Id (J - Pts'First + 1);
                  M (II, JJ) := Rounded_Euclidean
                    (Pts (I).X, Pts (I).Y, Pts (J).X, Pts (J).Y);
               end if;
            end loop;
         end loop;
         T := Approximate_Tour (M);
         Check (Is_Valid_Tour (T), Label & " approx valid");
         if N <= Max_Exact_Vertices then
            E := Exact_Tour (M);
            Check (Is_Valid_Tour (E), Label & " exact valid");
            Check (Ratio_OK (T.Cost, E.Cost), Label & " ≤ 1.5 Exact");
            Check (T.Cost >= E.Cost, Label & " approx ≥ Exact");
         end if;
      end Check_Points;

      L_Tri : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (0, 1)];
      Iso : constant Pt_Arr :=
        [1 => (0, 0), 2 => (2, 0), 3 => (1, 1)];
      Line4 : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (2, 0), 4 => (3, 0)];
      Sq : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (1, 1), 4 => (0, 1)];
      Rect : constant Pt_Arr :=
        [1 => (0, 0), 2 => (3, 0), 3 => (3, 4), 4 => (0, 4)];
      Pent : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (2, 1), 4 => (1, 2), 5 => (0, 1)];
      Sq_Diag : constant Pt_Arr :=
        [1 => (0, 0), 2 => (5, 0), 3 => (5, 5), 4 => (0, 5),
         5 => (2, 2), 6 => (3, 3)];
      Line7 : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (2, 0), 4 => (3, 0),
         5 => (4, 0), 6 => (5, 0), 7 => (6, 0)];
      Grid24 : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (2, 0), 4 => (3, 0),
         5 => (0, 1), 6 => (1, 1), 7 => (2, 1), 8 => (3, 1)];
      Ring9 : constant Pt_Arr :=
        [1 => (0, 0), 2 => (2, 0), 3 => (4, 0), 4 => (4, 2),
         5 => (4, 4), 6 => (2, 4), 7 => (0, 4), 8 => (0, 2),
         9 => (2, 2)];
      Grid25 : constant Pt_Arr :=
        [1 => (0, 0), 2 => (1, 0), 3 => (2, 0), 4 => (3, 0), 5 => (4, 0),
         6 => (0, 1), 7 => (1, 1), 8 => (2, 1), 9 => (3, 1), 10 => (4, 1)];
   begin
      Check_Points (L_Tri, "L-tri");
      Check_Points (Iso, "iso");
      Check_Points (Line4, "line4pts");
      Check_Points (Sq, "sq");
      Check_Points (Rect, "3-4-5-rect");
      Check_Points (Pent, "pent");
      Check_Points (Sq_Diag, "sq+diag");
      Check_Points (Line7, "line7");
      Check_Points (Grid24, "grid2x4");
      Check_Points (Ring9, "ring9");
      Check_Points (Grid25, "grid2x5");
   end;

   ------------------------------------------------------------------
   Section ("7. Complete unit / constant matrices");
   ------------------------------------------------------------------
   for N in 2 .. 8 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T, E : Tour;
         Odds : Vertex_List;
      begin
         Fill_Complete (M, N, 1);
         Check (MST_Cost (M) = Cost_Value (N - 1),
                "K" & N'Image & " MST = N-1");
         Odds := Odd_Vertices (M);
         Check (Odds.Count mod 2 = 0, "K" & N'Image & " odds even");
         T := Approximate_Tour (M);
         Check (Is_Valid_Tour (T), "K" & N'Image & " approx valid");
         Check (T.Cost = Cost_Value (N), "K" & N'Image & " tour cost N");
         E := Exact_Tour (M);
         Check (E.Cost = Cost_Value (N), "K" & N'Image & " Exact = N");
         Check (Ratio_OK (T.Cost, E.Cost), "K" & N'Image & " ratio");
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Approx_Raises_N (1), "Approximate_Tour rejects N=1");
   Check (Exact_Raises_N (1), "Exact_Tour rejects N=1");
   Check (Exact_Raises_N (11), "Exact_Tour rejects N=11");
   Check (Tour_Cost_Raises_Mismatch, "Tour_Cost size mismatch");
   Check (Matching_Raises_Odd_Count, "Matching_Cost rejects odd |O|");
   Check (Matching_Raises_Overflow, "Matching_Cost rejects |O|>cap");
   Check (Order_Raises (1, 1, 1, 2), "non-square 1x2 rejected");

   declare
      function MST_Raises_N1 return Boolean is
         M : constant Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
         C : Cost_Value;
      begin
         C := MST_Cost (M);
         Touch_Cost (C);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end MST_Raises_N1;
   begin
      Check (MST_Raises_N1, "MST_Cost rejects N=1");
   end;

   declare
      function Odd_Raises_N1 return Boolean is
         M : constant Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0]];
         L : Vertex_List;
      begin
         L := Odd_Vertices (M);
         Touch_List (L);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Odd_Raises_N1;
   begin
      Check (Odd_Raises_N1, "Odd_Vertices rejects N=1");
   end;

   declare
      function Bad_Start_Matrix return Boolean is
         subtype R is Vertex_Id range 2 .. 4;
         M : constant Cost_Matrix (R, R) := [others => [others => 1]];
         T : Tour;
      begin
         T := Approximate_Tour (M);
         Touch_Tour (T);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Bad_Start_Matrix;
   begin
      Check (Bad_Start_Matrix, "Approximate rejects First/=1");
   end;

   declare
      function Closed_Raises_N0 return Boolean is
         M : constant Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 1]];
         Cities : constant City_Seq := [others => 1];
         C : Cost_Value;
      begin
         C := Closed_Tour_Cost (M, Cities, Nat (0));
         Touch_Cost (C);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Closed_Raises_N0;
   begin
      Check (Closed_Raises_N0, "Closed_Tour_Cost rejects N=0");
   end;

   ------------------------------------------------------------------
   Section ("9. Is_Valid_Tour");
   ------------------------------------------------------------------
   declare
      T : Tour;
   begin
      Check (not Is_Valid_Tour (T), "empty tour invalid");
      T.N := 1;
      T.Cities (1) := 1;
      Check (not Is_Valid_Tour (T), "N=1 tour invalid");
      T.N := 2;
      T.Cities (1) := 1;
      T.Cities (2) := 2;
      Check (Is_Valid_Tour (T), "perm 1,2 valid");
      T.Cities (2) := 1;
      Check (not Is_Valid_Tour (T), "duplicate invalid");
      T.Cities (1) := 1;
      T.Cities (2) := 3;
      Check (not Is_Valid_Tour (T), "out of range invalid");
   end;

   ------------------------------------------------------------------
   Section ("10. Larger line instances (no exact)");
   ------------------------------------------------------------------
   for N in 11 .. 16 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T : Tour;
         Odds : Vertex_List;
         Mc : Cost_Value;
      begin
         Fill_Line (M, N);
         Odds := Odd_Vertices (M);
         Check (Odds.Count = Nat (2), "line-" & N'Image & " 2 odds");
         Mc := Matching_Cost (M, Odds);
         --  Matching of endpoints: distance N-1
         Check (Mc = Cost_Value (N - 1),
                "line-" & N'Image & " matching = N-1");
         T := Approximate_Tour (M);
         Check (Is_Valid_Tour (T), "line-" & N'Image & " approx valid");
         --  Euler is the cycle; no shortcuts help much: cost = MST + match
         --  = (N-1) + (N-1) = 2(N-1); shortcutting may reduce via chords.
         Check (T.Cost <= Cost_Value (2 * (N - 1)),
                "line-" & N'Image & " cost ≤ Euler bound");
         Check (T.Cost >= Cost_Value (2 * (N - 1)),
                "line-" & N'Image & " line tour ≥ 2(N-1)?");
         --  Actually OPT = 2(N-1) for a line (go to end and back via same?).
         --  Undirected line: visit 1..N then return: cost (N-1) + (N-1) = 2(N-1).
         --  Yes OPT = 2(N-1). Christofides with path MST + end matching
         --  yields the same cycle with no useful shortcuts → cost 2(N-1).
         Check (T.Cost = Cost_Value (2 * (N - 1)),
                "line-" & N'Image & " approx = OPT = 2(N-1)");
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("11. Capacity smoke Max_Vertices line");
   ------------------------------------------------------------------
   declare
      N : constant Positive := Max_Vertices;
      M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
        [others => [others => 0]];
      T : Tour;
      Odds : Vertex_List;
   begin
      Fill_Line (M, N);
      Check (Matrix_Order (M) = Nat (N), "Max_Vertices Matrix_Order");
      Odds := Odd_Vertices (M);
      Check (Odds.Count = Nat (2), "Max_Vertices line 2 odds");
      T := Approximate_Tour (M);
      Check (Is_Valid_Tour (T), "Max_Vertices approx valid");
      Check (T.Cost = Cost_Value (2 * (N - 1)), "Max_Vertices line OPT");
   end;

   ------------------------------------------------------------------
   Section ("12. MST properties");
   ------------------------------------------------------------------
   for N in 2 .. 10 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         Mc : Cost_Value;
         T  : Tour;
      begin
         Fill_Line (M, N);
         Mc := MST_Cost (M);
         Check (Mc = Cost_Value (N - 1),
                "MST line-" & N'Image & " = N-1");
         T := Approximate_Tour (M);
         Check (T.Cost >= Mc, "tour ≥ MST line-" & N'Image);
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("13. Asymmetric stored entries still run (undirected min)");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => 0]];
      T : Tour;
   begin
      M (1, 2) := 1;
      M (2, 1) := 5;
      M (2, 3) := 1;
      M (3, 2) := 5;
      M (1, 3) := 2;
      M (3, 1) := 9;
      Check (Undirected_Weight (M, 1, 2) = 1, "undirected min(1,5)=1");
      Check (Undirected_Weight (M, 1, 3) = 2, "undirected min(2,9)=2");
      T := Approximate_Tour (M);
      Check (Is_Valid_Tour (T), "asymmetric-storage approx valid");
      --  Tour_Cost uses directed stored entries along the orientation.
      Check (Tour_Cost (M, T) = T.Cost, "asymmetric Tour_Cost agrees");
   end;

   ------------------------------------------------------------------
   Section ("14. API counters / constants");
   ------------------------------------------------------------------
   Check (Max_Vertices = Nat (24), "Max_Vertices = 24");
   Check (Max_Matching_Odd = Nat (12), "Max_Matching_Odd = 12");
   Check (Max_Exact_Vertices = Nat (10), "Max_Exact_Vertices = 10");
   Check (Nat (Max_Matching_Odd) <= Nat (Max_Vertices),
          "matching cap ≤ vertices");
   Check (Vid (1) = 1, "Vertex_Id 1");
   Check (Nat (Max_Vertices) >= Nat (2), "Max_Vertices ≥ 2");

   ------------------------------------------------------------------
   Section ("15. More Euclidean ratio checks N=5..10");
   ------------------------------------------------------------------
   for Seed in 1 .. 6 loop
      declare
         N : constant Positive := 4 + Seed; -- 5 .. 10
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T, E : Tour;
         Xs, Ys : array (1 .. 10) of Integer;
      begin
         for I in 1 .. N loop
            Xs (I) := (I * (3 + Seed) + Seed * 7) mod 11;
            Ys (I) := (I * (5 + Seed) + Seed * 3) mod 13;
         end loop;
         for I in 1 .. N loop
            for J in 1 .. N loop
               if I /= J then
                  M (Vertex_Id (I), Vertex_Id (J)) :=
                    Rounded_Euclidean (Xs (I), Ys (I), Xs (J), Ys (J));
               end if;
            end loop;
         end loop;
         T := Approximate_Tour (M);
         E := Exact_Tour (M);
         Check (Is_Valid_Tour (T),
                "eucl seed" & Seed'Image & " approx valid");
         Check (Ratio_OK (T.Cost, E.Cost),
                "eucl seed" & Seed'Image & " ≤ 1.5 Exact");
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("16. Matching on explicit odd pairs");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Odds : Vertex_List;
   begin
      Fill_Complete (M, 4, 1);
      Put_Symmetric (M, 1, 2, Int (10));
      Put_Symmetric (M, 3, 4, Int (10));
      Put_Symmetric (M, 1, 3, Int (1));
      Put_Symmetric (M, 2, 4, Int (1));
      Put_Symmetric (M, 1, 4, Int (5));
      Put_Symmetric (M, 2, 3, Int (5));
      Odds.Count := 4;
      Odds.Vertices (1) := 1;
      Odds.Vertices (2) := 2;
      Odds.Vertices (3) := 3;
      Odds.Vertices (4) := 4;
      --  Best perfect matching: {1-3, 2-4} cost 1+1 = 2
      Check (Matching_Cost (M, Odds) = 2, "MWPM prefers cheap pairs");
      Odds.Count := 2;
      Odds.Vertices (1) := 1;
      Odds.Vertices (2) := 2;
      Check (Matching_Cost (M, Odds) = 10, "single-pair matching");
   end;

   ------------------------------------------------------------------
   Section ("17. Tour starts at vertex 1");
   ------------------------------------------------------------------
   for N in 2 .. 8 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T : Tour;
      begin
         Fill_Line (M, N);
         T := Approximate_Tour (M);
         Check (T.Cities (1) = 1, "approx starts at 1 (N=" & N'Image & ")");
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("18. Exact_Tour N=2..6 known optima");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0]];
      E : Tour;
   begin
      Fill_Line (M, 5);
      E := Exact_Tour (M);
      Check (E.Cost = 8, "line-5 Exact = 8");
      Check (Is_Valid_Tour (E), "line-5 Exact valid");
      Check (E.Cities (1) = 1, "Exact starts at 1");
   end;

   ------------------------------------------------------------------
   Section ("19. Extra Put_Symmetric / Distance edge cases");
   ------------------------------------------------------------------
   declare
      M : Cost_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0]];
   begin
      Put_Symmetric (M, 1, 1, Int (0));
      Check (Distance (M, 1, 1) = 0, "diagonal Put_Symmetric");
      Put_Distance (M, 1, 2, Int (0));
      Check (Distance (M, 1, 2) = 0, "zero distance allowed");
   end;
   Check (Put_Raises (2, 1, 2, Int (-1)), "negative again");

   ------------------------------------------------------------------
   Section ("20. Bulk validity on complete graphs");
   ------------------------------------------------------------------
   for N in 2 .. 12 loop
      declare
         M : Cost_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N)) :=
           [others => [others => 0]];
         T : Tour;
         Odds : Vertex_List;
      begin
         Fill_Complete (M, N, Cost_Value (N));
         Odds := Odd_Vertices (M);
         Check (Odds.Count mod 2 = 0, "bulk K odds even N=" & N'Image);
         T := Approximate_Tour (M);
         Check (Is_Valid_Tour (T), "bulk K valid N=" & N'Image);
         Check (T.Cost = Cost_Value (N) * Cost_Value (N),
                "bulk K cost N*w N=" & N'Image);
      end;
   end loop;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
