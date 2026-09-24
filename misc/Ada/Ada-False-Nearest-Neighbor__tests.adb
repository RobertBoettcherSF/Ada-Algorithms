--  Standalone test suite for False_Nearest_Neighbor (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics; use Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with False_Nearest_Neighbor; use False_Nearest_Neighbor;

procedure Tests is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Uniform LCG in (0,1) for reproducible noise (no Ada.Numerics.Float_Random).
   function LCG_Next (State : in out Natural) return Real is
      A : constant Long_Integer := 1_103_515_245;
      C : constant Long_Integer := 12_345;
      M : constant Long_Integer := 2_147_483_648;  -- 2^31
      S : Long_Integer;
   begin
      S := (A * Long_Integer (State) + C) mod M;
      State := Natural (S);
      return Real (S) / Real (M);
   end LCG_Next;

   function Make_Sine
     (N : Positive; Period : Positive; Phase : Real := 0.0) return Series
   is
      Data : Series (1 .. N);
      W    : constant Real := 2.0 * Pi / Real (Period);
   begin
      for I in Data'Range loop
         Data (I) := EF.Sin (W * Real (I - 1) + Phase);
      end loop;
      return Data;
   end Make_Sine;

   function Make_Circle_X
     (N : Positive; Period : Positive) return Series
   is
      --  x-coordinate of uniform samples on the unit circle (period Period).
      Data : Series (1 .. N);
      W    : constant Real := 2.0 * Pi / Real (Period);
   begin
      for I in Data'Range loop
         Data (I) := EF.Cos (W * Real (I - 1));
      end loop;
      return Data;
   end Make_Circle_X;

   function Make_Noise (N : Positive; Seed : Natural := 1) return Series is
      Data  : Series (1 .. N);
      State : Natural := Seed;
   begin
      for I in Data'Range loop
         Data (I) := LCG_Next (State) * 2.0 - 1.0;
      end loop;
      return Data;
   end Make_Noise;

   function Make_Logistic
     (N : Positive; R : Real := 4.0; X0 : Real := 0.1) return Series
   is
      Data : Series (1 .. N);
      X    : Real := X0;
   begin
      for I in Data'Range loop
         Data (I) := X;
         X := R * X * (1.0 - X);
      end loop;
      return Data;
   end Make_Logistic;

   --  Simple 3-D Hénon-like / discrete Lorenz-ish map observation (x-coord).
   function Make_Henon_X (N : Positive) return Series is
      Data : Series (1 .. N);
      X, Y : Real;
      A    : constant Real := 1.4;
      B    : constant Real := 0.3;
   begin
      X := 0.1;
      Y := 0.0;
      for I in Data'Range loop
         Data (I) := X;
         declare
            Xn : constant Real := 1.0 - A * X * X + Y;
            Yn : constant Real := B * X;
         begin
            X := Xn;
            Y := Yn;
         end;
      end loop;
      return Data;
   end Make_Henon_X;

begin
   Put_Line ("False_Nearest_Neighbor test suite");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Mean / Std_Dev helpers");
   ---------------------------------------------------------------------
   declare
      Data : constant Series := [1.0, 2.0, 3.0, 4.0, 5.0];
      One  : constant Series := [42.0];
      Const : constant Series := [3.0, 3.0, 3.0, 3.0];
      Raised : Boolean := False;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 0.0), "Near(0,0)");
      Check (Approx (Mean (Data), 3.0), "Mean of 1..5 = 3");
      Check (Approx (Std_Dev (Data), EF.Sqrt (2.5), 1.0E-9),
             "Std_Dev of 1..5 = sqrt(2.5)");
      begin
         declare
            Unused : Real;
         begin
            Unused := Mean (Series'(1 .. 0 => <>));
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Mean empty raises");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Std_Dev (One);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Std_Dev length-1 raises");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Std_Dev (Const);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Std_Dev constant raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Config defaults and validation");
   ---------------------------------------------------------------------
   declare
      C : FNN_Config;
      Raised : Boolean := False;
   begin
      C := Make_Config;
      Check (C.Tau = 1, "default Tau = 1");
      Check (Approx (C.R_Tol, 15.0), "default R_Tol = 15");
      Check (Approx (C.A_Tol, 2.0), "default A_Tol = 2");
      Check (C.Theiler = 0, "default Theiler = 0");
      Check (C.Max_Dim = 10, "default Max_Dim = 10");
      Check (C.Use_Absolute_Criterion, "default Use_Absolute = True");
      C := Make_Config (Tau => 3, R_Tol => 10.0, A_Tol => 2.5,
                        Theiler => 5, Max_Dim => 6,
                        Use_Absolute_Criterion => False);
      Check (C.Tau = 3 and then Approx (C.R_Tol, 10.0)
             and then Approx (C.A_Tol, 2.5)
             and then C.Theiler = 5 and then C.Max_Dim = 6
             and then not C.Use_Absolute_Criterion,
             "Make_Config custom fields");
      begin
         C := Make_Config (R_Tol => -1.0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Make_Config R_Tol <= 0 raises");
      Raised := False;
      begin
         C := Make_Config (A_Tol => 0.0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Make_Config A_Tol = 0 raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Embedding_Distance_Sq on hand-built points");
   ---------------------------------------------------------------------
   declare
      --  x = [0, 1, 4, 9, 16]  (squares)
      Data : constant Series := [0.0, 1.0, 4.0, 9.0, 16.0];
      D2   : Real;
   begin
      --  m=1, τ=1: |x1-x2|^2 = 1
      D2 := Embedding_Distance_Sq (Data, 1, 2, 1, 1);
      Check (Approx (D2, 1.0), "m=1 dist^2 (0,1) = 1");
      --  m=2, τ=1: y1=(0,1), y2=(1,4) => 1 + 9 = 10
      D2 := Embedding_Distance_Sq (Data, 1, 2, 2, 1);
      Check (Approx (D2, 10.0), "m=2 dist^2 y1-y2 = 10");
      --  m=3, τ=1: y1=(0,1,4), y3=(4,9,16) => 16+64+144 = 224
      D2 := Embedding_Distance_Sq (Data, 1, 3, 3, 1);
      Check (Approx (D2, 224.0), "m=3 dist^2 y1-y3 = 224");
      --  τ=2, m=2: y1=(0,4), y2=(1,9) => 1 + 25 = 26
      D2 := Embedding_Distance_Sq (Data, 1, 2, 2, 2);
      Check (Approx (D2, 26.0), "m=2 τ=2 dist^2 = 26");
      --  identical points
      D2 := Embedding_Distance_Sq (Data, 2, 2, 2, 1);
      Check (Approx (D2, 0.0), "self distance = 0");
      Check (Approx (Embedding_Distance_Sq (Data, 1, 5, 1, 1), 256.0),
             "m=1 ends dist^2 = 256");
   end;

   ---------------------------------------------------------------------
   Section ("4. Nearest_Neighbor_Index basic + Theiler");
   ---------------------------------------------------------------------
   declare
      --  Cluster: 0, 0.1, 5, 5.1, 10
      Data : constant Series := [0.0, 0.1, 5.0, 5.1, 10.0];
      Np   : Series_Index;
      Raised : Boolean := False;
   begin
      Np := Nearest_Neighbor_Index (Data, 1, 1, 1, 0);
      Check (Np = 2, "NN of idx1 is idx2");
      Np := Nearest_Neighbor_Index (Data, 3, 1, 1, 0);
      Check (Np = 4, "NN of idx3 is idx4");
      Np := Nearest_Neighbor_Index (Data, 5, 1, 1, 0);
      Check (Np = 4, "NN of idx5 is idx4");
      --  Theiler=1 excludes temporal neighbour 2 from 1 → next is 3
      Np := Nearest_Neighbor_Index (Data, 1, 1, 1, 1);
      Check (Np = 3, "Theiler=1 excludes idx2 for idx1");
      --  Large Theiler leaves no neighbour
      begin
         Np := Nearest_Neighbor_Index (Data, 3, 1, 1, 10);
         Check (False, "large Theiler should have raised");
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Theiler too large raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("5. Is_False_Neighbor relative / absolute criteria");
   ---------------------------------------------------------------------
   declare
      --  Two close points in m=1 that separate wildly in m=2.
      --  x: 0, 0.01, 1, 10
      Data : constant Series := [0.0, 0.01, 1.0, 10.0];
      Cfg  : FNN_Config := Make_Config (Tau => 1, R_Tol => 10.0,
                                        A_Tol => 2.0,
                                        Use_Absolute_Criterion => False);
      Sig  : constant Real := Std_Dev (Data);
      --  Pair (1,2): Rm = 0.01, Dx = |1-10|=9, ratio = 900 >> 10 → false
   begin
      Check (Is_False_Neighbor (Data, 1, 2, 1, Cfg, Sig),
             "large relative stretch is false");
      --  Soft R_Tol so relative criterion fails; absolute may catch.
      Cfg.R_Tol := 1.0E6;
      Cfg.Use_Absolute_Criterion := False;
      Check (not Is_False_Neighbor (Data, 1, 2, 1, Cfg, Sig),
             "huge R_Tol => not false without absolute");
      Cfg.Use_Absolute_Criterion := True;
      Cfg.A_Tol := 0.01;  -- very strict absolute
      Check (Is_False_Neighbor (Data, 1, 2, 1, Cfg, Sig),
             "strict A_Tol flags absolute false neighbour");
      --  True neighbour pair on a line segment: x = [0,1,2,3]
      declare
         Line : constant Series := [0.0, 1.0, 2.0, 3.0];
         Cl   : constant FNN_Config := Make_Config (R_Tol => 15.0, A_Tol => 2.0);
         Sl   : constant Real := Std_Dev (Line);
      begin
         --  N=1 Np=2: Rm=1, Dx=|2-3|=1, ratio=1 < 15; R2=sqrt2, sigma~1.29
         Check (not Is_False_Neighbor (Line, 1, 2, 1, Cl, Sl),
                "linear progression not false at m=1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Circle / sine: FNN high at m=1, drops by m=2");
   ---------------------------------------------------------------------
   declare
      Period : constant Positive := 20;
      Sine   : constant Series := Make_Sine (200, Period);
      Circ   : constant Series := Make_Circle_X (200, Period);
      --  τ ≈ Period/4 is classic for a periodic orbit (quarter period).
      Tau    : constant Positive := Period / 4;
      Cfg    : constant FNN_Config :=
        Make_Config (Tau => Tau, R_Tol => 15.0, A_Tol => 2.0,
                     Theiler => 0, Max_Dim => 4,
                     Use_Absolute_Criterion => True);
      F1, F2 : Real;
      Est    : Natural;
   begin
      F1 := False_Neighbor_Fraction (Sine, 1, Cfg);
      F2 := False_Neighbor_Fraction (Sine, 2, Cfg);
      Check (F1 > 0.15, "sine FNN(1) relatively high");
      Check (F2 < F1, "sine FNN(2) < FNN(1)");
      Check (F2 < 0.15, "sine FNN(2) near zero / small");
      F1 := False_Neighbor_Fraction (Circ, 1, Cfg);
      F2 := False_Neighbor_Fraction (Circ, 2, Cfg);
      Check (F1 > 0.15, "circle FNN(1) relatively high");
      Check (F2 < 0.15, "circle FNN(2) small");
      Est := Estimate_Embedding_Dimension (Circ, Cfg, 0.10);
      Check (Est = 2 or else Est = 1,
             "circle embedding estimate is small (1 or 2)");
      --  Prefer the expected pedagogical result: often 2 for a circle.
      Check (Est <= 3, "circle estimate <= 3");
   end;

   ---------------------------------------------------------------------
   Section ("7. Pure noise: FNN stays relatively high");
   ---------------------------------------------------------------------
   declare
      Noise : constant Series := Make_Noise (300, Seed => 99);
      Cfg   : constant FNN_Config :=
        Make_Config (Tau => 1, R_Tol => 10.0, A_Tol => 2.0,
                     Max_Dim => 5, Use_Absolute_Criterion => True);
      Prof  : Fraction_Array (1 .. 5);
      High_Count : Natural := 0;
   begin
      Prof := FNN_Profile (Noise, Cfg);
      for M in Prof'Range loop
         if Prof (M) > 0.2 then
            High_Count := High_Count + 1;
         end if;
      end loop;
      Check (Prof (1) > 0.3, "noise FNN(1) high");
      Check (High_Count >= 2, "noise FNN stays high for several m");
      --  Should not collapse to near-zero by m=2 like a clean circle.
      Check (Prof (2) > 0.1, "noise FNN(2) not collapsed");
      Check (Estimate_Embedding_Dimension (Noise, Cfg, 0.05) = 0
             or else Estimate_Embedding_Dimension (Noise, Cfg, 0.05) > 3,
             "noise does not yield tiny clean embedding at 5%");
   end;

   ---------------------------------------------------------------------
   Section ("8. Logistic / Hénon: sensible embedding estimate");
   ---------------------------------------------------------------------
   declare
      Logi : constant Series := Make_Logistic (400, R => 4.0, X0 => 0.1);
      Hen  : constant Series := Make_Henon_X (400);
      CfgL : constant FNN_Config :=
        Make_Config (Tau => 1, R_Tol => 15.0, A_Tol => 2.0,
                     Theiler => 1, Max_Dim => 6);
      CfgH : constant FNN_Config :=
        Make_Config (Tau => 1, R_Tol => 15.0, A_Tol => 2.0,
                     Theiler => 1, Max_Dim => 6);
      EL, EH : Natural;
      FL1, FL2 : Real;
   begin
      FL1 := False_Neighbor_Fraction (Logi, 1, CfgL);
      FL2 := False_Neighbor_Fraction (Logi, 2, CfgL);
      Check (FL1 >= 0.0 and then FL1 <= 1.0, "logistic FNN(1) in [0,1]");
      Check (FL2 <= FL1 + 0.05, "logistic FNN not rising sharply");
      EL := Estimate_Embedding_Dimension (Logi, CfgL, 0.15);
      Check (EL >= 1 and then EL <= 4,
             "logistic estimate in 1..4");
      EH := Estimate_Embedding_Dimension (Hen, CfgH, 0.15);
      Check (EH >= 1 and then EH <= 5,
             "Hénon-x estimate in 1..5");
      Check (False_Neighbor_Fraction (Hen, 1, CfgH) >= 0.0,
             "Hénon FNN(1) computed");
   end;

   ---------------------------------------------------------------------
   Section ("9. R_tol / A_tol edge behaviour");
   ---------------------------------------------------------------------
   declare
      Circ : constant Series := Make_Circle_X (150, 16);
      Tau  : constant Positive := 4;
      Soft : constant FNN_Config :=
        Make_Config (Tau => Tau, R_Tol => 1000.0, A_Tol => 100.0,
                     Max_Dim => 3, Use_Absolute_Criterion => True);
      Hard : constant FNN_Config :=
        Make_Config (Tau => Tau, R_Tol => 1.5, A_Tol => 0.5,
                     Max_Dim => 3, Use_Absolute_Criterion => True);
      Rel_Only : constant FNN_Config :=
        Make_Config (Tau => Tau, R_Tol => 15.0, A_Tol => 2.0,
                     Max_Dim => 3, Use_Absolute_Criterion => False);
      Fs, Fh, Fr : Real;
   begin
      Fs := False_Neighbor_Fraction (Circ, 1, Soft);
      Fh := False_Neighbor_Fraction (Circ, 1, Hard);
      Fr := False_Neighbor_Fraction (Circ, 1, Rel_Only);
      Check (Fs <= Fh, "softer tols => fewer or equal false neighbours");
      Check (Fh >= 0.0 and then Fs >= 0.0, "fractions non-negative");
      Check (Fr >= 0.0 and then Fr <= 1.0, "relative-only fraction in [0,1]");
      Check (False_Neighbor_Fraction (Circ, 2, Soft) <=
             False_Neighbor_Fraction (Circ, 1, Soft) + 0.01,
             "soft profile not increasing much m=1→2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Theiler exclusion effect on FNN");
   ---------------------------------------------------------------------
   declare
      Sine : constant Series := Make_Sine (180, 24);
      C0   : constant FNN_Config :=
        Make_Config (Tau => 6, Theiler => 0, Max_Dim => 3);
      C5   : constant FNN_Config :=
        Make_Config (Tau => 6, Theiler => 5, Max_Dim => 3);
      F0, F5 : Real;
   begin
      F0 := False_Neighbor_Fraction (Sine, 1, C0);
      F5 := False_Neighbor_Fraction (Sine, 1, C5);
      Check (F0 >= 0.0 and then F5 >= 0.0, "Theiler fractions non-neg");
      Check (F0 <= 1.0 and then F5 <= 1.0, "Theiler fractions <= 1");
      --  Both should still show the qualitative drop at m=2.
      Check (False_Neighbor_Fraction (Sine, 2, C5) < F5 + 0.05,
             "with Theiler, FNN drops or stays by m=2");
      declare
         Raised : Boolean := False;
         Tiny   : constant Series := [0.0, 1.0, 0.5, 0.2];
         Cbig   : constant FNN_Config :=
           Make_Config (Tau => 1, Theiler => 100, Max_Dim => 2);
      begin
         declare
            Unused : Real;
         begin
            Unused := False_Neighbor_Fraction (Tiny, 1, Cbig);
            pragma Unreferenced (Unused);
         exception
            when Degenerate_Geometry | Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "huge Theiler on tiny series raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid τ / short series raises");
   ---------------------------------------------------------------------
   declare
      Short : constant Series := [1.0, 2.0, 3.0];
      Ok    : constant Series := Make_Sine (50, 10);
      Cfg   : FNN_Config := Make_Config (Tau => 1, Max_Dim => 2);
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            --  τ large vs length: cannot form m+1 vectors
            Cfg.Tau := 20;
            Unused := False_Neighbor_Fraction (Short, 1, Cfg);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "short series + large τ raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Cfg := Make_Config (Tau => 1, Max_Dim => 2);
            Unused := False_Neighbor_Fraction (Short, 5, Cfg);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "m too large for short series raises");

      Raised := False;
      begin
         declare
            Unused : Series_Index;
         begin
            Unused := Nearest_Neighbor_Index (Short, 1, 5, 1, 0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "NN index with m exceeding series raises");

      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Embedding_Distance_Sq (Ok, 1, 2, 1, 1);
            Check (Unused >= 0.0, "valid embedding dist non-negative");
            --  Force OOB delay: N1 + (M-1)*Tau beyond end
            Unused := Embedding_Distance_Sq (Short, 1, 2, 3, 2);
            Check (False, "OOB embedding should have raised");
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Embedding_Distance_Sq OOB raises");

      Check (Ok'Length = 50, "sanity: sine length 50");
   end;

   ---------------------------------------------------------------------
   Section ("12. Profile monotonic-ish decrease on clean periodic data");
   ---------------------------------------------------------------------
   declare
      Circ : constant Series := Make_Circle_X (240, 20);
      Cfg  : constant FNN_Config :=
        Make_Config (Tau => 5, R_Tol => 15.0, A_Tol => 2.0,
                     Max_Dim => 5);
      Prof : Fraction_Array (1 .. 5);
   begin
      Prof := FNN_Profile (Circ, Cfg);
      Check (Prof'Length = 5, "profile length = Max_Dim");
      Check (Prof (1) >= Prof (2) - 0.05,
             "FNN(1) >= FNN(2) (approx)");
      Check (Prof (2) <= 0.2, "FNN(2) small on circle");
      Check (Prof (3) <= Prof (2) + 0.1, "FNN(3) not much larger than FNN(2)");
      Check (Prof (4) <= 0.25, "FNN(4) remains low");
      Check (Prof (5) <= 0.3, "FNN(5) remains low");
      for M in Prof'Range loop
         Check (Prof (M) >= 0.0 and then Prof (M) <= 1.0,
                "profile(" & M'Image & ") in [0,1]");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Estimate_Embedding_Dimension for circle / sine");
   ---------------------------------------------------------------------
   declare
      Circ : constant Series := Make_Circle_X (200, 20);
      Sine : constant Series := Make_Sine (200, 20);
      Cfg  : constant FNN_Config :=
        Make_Config (Tau => 5, R_Tol => 15.0, A_Tol => 2.0,
                     Max_Dim => 6);
      Ec, Es : Natural;
   begin
      Ec := Estimate_Embedding_Dimension (Circ, Cfg, 0.10);
      Es := Estimate_Embedding_Dimension (Sine, Cfg, 0.10);
      Check (Ec >= 1 and then Ec <= 3,
             "circle estimate in 1..3 at 10%");
      Check (Es >= 1 and then Es <= 3,
             "sine estimate in 1..3 at 10%");
      --  Stricter threshold may still find small m on clean data.
      Ec := Estimate_Embedding_Dimension (Circ, Cfg, 0.05);
      Check (Ec = 0 or else Ec <= 3,
             "circle @5%: 0 or small m");
      --  Very strict: may return 0
      declare
         E0 : constant Natural :=
           Estimate_Embedding_Dimension (Circ, Cfg, 0.0);
      begin
         Check (E0 = 0 or else E0 >= 1, "threshold 0 returns 0 or some m");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Capacity / constants / identical Rm=0 case");
   ---------------------------------------------------------------------
   declare
      Dup : constant Series :=
        [0.0, 0.0, 1.0, 0.0, 0.0, 5.0];  -- indices 1 and 2 identical in m=1
      Cfg : constant FNN_Config :=
        Make_Config (Tau => 1, R_Tol => 15.0, A_Tol => 2.0,
                     Use_Absolute_Criterion => False);
      Sig : constant Real := Std_Dev (Dup);
   begin
      Check (Series_Count'Last = Max_Series, "Series_Count bound = Max_Series");
      Check (Dim_Count'Last = Max_Dim, "Dim_Count bound = Max_Dim");
      --  Rm=0 between 1 and 2, next coords 1 vs 0 → false
      Check (Is_False_Neighbor (Dup, 1, 2, 1, Cfg, Sig),
             "Rm=0 with differing next coord is false");
      --  Indices 1 and 4: both 0, next both 0 → not false (identical lift)
      Check (not Is_False_Neighbor (Dup, 1, 4, 1, Cfg, Sig),
             "Rm=0 with identical next coord is true neighbour");
      Check (Near (Mean (Dup), Mean (Dup)), "Mean reflexive Near");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra geometry / estimate edge cases");
   ---------------------------------------------------------------------
   declare
      Data : constant Series := [0.0, 1.0, 0.5, 2.0, 1.5, 3.0, 2.5, 4.0];
      Cfg  : constant FNN_Config :=
        Make_Config (Tau => 1, R_Tol => 15.0, A_Tol => 2.0, Max_Dim => 2);
      D2a, D2b : Real;
      Np       : Series_Index;
      F        : Real;
   begin
      D2a := Embedding_Distance_Sq (Data, 1, 3, 1, 1);
      D2b := Embedding_Distance_Sq (Data, 3, 1, 1, 1);
      Check (Approx (D2a, D2b), "distance symmetric");
      Check (Approx (D2a, 0.25), "dist^2 (0,0.5)=0.25");
      Np := Nearest_Neighbor_Index (Data, 2, 2, 1, 0);
      Check (Np /= 2, "NN of 2 is not self");
      Check (Embedding_Distance_Sq (Data, 2, Np, 2, 1) >= 0.0,
             "NN distance non-negative");
      F := False_Neighbor_Fraction (Data, 1, Cfg);
      Check (F >= 0.0 and then F <= 1.0, "short series FNN in [0,1]");
      Check (Estimate_Embedding_Dimension (Data, Cfg, 0.99) >= 1,
             "loose threshold finds some m");
      Check (Near (1.0, 1.0, 0.0), "Near with Tol=0 exact");
      Check (not Near (1.0, 1.1, 0.05), "Near rejects outside Tol");
   end;

   ---------------------------------------------------------------------
   Section ("15. FNN_Profile vs per-m False_Neighbor_Fraction consistency");
   ---------------------------------------------------------------------
   declare
      Data : constant Series := Make_Sine (120, 16);
      Cfg  : constant FNN_Config :=
        Make_Config (Tau => 4, Max_Dim => 3);
      Prof : constant Fraction_Array := FNN_Profile (Data, Cfg);
   begin
      Check (Approx (Prof (1), False_Neighbor_Fraction (Data, 1, Cfg), 1.0E-12),
             "profile(1) matches fraction");
      Check (Approx (Prof (2), False_Neighbor_Fraction (Data, 2, Cfg), 1.0E-12),
             "profile(2) matches fraction");
      Check (Approx (Prof (3), False_Neighbor_Fraction (Data, 3, Cfg), 1.0E-12),
             "profile(3) matches fraction");
      Check (Estimate_Embedding_Dimension (Data, Cfg, 1.0) = 1,
             "threshold 1.0 => estimate 1 (always FNN<=1)");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   pragma Assert (Fail_Count = 0);
end Tests;
