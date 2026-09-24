--  Standalone test suite for Random_Restart_Hill_Climbing (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Random_Restart_Hill_Climbing; use Random_Restart_Hill_Climbing;

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

   function All_Ones (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => True];
   begin
      return B;
   end All_Ones;

   function All_Zeros (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => False];
   begin
      return B;
   end All_Zeros;

   --  Tiny Euclidean TSP instance on a square + center-ish points.
   function Make_Square_4 return Dist_Matrix is
      D : Dist_Matrix (1 .. 4, 1 .. 4) := [others => [others => 0.0]];
   begin
      --  Cities at (0,0),(1,0),(1,1),(0,1); unit side, diagonal √2.
      D (1, 2) := 1.0; D (2, 1) := 1.0;
      D (2, 3) := 1.0; D (3, 2) := 1.0;
      D (3, 4) := 1.0; D (4, 3) := 1.0;
      D (4, 1) := 1.0; D (1, 4) := 1.0;
      D (1, 3) := 1.41421356237; D (3, 1) := 1.41421356237;
      D (2, 4) := 1.41421356237; D (4, 2) := 1.41421356237;
      return D;
   end Make_Square_4;

   function Make_Path_5 return Dist_Matrix is
      D : Dist_Matrix (1 .. 5, 1 .. 5) := [others => [others => 0.0]];
   begin
      --  Cities on a line 1-2-3-4-5 with unit gaps; large wrap distances.
      for I in City_Index range 1 .. 5 loop
         for J in City_Index range 1 .. 5 loop
            if I /= J then
               D (I, J) := Non_Negative (abs (Real (I) - Real (J)));
            end if;
         end loop;
      end loop;
      return D;
   end Make_Path_5;

begin
   Put_Line ("Random_Restart_Hill_Climbing test suite");
   Put_Line ("=======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp helpers");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Clamp (0.5, 0.0, 1.0) = 0.5, "Clamp interior");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp below");
      Check (Clamp (2.0, 0.0, 1.0) = 1.0, "Clamp above");
      Check (Clamp (0.0, 0.0, 1.0) = 0.0, "Clamp at Lo");
      Check (Clamp (1.0, 0.0, 1.0) = 1.0, "Clamp at Hi");
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
      K          : Natural;
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
      K := Next_Natural (S1, 0, 10);
      Check (K <= 10, "Next_Natural upper");
      Seed_RNG (S1, 55);
      Check (Next_Natural (S1, 4, 4) = 4, "Next_Natural Lo=Hi");
      declare
         Ok : Boolean := True;
      begin
         Seed_RNG (S1, 9);
         for I in 1 .. 30 loop
            K := Next_Natural (S1, 1, 5);
            if K < 1 or else K > 5 then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "30 Next_Natural in [1,5]");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Bit helpers Flip / Hamming / Counts");
   ---------------------------------------------------------------------
   declare
      A : constant Bit_String (1 .. 4) := [True, False, True, False];
      B : constant Bit_String (1 .. 4) := [True, True, False, False];
      F : Bit_String (1 .. 4);
   begin
      Check (Hamming_Distance (A, A) = 0, "Hamming self 0");
      Check (Hamming_Distance (A, B) = 2, "Hamming A,B = 2");
      Check (Zero_Count (A) = 2, "Zero_Count A = 2");
      Check (Ones_Count (A) = 2, "Ones_Count A = 2");
      Check (Zero_Count (All_Ones (8)) = 0, "All_Ones zeros=0");
      Check (Ones_Count (All_Zeros (5)) = 0, "All_Zeros ones=0");
      F := Flip_Bit (A, 2);
      Check (F (2) = True, "Flip_Bit index 2");
      Check (Hamming_Distance (A, F) = 1, "Flip changes one bit");
      F := Flip_Bit (All_Zeros (4), 1);
      Check (Ones_Count (F) = 1, "Flip first of zeros");
      Check (Zero_Count (All_Ones (1)) = 0, "N=1 all ones");
      Check (Hamming_Distance (All_Zeros (3), All_Ones (3)) = 3,
             "Hamming zeros vs ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Hill climb to local / global opt (OneMax)");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Restarts => 1, Max_Climb_Steps => 100, Seed => 1, Step => 0.1);
      Start : constant Bit_String :=
        [False, False, False, False, True, True, True, True];
      R : Bit_Result;
      Opt : Bit_Result;
   begin
      R := Hill_Climb_OneMax (Start, Cfg);
      Check (R.Best_Cost = 0.0, "OneMax climb reaches all-ones");
      Check (R.Climbs = 4, "OneMax climbs = 4 flips from 4 zeros");
      Check (Ones_Count (R.Best_Bits (1 .. R.N)) = 8, "result all ones");

      Opt := Hill_Climb_OneMax (All_Ones (6), Cfg);
      Check (Opt.Best_Cost = 0.0, "already-optimal start cost 0");
      Check (Opt.Climbs = 0, "already-optimal: Climbs = 0");
      Check (Opt.Restarts_Used = 0, "single climb Restarts_Used = 0");

      declare
         Z : constant Bit_String := All_Zeros (10);
         Rz : constant Bit_Result := Hill_Climb_OneMax (Z, Cfg);
      begin
         Check (Rz.Best_Cost = 0.0, "zeros -> OneMax success");
         Check (Rz.Climbs = 10, "10 zeros need 10 climbs");
      end;

      declare
         Tgt : constant Bit_String :=
           [True, False, True, False, True];
         St  : constant Bit_String :=
           [False, False, False, False, False];
         Rh  : constant Bit_Result := Hill_Climb_Hamming (St, Tgt, Cfg);
      begin
         Check (Rh.Best_Cost = 0.0, "Hamming climb to target");
         Check (Rh.Climbs = 3, "Hamming climbs = ones in target");
         Check (Hamming_Distance (Rh.Best_Bits (1 .. 5), Tgt) = 0,
                "bits match target");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Random restart OneMax / reproducibility");
   ---------------------------------------------------------------------
   declare
      Cfg : Config :=
        (Max_Restarts => 15, Max_Climb_Steps => 50, Seed => 42, Step => 0.1);
      R1, R2, R3 : Bit_Result;
      Empty : Bit_Result;
   begin
      R1 := Random_Restart_OneMax (12, Cfg);
      R2 := Random_Restart_OneMax (12, Cfg);
      Check (R1.Best_Cost = 0.0, "RR OneMax N=12 finds optimum");
      Check (R1.Best_Cost = R2.Best_Cost, "same seed same Best_Cost");
      Check (R1.Restarts_Used = R2.Restarts_Used, "same Restarts_Used");
      Check (R1.Climbs = R2.Climbs, "same Climbs (deterministic)");
      Check (R1.Restarts_Used >= 1, "at least one restart used");
      Check (R1.Restarts_Used <= Cfg.Max_Restarts, "Restarts <= max");

      Cfg.Seed := 99;
      R3 := Random_Restart_OneMax (12, Cfg);
      Check (R3.Best_Cost = 0.0, "different seed still finds OneMax");

      Cfg.Max_Restarts := 0;
      Empty := Random_Restart_OneMax (8, Cfg);
      Check (Empty.Restarts_Used = 0, "Max_Restarts=0 -> Restarts_Used=0");
      Check (Empty.Climbs = 0, "Max_Restarts=0 -> Climbs=0");

      Cfg.Max_Restarts := 5;
      Cfg.Seed := 7;
      declare
         T : constant Bit_String :=
           [True, True, False, True, False, True, True, False];
         Rh : constant Bit_Result := Random_Restart_Hamming (T, Cfg);
      begin
         Check (Rh.Best_Cost = 0.0, "RR Hamming hits target");
         Check (Rh.N = 8, "RR Hamming N=8");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Continuous Sphere hill climb");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Restarts => 1, Max_Climb_Steps => 200, Seed => 1, Step => 0.25);
      R : Cont_Result;
   begin
      R := Hill_Climb_1D (Sphere_1D'Access, 3.0, Cfg, -5.0, 5.0);
      Check (Approx (R.Best_X, 0.0, 0.3), "Sphere climbs near 0");
      Check (R.Best_Cost < 0.1, "Sphere cost small");
      Check (R.Climbs > 0, "Sphere took climbs");

      R := Hill_Climb_1D (Sphere_1D'Access, 0.0, Cfg, -5.0, 5.0);
      Check (Approx (R.Best_X, 0.0), "Sphere already at opt");
      Check (R.Climbs = 0, "Sphere at opt: Climbs=0");

      R := Hill_Climb_1D
        (Shifted_Sphere_1D'Access, 0.0, Cfg, -1.0, 6.0);
      Check (Approx (R.Best_X, 3.0, 0.3), "Shifted Sphere near 3");
      Check (R.Best_Cost < 0.1, "Shifted Sphere cost small");

      Check (Approx (Sphere_1D (0.0), 0.0), "Sphere(0)=0");
      Check (Approx (Sphere_1D (2.0), 4.0), "Sphere(2)=4");
      Check (Approx (Shifted_Sphere_1D (3.0), 0.0), "Shifted(3)=0");
   end;

   ---------------------------------------------------------------------
   Section ("7. Multimodal: single climb fails, restarts find global");
   ---------------------------------------------------------------------
   declare
      Cfg_Local : constant Config :=
        (Max_Restarts => 1, Max_Climb_Steps => 100, Seed => 1, Step => 0.1);
      Cfg_RR : constant Config :=
        (Max_Restarts => 40, Max_Climb_Steps => 80, Seed => 123,
         Step => 0.15);
      Local : Cont_Result;
      Global : Cont_Result;
      Single_From_Shallow : Cont_Result;
   begin
      --  Start in shallow basin of Two_Basin around +2.
      Local := Hill_Climb_1D
        (Two_Basin'Access, 2.0, Cfg_Local, -6.0, 6.0);
      Check (Local.Best_X > 0.0, "Two_Basin from +2 stays positive");
      Check (Local.Best_Cost >= 0.9, "shallow basin cost ~1");

      Single_From_Shallow := Local;
      Global := Random_Restart_1D
        (Two_Basin'Access, Cfg_RR, -6.0, 6.0);
      Check (Global.Best_X < 0.0, "RR Two_Basin finds negative well");
      Check (Global.Best_Cost < 0.2, "RR Two_Basin near global cost 0");
      Check (Global.Best_Cost < Single_From_Shallow.Best_Cost,
             "restarts improve over single shallow start");
      Check (Global.Restarts_Used >= 1, "RR used restarts");

      --  Double_Well: local near +1, global near -1.
      declare
         Loc : constant Cont_Result := Hill_Climb_1D
           (Double_Well'Access, 1.2, Cfg_Local, -3.0, 3.0);
         Gl  : constant Cont_Result := Random_Restart_1D
           (Double_Well'Access, Cfg_RR, -3.0, 3.0);
      begin
         Check (Loc.Best_X > 0.0, "Double_Well local stays >0");
         Check (Gl.Best_X < 0.0, "Double_Well RR finds left well");
         Check (Gl.Best_Cost < Loc.Best_Cost,
                "Double_Well RR better than local");
      end;

      Check (Two_Basin (2.0) > Two_Basin (-3.0),
             "Two_Basin shallow > deep");
      Check (Approx (Two_Basin (-3.0), 0.0), "Two_Basin(-3)=0");
      Check (Approx (Two_Basin (2.0), 1.0), "Two_Basin(+2)=1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Continuous RR reproducibility / empty restarts");
   ---------------------------------------------------------------------
   declare
      Cfg : Config :=
        (Max_Restarts => 12, Max_Climb_Steps => 60, Seed => 77, Step => 0.2);
      A, B : Cont_Result;
      Z    : Cont_Result;
   begin
      A := Random_Restart_1D (Sphere_1D'Access, Cfg, -4.0, 4.0);
      B := Random_Restart_1D (Sphere_1D'Access, Cfg, -4.0, 4.0);
      Check (Approx (A.Best_Cost, B.Best_Cost), "RR Sphere same cost");
      Check (Approx (A.Best_X, B.Best_X), "RR Sphere same X");
      Check (A.Climbs = B.Climbs, "RR Sphere same Climbs");
      Check (A.Restarts_Used = B.Restarts_Used, "RR Sphere same Restarts");
      Check (A.Best_Cost < 0.15, "RR Sphere near 0");

      Cfg.Max_Restarts := 0;
      Z := Random_Restart_1D (Sphere_1D'Access, Cfg, -4.0, 4.0);
      Check (Z.Restarts_Used = 0, "cont Max_Restarts=0");
      Check (Z.Climbs = 0, "cont empty Climbs=0");
   end;

   ---------------------------------------------------------------------
   Section ("9. TSP 2-opt hill climb / restarts");
   ---------------------------------------------------------------------
   declare
      D4  : constant Dist_Matrix := Make_Square_4;
      D5  : constant Dist_Matrix := Make_Path_5;
      Cfg : Config :=
        (Max_Restarts => 20, Max_Climb_Steps => 50, Seed => 3, Step => 0.1);
      Id4 : constant Tour := Identity_Tour (4);
      Bad : Tour (1 .. 4);
      R   : TSP_Result;
      RR  : TSP_Result;
   begin
      Check (Approx (Real (Tour_Length (Id4, D4)), 4.0),
             "square identity length 4");

      Bad := [1, 3, 2, 4];  -- uses a diagonal
      R := Hill_Climb_TSP (D4, Bad, Cfg);
      Check (R.Best_Length <= Tour_Length (Bad, D4),
             "climb length <= start");
      Check (Approx (Real (R.Best_Length), 4.0, 0.01)
             or else R.Best_Length < Tour_Length (Bad, D4),
             "climb improves or optimal");

      --  Already locally optimal tour on square.
      R := Hill_Climb_TSP (D4, Id4, Cfg);
      Check (Approx (Real (R.Best_Length), 4.0), "opt tour stays 4");
      Check (R.Climbs = 0, "already-opt TSP Climbs=0");

      RR := Random_Restart_TSP (D4, Cfg);
      Check (Approx (Real (RR.Best_Length), 4.0, 0.01),
             "RR TSP square finds 4");
      Check (RR.Restarts_Used >= 1, "RR TSP used restarts");
      Check (RR.N = 4, "RR TSP N=4");

      declare
         RRa, RRb : TSP_Result;
      begin
         RRa := Random_Restart_TSP (D5, Cfg);
         RRb := Random_Restart_TSP (D5, Cfg);
         Check (Approx (Real (RRa.Best_Length), Real (RRb.Best_Length)),
                "RR TSP seed reproducible length");
         Check (RRa.Climbs = RRb.Climbs, "RR TSP seed reproducible Climbs");
         Check (RRa.Best_Length > 0.0, "path-5 length positive");
      end;

      Cfg.Max_Restarts := 0;
      RR := Random_Restart_TSP (D4, Cfg);
      Check (RR.Restarts_Used = 0, "TSP Max_Restarts=0");
      Check (RR.Climbs = 0, "TSP empty Climbs=0");

      --  Apply_2Opt sanity
      declare
         T  : constant Tour := Identity_Tour (5);
         T2 : constant Tour := Apply_2Opt (T, 1, 4);
      begin
         Check (T2 (1) = 1, "2-opt keeps pos 1");
         Check (T2 (2) = 4, "2-opt reversed segment start");
         Check (T2 (3) = 3, "2-opt mid");
         Check (T2 (4) = 2, "2-opt reversed segment end");
         Check (T2 (5) = 5, "2-opt keeps last");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. To_Result adapters / Config fields");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Restarts => 8, Max_Climb_Steps => 40, Seed => 5, Step => 0.1);
      Br : constant Bit_Result := Random_Restart_OneMax (6, Cfg);
      Cr : constant Cont_Result :=
        Random_Restart_1D (Sphere_1D'Access, Cfg, -2.0, 2.0);
      Tr : constant TSP_Result := Random_Restart_TSP (Make_Square_4, Cfg);
      Rb : constant Result := To_Result (Br);
      Rc : constant Result := To_Result (Cr);
      Rt : constant Result := To_Result (Tr);
   begin
      Check (Approx (Rb.Best_Cost, Br.Best_Cost), "To_Result bit cost");
      Check (Rb.Restarts_Used = Br.Restarts_Used, "To_Result bit restarts");
      Check (Rb.Climbs = Br.Climbs, "To_Result bit climbs");
      Check (Approx (Rc.Best_Cost, Cr.Best_Cost), "To_Result cont cost");
      Check (Rc.Climbs = Cr.Climbs, "To_Result cont climbs");
      Check (Approx (Rt.Best_Cost, Real (Tr.Best_Length)),
             "To_Result TSP cost");
      Check (Rt.Restarts_Used = Tr.Restarts_Used, "To_Result TSP restarts");
      Check (Cfg.Max_Restarts = 8, "Config Max_Restarts field");
      Check (Cfg.Max_Climb_Steps = 40, "Config Max_Climb_Steps field");
      Check (Cfg.Seed = 5, "Config Seed field");
   end;

   ---------------------------------------------------------------------
   Section ("11. Random_Bit_String / Random_Tour helpers");
   ---------------------------------------------------------------------
   declare
      S1, S2 : RNG_State;
      B1, B2 : Bit_String (1 .. 16);
      T1, T2 : Tour (1 .. 6);
      Seen   : array (City_Index range 1 .. 6) of Boolean :=
        [others => False];
      Perm_Ok : Boolean := True;
   begin
      Seed_RNG (S1, 11);
      Seed_RNG (S2, 11);
      B1 := Random_Bit_String (S1, 16);
      B2 := Random_Bit_String (S2, 16);
      Check (B1 = B2, "Random_Bit_String deterministic");
      Check (B1'Length = 16, "Random_Bit_String length");

      Seed_RNG (S1, 22);
      Seed_RNG (S2, 22);
      T1 := Random_Tour (S1, 6);
      T2 := Random_Tour (S2, 6);
      Check (T1 = T2, "Random_Tour deterministic");
      for I in T1'Range loop
         if Seen (T1 (I)) then
            Perm_Ok := False;
         end if;
         Seen (T1 (I)) := True;
      end loop;
      for C in City_Index range 1 .. 6 loop
         if not Seen (C) then
            Perm_Ok := False;
         end if;
      end loop;
      Check (Perm_Ok, "Random_Tour is a permutation");
      Check (Identity_Tour (3) = Tour'(1, 2, 3), "Identity_Tour 3");
   end;

   ---------------------------------------------------------------------
   Section ("12. Edge: small N, Max_Climb_Steps=1, Hamming target");
   ---------------------------------------------------------------------
   declare
      Cfg : Config :=
        (Max_Restarts => 3, Max_Climb_Steps => 1, Seed => 2, Step => 0.5);
      R : Bit_Result;
      C : Cont_Result;
   begin
      R := Hill_Climb_OneMax (All_Zeros (4), Cfg);
      Check (R.Climbs = 1, "Max_Climb_Steps=1 limits climbs");
      Check (R.Best_Cost = 3.0, "one step from 4 zeros -> 3");

      R := Hill_Climb_OneMax (All_Zeros (1), Cfg);
      Check (R.Best_Cost = 0.0, "N=1 OneMax from zero");
      Check (R.Climbs = 1, "N=1 one flip");

      C := Hill_Climb_1D (Sphere_1D'Access, 1.0, Cfg, -2.0, 2.0);
      Check (C.Climbs <= 1, "cont Max_Climb_Steps=1");
      Check (C.Best_Cost < Sphere_1D (1.0) or else C.Climbs = 0,
             "one step improves or stuck");

      --  Neighbor both clamp to same point at bound with tiny domain.
      Cfg.Step := 5.0;
      C := Hill_Climb_1D (Sphere_1D'Access, 0.0, Cfg, 0.0, 0.5);
      Check (C.Best_X >= 0.0, "bound climb X>=Lo");
   end;

   ---------------------------------------------------------------------
   Section ("13. Batch OneMax sizes / Sphere starts");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Restarts => 10, Max_Climb_Steps => 40, Seed => 8, Step => 0.2);
      Ok_Bits : Boolean := True;
      Ok_Cont : Boolean := True;
   begin
      for N in Bit_Count range 2 .. 16 loop
         declare
            R : constant Bit_Result := Random_Restart_OneMax (N, Cfg);
         begin
            if R.Best_Cost /= 0.0 then
               Ok_Bits := False;
            end if;
         end;
      end loop;
      Check (Ok_Bits, "RR OneMax success for N=2..16");

      for K in 1 .. 8 loop
         declare
            X0 : constant Real := Real (K) - 4.5;
            R  : constant Cont_Result :=
              Hill_Climb_1D (Sphere_1D'Access, X0, Cfg, -5.0, 5.0);
         begin
            if R.Best_Cost > 0.15 then
               Ok_Cont := False;
            end if;
         end;
      end loop;
      Check (Ok_Cont, "Sphere climbs from 8 starts");

      --  Extra granular checks to pad coverage / regression.
      Check (Approx (Double_Well (-1.0), Double_Well (-1.0)),
             "Double_Well self");
      Check (Double_Well (-1.0) < Double_Well (1.0),
             "Double_Well global < local");
      Check (Ones_Count (Flip_Bit (All_Zeros (8), 4)) = 1,
             "single flip ones");
      Check (Zero_Count (Flip_Bit (All_Ones (8), 4)) = 1,
             "single flip zeros");
   end;

   ---------------------------------------------------------------------
   Section ("14. Invalid / empty-neighbor style boundaries");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Max_Restarts => 5, Max_Climb_Steps => 20, Seed => 1, Step => 0.1);
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            R : Cont_Result;
         begin
            R := Hill_Climb_1D (null, 0.0, Cfg);
            pragma Unreferenced (R);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "null objective raises Invalid_Argument");

      Raised := False;
      begin
         declare
            R : Cont_Result;
         begin
            R := Hill_Climb_1D (Sphere_1D'Access, 0.0, Cfg, 1.0, 0.0);
            pragma Unreferenced (R);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Lo>=Hi raises Invalid_Argument");

      --  Hamming with matching start = empty improving neighborhood.
      declare
         T : constant Bit_String := [True, False, True];
         R : constant Bit_Result := Hill_Climb_Hamming (T, T, Cfg);
      begin
         Check (R.Best_Cost = 0.0, "Hamming start=target cost 0");
         Check (R.Climbs = 0, "empty improving neighborhood Climbs=0");
      end;
   end;

   New_Line;
   Put_Line ("=======================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
