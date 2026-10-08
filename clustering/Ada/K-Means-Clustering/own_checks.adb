--  Own checks for Lloyd / naive k-means.
--  The reference is an independent assignment and mean update:
--  squared Euclidean distance written here, lowest index on a tie,
--  empty clusters keep the previous center. Not the package's loops.
--  Seed 20261008, printed, overridable with AA_SEED.

with Ada.Environment_Variables;
with Ada.Text_IO;
with K_Means_Clustering;

procedure Own_Checks (Fail_Count : out Natural) is
   use K_Means_Clustering;
   package Txt renames Ada.Text_IO;

   Checks : Natural := 0;
   Fails  : Natural := 0;

   type U32 is mod 2**32;
   Seed : U32 := 20261008;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   function Next_U return U32 is
   begin
      Seed := Seed * 1664525 + 1013904223;
      return Seed;
   end Next_U;

   function Unit return Real is
   begin
      return Real (Long_Float (Next_U) / 4294967296.0);
   end Unit;

   function R (Lo, Hi : Real) return Real is
   begin
      return Lo + (Hi - Lo) * Unit;
   end R;

   function Own_Sq (Data : Dataset; P : Point_Index; C : Centers; K : Site_Index)
     return Real
   is
      S : Real := 0.0;
      Dc : constant Integer := Data'First (2);
      Cc : constant Integer := C'First (2);
   begin
      for J in 0 .. Data'Length (2) - 1 loop
         declare
            Diff : constant Real :=
              Data (P, Dim_Index (Dc + J)) - C (K, Dim_Index (Cc + J));
         begin
            S := S + Diff * Diff;
         end;
      end loop;
      return S;
   end Own_Sq;

   function Own_Nearest (Data : Dataset; P : Point_Index; C : Centers)
     return Site_Index
   is
      Best : Site_Index := C'First (1);
      Best_S : Real := Own_Sq (Data, P, C, Best);
   begin
      for K in C'First (1) + 1 .. C'Last (1) loop
         declare
            S : constant Real := Own_Sq (Data, P, C, K);
         begin
            if S < Best_S then
               Best_S := S;
               Best := K;
            end if;
         end;
      end loop;
      return Best;
   end Own_Nearest;

   procedure Read_Seed is
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         declare
            Raw : constant String := Ada.Environment_Variables.Value ("AA_SEED");
            Acc : U32 := 0;
         begin
            for Ch of Raw loop
               if Ch in '0' .. '9' then
                  Acc := Acc * 10 + U32 (Character'Pos (Ch) - Character'Pos ('0'));
               end if;
            end loop;
            if Raw'Length > 0 then
               Seed := Acc;
            end if;
         end;
      end if;
      Txt.Put_Line ("own checks seed:" & U32'Image (Seed)
        & " (default 20261008; set AA_SEED to override)");
   end Read_Seed;

begin
   Fail_Count := 0;
   Read_Seed;

   --  Two tight clusters. One Lloyd step from the cluster seeds is the means.
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [2.0, 0.0],
         [0.0, 2.0],
         [10.0, 10.0],
         [12.0, 10.0],
         [10.0, 12.0]];
      C : Centers :=
        [[0.0, 0.0],
         [10.0, 10.0]];
      Lab : constant Labels := Assign_Labels (Data, C);
      Empty : Empty_Flags (1 .. 2);
      Own_Lab : Labels (1 .. 6);
   begin
      for P in Data'Range (1) loop
         Own_Lab (P) := Natural (Own_Nearest (Data, P, C));
         Note (Lab (P) = Own_Lab (P), "assignment matches own nearest center");
      end loop;
      Compute_Centroids (Data, Lab, C, Empty);
      Note (not Empty (1) and then not Empty (2), "both toy clusters are used");
      Note (abs (C (1, 1) - (0.0 + 2.0 + 0.0) / 3.0) < 1.0e-9
        and then abs (C (1, 2) - (0.0 + 0.0 + 2.0) / 3.0) < 1.0e-9,
        "left mean is the average of its three points");
      Note (abs (C (2, 1) - (10.0 + 12.0 + 10.0) / 3.0) < 1.0e-9
        and then abs (C (2, 2) - (10.0 + 10.0 + 12.0) / 3.0) < 1.0e-9,
        "right mean is the average of its three points");
      declare
         Params : constant Parameters :=
           (K => 2, Max_Iters => 1, Tol => 0.0, Seed => 1);
         Step : constant Result :=
           Run_Lloyd (Data, [[0.0, 0.0], [10.0, 10.0]], Params);
      begin
         Note (Step.Iters = 1, "one iteration does a single Lloyd step");
         Note (abs (Step.Centers (1, 1) - C (1, 1)) < 1.0e-9
           and then abs (Step.Centers (2, 2) - C (2, 2)) < 1.0e-9,
           "Run_Lloyd's first step matches the own mean");
         Note (abs (Step.WCSS - Step.Inertia) < 1.0e-12, "inertia is WCSS");
      end;
   end;

   --  Index origin other than 1. Spaced picks rows by the published formula.
   declare
      Data : constant Dataset (5 .. 9, 2 .. 3) :=
        [[1.0, 0.0],
         [2.0, 0.0],
         [3.0, 0.0],
         [4.0, 0.0],
         [5.0, 0.0]];
      Sp : constant Centers := Init_Centers_Spaced (Data, 3);
      --  N = 5, K = 3: offset floor((j-1)*(N-1)/(K-1)) from the first row.
      Expect : constant array (1 .. 3) of Point_Index := [5, 7, 9];
   begin
      for J in 1 .. 3 loop
         Note (abs (Sp (J, Sp'First (2)) - Data (Expect (J), 2)) < 1.0e-12
           and then abs (Sp (J, Sp'Last (2)) - Data (Expect (J), 3)) < 1.0e-12,
           "spaced center is the formula's data row");
      end loop;
   end;

   --  Forgy centers are distinct rows of the data, and the seed repeats.
   declare
      Data : Dataset (1 .. 8, 1 .. 2);
      A, B : Centers (1 .. 3, 1 .. 2);
   begin
      for P in Data'Range (1) loop
         Data (P, 1) := R (-2.0, 2.0);
         Data (P, 2) := R (-2.0, 2.0);
      end loop;
      A := Init_Centers_Forgy (Data, 3, Natural (Seed mod 1000) + 1);
      B := Init_Centers_Forgy (Data, 3, Natural (Seed mod 1000) + 1);
      for J in 1 .. 3 loop
         declare
            Seen : Boolean := False;
         begin
            for P in Data'Range (1) loop
               if abs (A (J, 1) - Data (P, 1)) < 1.0e-12
                 and then abs (A (J, 2) - Data (P, 2)) < 1.0e-12
               then
                  Seen := True;
               end if;
            end loop;
            Note (Seen, "Forgy center is a data row");
         end;
         for I in 1 .. J - 1 loop
            Note (abs (A (J, 1) - A (I, 1)) > 1.0e-12
              or else abs (A (J, 2) - A (I, 2)) > 1.0e-12,
              "Forgy centers are distinct rows");
         end loop;
         Note (abs (A (J, 1) - B (J, 1)) < 1.0e-12,
           "Forgy repeats for the same seed");
      end loop;
   end;

   --  A full run's centers are the means of the labels it reports,
   --  and WCSS is the own sum of squared distances to those means.
   for Trial in 1 .. 6 loop
      declare
         Data : Dataset (1 .. 12, 1 .. 2);
         Init : Centers (1 .. 2, 1 .. 2);
         Params : constant Parameters :=
           (K => 2, Max_Iters => 30, Tol => 1.0e-8, Seed => 1);
         Fit : Result (12, 2, 2);
         Sum : array (1 .. 2, 1 .. 2) of Real := [others => [others => 0.0]];
         Count : array (1 .. 2) of Natural := [others => 0];
         SSE : Real := 0.0;
      begin
         for P in 1 .. 6 loop
            Data (P, 1) := R (-0.4, 0.4);
            Data (P, 2) := R (-0.4, 0.4);
            Data (P + 6, 1) := 4.0 + R (-0.4, 0.4);
            Data (P + 6, 2) := 4.0 + R (-0.4, 0.4);
         end loop;
         Init := [[Data (1, 1), Data (1, 2)], [Data (7, 1), Data (7, 2)]];
         Fit := Run_Lloyd (Data, Init, Params);
         for P in 1 .. 12 loop
            declare
               K : constant Positive := Positive (Fit.Lab (P));
            begin
               Count (K) := Count (K) + 1;
               Sum (K, 1) := Sum (K, 1) + Data (P, 1);
               Sum (K, 2) := Sum (K, 2) + Data (P, 2);
            end;
         end loop;
         for K in 1 .. 2 loop
            if Count (K) > 0 then
               Note (abs (Fit.Centers (K, 1) - Sum (K, 1) / Real (Count (K))) < 1.0e-8,
                 "fitted center is the own mean of its points");
               Note (abs (Fit.Centers (K, 2) - Sum (K, 2) / Real (Count (K))) < 1.0e-8,
                 "fitted center y is the own mean");
            end if;
         end loop;
         for P in 1 .. 12 loop
            declare
               K : constant Site_Index := Site_Index (Fit.Lab (P));
               Dx : constant Real := Data (P, 1) - Fit.Centers (K, 1);
               Dy : constant Real := Data (P, 2) - Fit.Centers (K, 2);
            begin
               SSE := SSE + Dx * Dx + Dy * Dy;
            end;
         end loop;
         Note (abs (Fit.WCSS - SSE) < 1.0e-6, "WCSS matches the own sum of squares");
         Note (Fit.Converged, "separated blobs converge");
      end;
   end loop;

   --  One point, one cluster: N < 1 and K < 1 must stay strict.
   declare
      Data : constant Dataset := [[4.0, 5.0]];
      Sp : constant Centers := Init_Centers_Spaced (Data, 1);
      Fg : constant Centers := Init_Centers_Forgy (Data, 1, 1);
      Params : constant Parameters :=
        (K => 1, Max_Iters => 5, Tol => 1.0e-9, Seed => 1);
      Fit : constant Result := Run_Lloyd (Data, Sp, Params);
   begin
      Note (abs (Sp (1, 1) - 4.0) < 1.0e-12, "spaced K=1 uses the only row");
      Note (abs (Fg (1, 1) - 4.0) < 1.0e-12, "Forgy K=1 uses the only row");
      Note (Fit.Iters >= 1 and then abs (Fit.Centers (1, 1) - 4.0) < 1.0e-9,
        "Lloyd accepts a single point");
   end;

   --  Column origin is not 1. Extract and a Lloyd init must follow it.
   declare
      Data : constant Dataset (4 .. 6, 3 .. 4) :=
        [[9.0, 8.0],
         [7.0, 6.0],
         [5.0, 4.0]];
      Pt : constant Point := Extract_Point (Data, 5);
      Init : constant Centers (2 .. 2, 5 .. 6) := [[7.0, 6.0]];
      Params : constant Parameters :=
        (K => 1, Max_Iters => 4, Tol => 1.0e-9, Seed => 1);
      Fit : constant Result := Run_Lloyd (Data, Init, Params);
   begin
      Note (abs (Pt (1) - 7.0) < 1.0e-12 and then abs (Pt (2) - 6.0) < 1.0e-12,
        "extract follows a column origin other than 1");
      Note (abs (Fit.Centers (1, 1) - 7.0) < 1.0e-6
        and then abs (Fit.Centers (1, 2) - 6.0) < 1.0e-6,
        "Lloyd init follows a column origin other than 1");
   end;

   --  Forgy's first draw, from the Numerical Recipes LCG, not the package RNG.
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [2.0, 0.0],
         [3.0, 0.0]];
      S : U32 := 3 * 1664525 + 1013904223;
      U : Real;
      Off : Natural;
      Fg : constant Centers := Init_Centers_Forgy (Data, 1, 3);
   begin
      S := S * 1664525 + 1013904223;
      U := Real (Long_Float (S) / 4294967296.0);
      Off := Natural (Long_Float (U) * 4.0);
      if Off >= 4 then
         Off := 3;
      end if;
      Note (abs (Fg (1, 1) - Real (Off)) < 1.0e-9,
        "Forgy seed 3 picks the LCG row");
   end;

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
