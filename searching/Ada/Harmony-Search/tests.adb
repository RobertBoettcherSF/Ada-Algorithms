--  Standalone test suite for Harmony_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Harmony_Search; use Harmony_Search;

procedure Tests is

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

   function Box2 (Lo, Hi : Real) return Bounds is
      B : Bounds (1 .. 2);
   begin
      B (1) := (Lo => Lo, Hi => Hi);
      B (2) := (Lo => Lo, Hi => Hi);
      return B;
   end Box2;

   function BoxN (N : Dim_Count; Lo, Hi : Real) return Bounds is
      B : Bounds (1 .. N);
   begin
      for I in B'Range loop
         B (I) := (Lo => Lo, Hi => Hi);
      end loop;
      return B;
   end BoxN;

   function Member_Point (H : Harmony) return Point is
      P : Point (1 .. H.Dim);
   begin
      for I in 1 .. H.Dim loop
         P (I) := H.X (I);
      end loop;
      return P;
   end Member_Point;

begin
   Put_Line ("Harmony_Search test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Default_Config");
   ---------------------------------------------------------------------
   declare
      C : Config;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Clamp (0.5, 0.0, 1.0) = 0.5, "Clamp interior");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp below");
      Check (Clamp (2.0, 0.0, 1.0) = 1.0, "Clamp above");
      Check (Clamp (0.0, 0.0, 1.0) = 0.0, "Clamp at Lo");
      Check (Clamp (1.0, 0.0, 1.0) = 1.0, "Clamp at Hi");
      C := Default_Config;
      Check (C.HMS = 10, "Default HMS");
      Check (Approx (Real (C.HMCR), 0.90), "Default HMCR");
      Check (Approx (Real (C.PAR), 0.30), "Default PAR");
      Check (Approx (Real (C.BW), 0.20), "Default BW");
      Check (C.Max_Improvisations = 1_000, "Default Max_Improvisations");
      Check (C.Seed = 1, "Default Seed");
      C := Default_Config
        (HMS => 5, HMCR => 0.5, PAR => 0.1,
         BW => 0.05, Max_Improvisations => 20, Seed => 9);
      Check (C.HMS = 5 and then C.Seed = 9, "Default_Config overrides");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      X          : Real;
      N          : Natural;
      N_Ok       : Boolean := True;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (U1 = U2, "same seed -> same first draw");
      Check (U1 /= U3, "different seeds differ");
      Check (U1 >= 0.0 and then U1 < 1.0, "U in [0,1)");

      Seed_RNG (S1, 7);
      Seed_RNG (S2, 7);
      for I in 1 .. 40 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         if U1 /= U2 then
            Saw_Diff := True;
         end if;
         if U1 < 0.0 or else U1 >= 1.0 then
            All_In := False;
         end if;
      end loop;
      Check (not Saw_Diff, "same seed stream matches for 40 draws");
      Check (All_In, "40 units stay in [0,1)");

      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "Seed 0 still valid");

      Seed_RNG (S1, 123);
      X := Next_Uniform (S1, -2.0, 5.0);
      Check (X >= -2.0 and then X <= 5.0, "Next_Uniform in [Lo,Hi]");
      Seed_RNG (S1, 123);
      Check (Approx (Next_Uniform (S1, 3.0, 3.0), 3.0),
             "Next_Uniform Lo=Hi");

      Seed_RNG (S1, 55);
      for I in 1 .. 60 loop
         N := Next_Natural (S1, 1, 10);
         if N < 1 or else N > 10 then
            N_Ok := False;
         end if;
      end loop;
      Check (N_Ok, "Next_Natural in [1,10] for 60 draws");
      Seed_RNG (S1, 3);
      Check (Next_Natural (S1, 4, 4) = 4, "Next_Natural Lo=Hi");
   end;

   ---------------------------------------------------------------------
   Section ("3. Objectives Sphere / Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      Z  : constant Point (1 .. 3) := [0.0, 0.0, 0.0];
      O  : constant Point (1 .. 2) := [1.0, 1.0];
      S1 : constant Point (1 .. 2) := [1.0, 1.0];
      P  : constant Point (1 .. 2) := [0.0, 0.0];
   begin
      Check (Approx (Sphere (Z), 0.0), "Sphere at origin = 0");
      Check (Approx (Sphere (Point'(1 => 3.0)), 9.0), "Sphere (3) = 9");
      Check (Approx (Rosenbrock (O), 0.0), "Rosenbrock at (1,1) = 0");
      Check (Rosenbrock (P) > 0.0, "Rosenbrock at (0,0) > 0");
      Check (Approx (Shifted_Sphere (S1), 0.0), "Shifted_Sphere at ones");
      Check (Shifted_Sphere (Z) > 0.0, "Shifted_Sphere origin > 0");
      Check (Approx (Sphere (Point'(1 => -2.0, 2 => 1.0)), 5.0),
             "Sphere (-2,1) = 5");
      Check (Rosenbrock (Point'(1 => -1.0, 2 => 1.0)) > 0.0,
             "Rosenbrock elsewhere > 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Bit helpers");
   ---------------------------------------------------------------------
   declare
      B : constant Bit_String (1 .. 5) := [False, True, False, True, True];
      F : Bit_String (1 .. 5);
   begin
      Check (Zero_Count (B) = 2, "Zero_Count = 2");
      Check (Ones_Count (B) = 3, "Ones_Count = 3");
      Check (Zero_Count (Bit_String'(1 .. 4 => True)) = 0, "all ones zeros=0");
      Check (Ones_Count (Bit_String'(1 .. 4 => False)) = 0, "all zeros ones=0");
      F := Flip_Bit (B, 1);
      Check (F (1), "Flip_Bit index 1 is True");
      Check (F (2) = B (2) and then F (3) = B (3)
             and then F (4) = B (4) and then F (5) = B (5),
             "Flip_Bit leaves other bits");
      F := Flip_Bit (B, 2);
      Check (F (2) = False, "Flip_Bit flips index 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Init_HM / Best / Worst / cost consistency");
   ---------------------------------------------------------------------
   declare
      HM     : Harmony_Memory (8);
      State  : RNG_State;
      B      : constant Bounds := Box2 (-5.0, 5.0);
      All_In : Boolean := True;
      Costs_Ok : Boolean := True;
      Bi, Wi : Positive;
   begin
      Seed_RNG (State, 11);
      Init_HM (HM, B, Sphere'Access, State);
      Check (HM.Size = 8, "Init_HM Size = Capacity");
      Check (HM.Dim = 2, "Init_HM Dim = 2");
      for K in 1 .. HM.Size loop
         Check (HM.Members (K).Dim = 2,
                "member Dim=2 k=" & Integer'Image (K));
         if HM.Members (K).X (1) < -5.0 or else HM.Members (K).X (1) > 5.0
           or else HM.Members (K).X (2) < -5.0
           or else HM.Members (K).X (2) > 5.0
         then
            All_In := False;
         end if;
         if not Approx
           (HM.Members (K).Cost, Sphere (Member_Point (HM.Members (K))), 1.0E-9)
         then
            Costs_Ok := False;
         end if;
      end loop;
      Check (All_In, "Init_HM members inside box");
      Check (Costs_Ok, "Init_HM costs match Sphere");
      Bi := Best_Index (HM);
      Wi := Worst_Index (HM);
      Check (Bi in 1 .. HM.Size, "Best_Index in range");
      Check (Wi in 1 .. HM.Size, "Worst_Index in range");
      for K in 1 .. HM.Size loop
         Check (HM.Members (Bi).Cost <= HM.Members (K).Cost,
                "best <= member k=" & Integer'Image (K));
         Check (HM.Members (Wi).Cost >= HM.Members (K).Cost,
                "worst >= member k=" & Integer'Image (K));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Update_HM replaces worst when better");
   ---------------------------------------------------------------------
   declare
      HM    : Harmony_Memory (4);
      State : RNG_State;
      B     : constant Bounds := Box2 (-2.0, 2.0);
      Wi    : Positive;
      Cand  : Harmony;
      Old_Worst : Real;
      Old_Best  : Real;
   begin
      Seed_RNG (State, 21);
      Init_HM (HM, B, Sphere'Access, State);
      Wi := Worst_Index (HM);
      Old_Worst := HM.Members (Wi).Cost;
      Old_Best  := HM.Members (Best_Index (HM)).Cost;

      Cand.Dim  := 2;
      Cand.X    := [0.0, 0.0, others => 0.0];
      Cand.Cost := 0.0;  -- better than any typical random start
      Update_HM (HM, Cand);
      Check (HM.Members (Wi).Cost = 0.0, "Update_HM wrote over worst slot");
      Check (Approx (HM.Members (Best_Index (HM)).Cost, 0.0),
             "new best is origin");
      Check (Old_Worst >= Old_Best, "sanity worst >= best before update");

      --  Worse candidate must not replace anyone
      declare
         Before : constant Harmony_Array := HM.Members;
         Bad    : Harmony := Cand;
         Same   : Boolean := True;
      begin
         Bad.Cost := 1.0E9;
         Bad.X (1) := 1.5;
         Bad.X (2) := 1.5;
         Update_HM (HM, Bad);
         for K in 1 .. HM.Size loop
            if HM.Members (K).Cost /= Before (K).Cost then
               Same := False;
            end if;
         end loop;
         Check (Same, "worse candidate does not change HM");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Improvise stays in bounds (many draws)");
   ---------------------------------------------------------------------
   declare
      HM     : Harmony_Memory (6);
      State  : RNG_State;
      B      : constant Bounds := Box2 (-1.0, 1.0);
      Cfg    : Config := Default_Config (HMS => 6, Seed => 33);
      Cand   : Harmony;
      All_In : Boolean := True;
      Saw_Mem : Boolean := False;
   begin
      Seed_RNG (State, 33);
      Init_HM (HM, B, Sphere'Access, State);
      Cfg.HMCR := 0.85;
      Cfg.PAR  := 0.5;
      Cfg.BW   := 0.3;
      for I in 1 .. 80 loop
         Cand := Improvise (HM, B, Cfg, State);
         Check (Cand.Dim = 2, "improv Dim=2 i=" & Integer'Image (I));
         if Cand.X (1) < -1.0 or else Cand.X (1) > 1.0
           or else Cand.X (2) < -1.0 or else Cand.X (2) > 1.0
         then
            All_In := False;
         end if;
         --  With high HMCR some coords should match an HM member often
         for K in 1 .. HM.Size loop
            if Near (Cand.X (1), HM.Members (K).X (1), 1.0E-12)
              or else Near (Cand.X (2), HM.Members (K).X (2), 1.0E-12)
            then
               Saw_Mem := True;
            end if;
         end loop;
      end loop;
      Check (All_In, "80 improvisations stay in [-1,1]^2");
      Check (Saw_Mem, "HMCR sometimes copies from memory");
   end;

   ---------------------------------------------------------------------
   Section ("8. PAR / HMCR edge cases");
   ---------------------------------------------------------------------
   declare
      HM    : Harmony_Memory (5);
      State : RNG_State;
      B     : constant Bounds := Box2 (0.0, 1.0);
      Cfg   : Config := Default_Config (HMS => 5);
      Cand  : Harmony;
      All_In : Boolean := True;
      --  HMCR=0 => pure random in bounds
      --  HMCR=1, PAR=0 => exact copy of some HM coordinate (no pitch)
      Exact_Copy_Seen : Boolean := False;
   begin
      Seed_RNG (State, 44);
      Init_HM (HM, B, Sphere'Access, State);

      Cfg.HMCR := 0.0;
      Cfg.PAR  := 1.0;
      Cfg.BW   := 10.0;  -- large BW irrelevant when HMCR=0
      for I in 1 .. 30 loop
         Cand := Improvise (HM, B, Cfg, State);
         if Cand.X (1) < 0.0 or else Cand.X (1) > 1.0
           or else Cand.X (2) < 0.0 or else Cand.X (2) > 1.0
         then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "HMCR=0 improvisations stay in bounds");

      Cfg.HMCR := 1.0;
      Cfg.PAR  := 0.0;
      Cfg.BW   := 0.5;
      Seed_RNG (State, 45);
      Init_HM (HM, B, Sphere'Access, State);
      for I in 1 .. 40 loop
         Cand := Improvise (HM, B, Cfg, State);
         declare
            Match1, Match2 : Boolean := False;
         begin
            for K in 1 .. HM.Size loop
               if Near (Cand.X (1), HM.Members (K).X (1), 0.0) then
                  Match1 := True;
               end if;
               if Near (Cand.X (2), HM.Members (K).X (2), 0.0) then
                  Match2 := True;
               end if;
            end loop;
            if Match1 and then Match2 then
               Exact_Copy_Seen := True;
            end if;
            Check (Match1 and then Match2,
                   "HMCR=1 PAR=0 coords from HM i=" & Integer'Image (I));
         end;
      end loop;
      Check (Exact_Copy_Seen, "HMCR=1 PAR=0 saw full memory-sourced harmony");

      --  PAR=1 with HMCR=1 still stays in bounds after pitch adjust
      All_In := True;
      Cfg.HMCR := 1.0;
      Cfg.PAR  := 1.0;
      Cfg.BW   := 0.25;
      for I in 1 .. 40 loop
         Cand := Improvise (HM, B, Cfg, State);
         if Cand.X (1) < 0.0 or else Cand.X (1) > 1.0
           or else Cand.X (2) < 0.0 or else Cand.X (2) > 1.0
         then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "HMCR=1 PAR=1 pitch adjust stays in bounds");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize_Box Sphere improves + reproducibility");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := BoxN (3, -5.0, 5.0);
      Cfg : Config :=
        Default_Config
          (HMS => 12, HMCR => 0.9, PAR => 0.35, BW => 0.4,
           Max_Improvisations => 400, Seed => 100);
      R1, R2, R3 : Result;
      Init_Best  : Real;
      HM         : Harmony_Memory (12);
      State      : RNG_State;
   begin
      Seed_RNG (State, 100);
      Init_HM (HM, B, Sphere'Access, State);
      Init_Best := HM.Members (Best_Index (HM)).Cost;

      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Dim = 3, "Sphere Result Dim=3");
      Check (R1.Improvisations = 400, "Sphere Improvisations=400");
      Check (R1.HMS_Used = 12, "Sphere HMS_Used=12");
      Check (R1.Best_Cost < Init_Best, "Sphere improves vs initial HM best");
      Check (R1.Best_Cost < 1.0, "Sphere Best_Cost < 1");
      Check (R1.Best_X (1) >= -5.0 and then R1.Best_X (1) <= 5.0,
             "Sphere X1 in box");
      Check (R1.Best_X (2) >= -5.0 and then R1.Best_X (2) <= 5.0,
             "Sphere X2 in box");
      Check (R1.Best_X (3) >= -5.0 and then R1.Best_X (3) <= 5.0,
             "Sphere X3 in box");
      Check (Approx (R1.Best_Cost, Sphere (R1.Best_X (1 .. 3)), 1.0E-9),
             "Sphere Best_Cost matches Best_X");

      R2 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 0.0),
             "same seed -> same Best_Cost");
      Check (Near (R1.Best_X (1), R2.Best_X (1), 0.0)
             and then Near (R1.Best_X (2), R2.Best_X (2), 0.0)
             and then Near (R1.Best_X (3), R2.Best_X (3), 0.0),
             "same seed -> same Best_X");

      Cfg.Seed := 101;
      R3 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R3.Best_Cost /= R1.Best_Cost
             or else not Near (R3.Best_X (1), R1.Best_X (1), 0.0),
             "different seed usually differs");

      --  Max_Improvisations = 0 returns best of initial HM only
      Cfg.Seed := 100;
      Cfg.Max_Improvisations := 0;
      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Improvisations = 0, "zero improvisations reported");
      Check (Approx (R1.Best_Cost, Init_Best, 1.0E-9),
             "zero improv = initial HM best");
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize_Box Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := Box2 (-2.0, 2.0);
      Cfg : Config :=
        Default_Config
          (HMS => 15, HMCR => 0.95, PAR => 0.4, BW => 0.15,
           Max_Improvisations => 800, Seed => 7);
      R   : Result;
      Bs  : constant Bounds := BoxN (2, -1.0, 3.0);
   begin
      R := Minimize_Box (Rosenbrock'Access, B, Cfg);
      Check (R.Dim = 2, "Rosenbrock Dim=2");
      Check (R.Best_Cost < 10.0, "Rosenbrock Best_Cost < 10");
      Check (R.Best_X (1) >= -2.0 and then R.Best_X (1) <= 2.0,
             "Rosenbrock X in box");
      Check (R.Improvisations = 800, "Rosenbrock improvisations");

      Cfg.Max_Improvisations := 500;
      Cfg.Seed := 8;
      R := Minimize_Box (Shifted_Sphere'Access, Bs, Cfg);
      Check (R.Best_Cost < 0.5, "Shifted_Sphere Best_Cost < 0.5");
      Check (Near (R.Best_X (1), 1.0, 0.5)
             and then Near (R.Best_X (2), 1.0, 0.5),
             "Shifted_Sphere near (1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Bit HM Init / Improvise / Update / OneMax");
   ---------------------------------------------------------------------
   declare
      HM    : Bit_Harmony_Memory (10);
      State : RNG_State;
      Cfg   : Config :=
        Default_Config
          (HMS => 10, HMCR => 0.9, PAR => 0.3,
           Max_Improvisations => 300, Seed => 50);
      Cand  : Bit_Harmony;
      All_Bits_Bool : Boolean := True;
      R1, R2 : Bit_Result;
      Wi : Positive;
      Init_Best : Real;
   begin
      Seed_RNG (State, 50);
      Init_Bit_HM (HM, 12, State);
      Check (HM.Size = 10, "Init_Bit_HM Size");
      Check (HM.N = 12, "Init_Bit_HM N=12");
      for K in 1 .. HM.Size loop
         Check (HM.Members (K).N = 12, "bit member N k=" & Integer'Image (K));
         Check
           (Approx
              (HM.Members (K).Cost,
               Real (Zero_Count (HM.Members (K).Bits (1 .. 12)))),
            "bit cost=Zero_Count k=" & Integer'Image (K));
      end loop;
      Init_Best := HM.Members (Best_Bit_Index (HM)).Cost;
      Check (Init_Best >= 0.0, "Init_Bit_HM best cost >= 0");

      for I in 1 .. 50 loop
         Cand := Improvise_Bits (HM, Cfg, State);
         Check (Cand.N = 12, "improv bits N i=" & Integer'Image (I));
         --  bits are Boolean; always "valid"
         if Cand.N /= 12 then
            All_Bits_Bool := False;
         end if;
      end loop;
      Check (All_Bits_Bool, "50 bit improvisations have N=12");

      Wi := Worst_Bit_Index (HM);
      Cand.N := 12;
      Cand.Bits := [others => True];
      Cand.Cost := 0.0;
      Update_Bit_HM (HM, Cand);
      Check (Approx (HM.Members (Wi).Cost, 0.0), "Update_Bit_HM replaces worst");
      Check (Approx (HM.Members (Best_Bit_Index (HM)).Cost, 0.0),
             "bit HM best is 0 after perfect insert");

      R1 := Minimize_OneMax (16, Cfg);
      Check (R1.N = 16, "OneMax N=16");
      Check (R1.Improvisations = 300, "OneMax improvisations");
      Check (R1.HMS_Used = 10, "OneMax HMS_Used");
      Check (R1.Best_Cost < Init_Best or else R1.Best_Cost <= 4.0,
             "OneMax improves or reaches low cost");
      Check (R1.Best_Cost <= 2.0, "OneMax Best_Cost <= 2");
      Check (Zero_Count (R1.Best_Bits (1 .. 16)) =
             Natural (R1.Best_Cost),
             "OneMax Best_Cost matches zeros");

      R2 := Minimize_OneMax (16, Cfg);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 0.0),
             "OneMax seed reproducibility cost");
      declare
         Same : Boolean := True;
      begin
         for I in 1 .. 16 loop
            if R1.Best_Bits (I) /= R2.Best_Bits (I) then
               Same := False;
            end if;
         end loop;
         Check (Same, "OneMax seed reproducibility bits");
      end;

      --  HMCR/PAR edges on bits
      Cfg.HMCR := 0.0;
      Cfg.PAR  := 0.0;
      Cfg.Max_Improvisations := 100;
      Cfg.Seed := 60;
      R1 := Minimize_OneMax (8, Cfg);
      Check (R1.Best_Cost <= 8.0, "OneMax HMCR=0 still valid");
      Check (R1.N = 8, "OneMax HMCR=0 N");

      Cfg.HMCR := 1.0;
      Cfg.PAR  := 1.0;
      Cfg.Seed := 61;
      R1 := Minimize_OneMax (8, Cfg);
      Check (R1.Best_Cost <= 3.0, "OneMax HMCR=1 PAR=1 finds few zeros");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra Sphere dims / config smoke");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Cfg : Config;
   begin
      for D in Dim_Count loop
         Cfg := Default_Config
           (HMS => 8, HMCR => 0.85, PAR => 0.25, BW => 0.3,
            Max_Improvisations => 120, Seed => 200 + D);
         R := Minimize_Box (Sphere'Access, BoxN (D, -1.0, 1.0), Cfg);
         Check (R.Dim = D, "Sphere dim D=" & Dim_Count'Image (D));
         Check (R.Best_Cost < 2.0,
                "Sphere cost ok D=" & Dim_Count'Image (D));
         Check (R.Improvisations = 120,
                "Sphere iters D=" & Dim_Count'Image (D));
      end loop;
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 100)");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
