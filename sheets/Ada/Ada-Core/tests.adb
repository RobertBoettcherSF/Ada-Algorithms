--  Standalone test suite for Core_Game_Theory.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Core_Game_Theory; use Core_Game_Theory;

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
   function PC (X : Natural) return Player_Count is (Player_Count (X));
   function Pid (X : Positive) return Player_Id is (Player_Id (X));
   function W (X : Worth) return Worth is (X);

   function Vec_Near
     (A, B : Allocation; Tol : Worth := 1.0E-9) return Boolean
   is
   begin
      if A'First /= B'First or else A'Last /= B'Last then
         return False;
      end if;
      for I in A'Range loop
         if not Near (A (I), B (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   ---------------------------------------------------------------------------
   -- Exception helpers
   ---------------------------------------------------------------------------

   function Near_Raises (Tol : Worth) return Boolean is
      Unused : Boolean;
   begin
      Unused := Near (0.0, 0.0, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Raises;

   function Power2_Raises (N : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Power2 (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Power2_Raises;

   function Imputation_Raises
     (N : Natural; V : Characteristic; X : Allocation) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Imputation (N, V, X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Imputation_Raises;

   function Core_Raises
     (N : Natural; V : Characteristic; X : Allocation) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_In_Core (N, V, X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Core_Raises;

   function Excess_Raises
     (N : Natural; V : Characteristic; X : Allocation; Mask : Natural)
      return Boolean
   is
      Unused : Worth;
   begin
      Unused := Coalition_Excess (N, V, X, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Excess_Raises;

   function Miners_Point_Raises (N : Natural) return Boolean is
   begin
      declare
         Unused : constant Allocation := Miners_Core_Point (N);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Miners_Point_Raises;

   function Pair_Point_Raises (Share : Worth) return Boolean is
   begin
      declare
         Unused : constant Allocation := Pair_Gloves_Core_Point (Share);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Pair_Point_Raises;

   function Make_Miners_Raises (N : Natural) return Boolean is
   begin
      declare
         V : constant Characteristic := Make_Miners (N);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Miners_Raises;

   function Make_Majority_Raises (N : Natural) return Boolean is
   begin
      declare
         V : constant Characteristic := Make_Majority (N);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Majority_Raises;

   function Make_Unanimity_Raises (N : Natural) return Boolean is
   begin
      declare
         V : constant Characteristic := Make_Unanimity (N);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Unanimity_Raises;

   function Make_Zero_Raises (N : Natural) return Boolean is
   begin
      declare
         V : constant Characteristic := Make_Zero (N);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Zero_Raises;

   function Clear_Raises (Size : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Load_Raises (V : Characteristic) return Boolean is
      Inst : Instance;
   begin
      Load (Inst, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Raises;

   function Set_Worth_Raises
     (Size : Natural; Mask : Natural) return Boolean
   is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      Set_Worth (Inst, Mask, 1.0);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Worth_Raises;

begin
   Put_Line ("Core_Game_Theory test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Power2 / bitmask helpers");
   ---------------------------------------------------------------------
   Check (Near (W (1.0), W (1.0)), "Near equal");
   Check (Near (W (1.0), W (1.0 + 1.0E-12)), "Near tiny delta");
   Check (not Near (W (1.0), W (2.0)), "Near far");
   Check (Near_Raises (W (-1.0)), "Near negative tol raises");
   Check (Power2 (Nat (0)) = 1, "2^0");
   Check (Power2 (Nat (1)) = 2, "2^1");
   Check (Power2 (Nat (3)) = 8, "2^3");
   Check (Power2 (Nat (12)) = 4096, "2^12");
   Check (Power2_Raises (Nat (13)), "2^13 raises");
   Check (Player_Bit (Pid (1)) = 1, "bit player 1");
   Check (Player_Bit (Pid (2)) = 2, "bit player 2");
   Check (Player_Bit (Pid (3)) = 4, "bit player 3");
   Check (Bit_Count (Nat (0)) = 0, "popcount 0");
   Check (Bit_Count (Nat (7)) = 3, "popcount 7");
   Check (Bit_Count (Nat (10)) = 2, "popcount 10");
   Check (Has_Player (Nat (5), Pid (1)), "has p1 in 5");
   Check (not Has_Player (Nat (5), Pid (2)), "no p2 in 5");
   Check (Has_Player (Nat (5), Pid (3)), "has p3 in 5");
   Check (Coalition_Size (Nat (15)) = 4, "coalition size rename");

   for N in 1 .. 8 loop
      Check (Power2 (PC (N)) = 2 ** N,
             "Power2 n=" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------
   Section ("2. Sum / coalition payoff");
   ---------------------------------------------------------------------
   declare
      X : constant Allocation := [1 => 1.0, 2 => 2.0, 3 => 3.0];
   begin
      Check (Near (Sum_Allocation (X), W (6.0)), "sum 1+2+3");
      Check (Near (Coalition_Payoff (X, Nat (0)), W (0.0)), "payoff empty");
      Check (Near (Coalition_Payoff (X, Nat (1)), W (1.0)), "payoff {1}");
      Check (Near (Coalition_Payoff (X, Nat (2)), W (2.0)), "payoff {2}");
      Check (Near (Coalition_Payoff (X, Nat (4)), W (3.0)), "payoff {3}");
      Check (Near (Coalition_Payoff (X, Nat (5)), W (4.0)), "payoff {1,3}");
      Check (Near (Coalition_Payoff (X, Nat (7)), W (6.0)), "payoff N");
   end;

   ---------------------------------------------------------------------
   Section ("3. Classic gloves: unique core (0,0,1)");
   ---------------------------------------------------------------------
   declare
      V   : constant Characteristic := Make_Gloves;
      C   : constant Allocation := Gloves_Core_Point;
      Bad : constant Allocation :=
        [1 => 1.0 / 6.0, 2 => 1.0 / 6.0, 3 => 2.0 / 3.0];
      Eq  : constant Allocation :=
        [1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0];
      Exp : constant Allocation := [1 => 0.0, 2 => 0.0, 3 => 1.0];
   begin
      Check (V'Length = 8 and then V'First = 0, "gloves length");
      Check (Near (V (0), 0.0) and then Near (V (1), 0.0), "gloves singles 1");
      Check (Near (V (2), 0.0) and then Near (V (4), 0.0), "gloves singles 2");
      Check (Near (V (3), 0.0), "gloves {1,2}=0");
      Check (Near (V (5), 1.0) and then Near (V (6), 1.0), "gloves mixed");
      Check (Near (V (7), 1.0), "gloves grand");
      Check (Vec_Near (C, Exp), "gloves core point coords");
      Check (Is_Imputation (Nat (3), V, C), "gloves core is imputation");
      Check (Is_In_Core (Nat (3), V, C), "gloves core in core");
      Check (Count_Blocking (Nat (3), V, C) = 0, "gloves core no blockers");
      Check (Near (Max_Excess (Nat (3), V, C), 0.0), "gloves max excess 0");
      Check (Is_Imputation (Nat (3), V, Bad), "Shapley-like is imputation");
      Check (not Is_In_Core (Nat (3), V, Bad), "Shapley-like not in core");
      Check (Count_Blocking (Nat (3), V, Bad) > 0,
             "Shapley-like has blockers");
      Check (not Is_In_Core (Nat (3), V, Eq), "equal split not in gloves core");
      Check (Blocks (Nat (3), V, Bad, Nat (5))
               or else Blocks (Nat (3), V, Bad, Nat (6)),
             "gloves {1,3} or {2,3} blocks Shapley-like");
      Check (not Blocks (Nat (3), V, C, Nat (0)), "empty never blocks");
      Check (not Blocks (Nat (3), V, C, Nat (7)), "grand never blocks");
   end;

   ---------------------------------------------------------------------
   Section ("4. Pair gloves (Wikipedia two-player)");
   ---------------------------------------------------------------------
   declare
      V   : constant Characteristic := Make_Pair_Gloves;
      Mid : constant Allocation := Pair_Gloves_Core_Point;
      Lo  : constant Allocation := Pair_Gloves_Core_Point (5.0);
      Hi  : constant Allocation := Pair_Gloves_Core_Point (10.0);
      Bad : constant Allocation := [1 => 4.0, 2 => 11.0];
   begin
      Check (Near (V (1), 5.0) and then Near (V (2), 5.0), "pair singles");
      Check (Near (V (3), 15.0), "pair grand");
      Check (Is_In_Core (Nat (2), V, Mid), "pair mid in core");
      Check (Is_In_Core (Nat (2), V, Lo), "pair (5,10) in core");
      Check (Is_In_Core (Nat (2), V, Hi), "pair (10,5) in core");
      Check (not Is_Individually_Rational (Nat (2), V, Bad),
             "pair (4,11) not IR");
      Check (not Is_In_Core (Nat (2), V, Bad), "pair (4,11) not in core");
      Check (Pair_Point_Raises (W (4.9)), "pair share <5 raises");
      Check (Pair_Point_Raises (W (10.1)), "pair share >10 raises");
      Check (Near (Coalition_Excess (Nat (2), V, Mid, Nat (1)), 5.0 - 7.5),
             "pair excess {1}");
   end;

   ---------------------------------------------------------------------
   Section ("5. Miners even / odd");
   ---------------------------------------------------------------------
   declare
      V4  : constant Characteristic := Make_Miners (Nat (4));
      V3  : constant Characteristic := Make_Miners (Nat (3));
      C4  : constant Allocation := Miners_Core_Point (Nat (4));
      Eq3 : constant Allocation :=
        [1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0];
      Exp4 : constant Allocation :=
        [1 => 0.5, 2 => 0.5, 3 => 0.5, 4 => 0.5];
   begin
      Check (Near (V4 (0), 0.0), "miners4 empty");
      Check (Near (V4 (1), 0.0), "miners4 singleton");
      Check (Near (V4 (3), 1.0), "miners4 pair");
      Check (Near (V4 (15), 2.0), "miners4 grand floor(4/2)");
      Check (Vec_Near (C4, Exp4), "miners4 core coords");
      Check (Is_In_Core (Nat (4), V4, C4), "miners4 in core");
      Check (Count_Blocking (Nat (4), V4, C4) = 0, "miners4 no block");
      Check (Near (V3 (7), 1.0), "miners3 grand");
      Check (Is_Imputation (Nat (3), V3, Eq3), "miners3 equal is imputation");
      Check (not Is_In_Core (Nat (3), V3, Eq3), "miners3 equal not in core");
      Check (Count_Blocking (Nat (3), V3, Eq3) > 0, "miners3 has blockers");
      Check (Blocks (Nat (3), V3, Eq3, Nat (3)), "miners3 pair blocks equal");
      Check (Miners_Point_Raises (Nat (3)), "miners odd point raises");
      Check (Miners_Point_Raises (Nat (0)), "miners 0 raises");
      Check (Miners_Point_Raises (Nat (5)), "miners 5 raises");
      Check (Max_Excess (Nat (3), V3, Eq3) > 0.0, "miners3 max excess > 0");
   end;

   declare
      V2 : constant Characteristic := Make_Miners (Nat (2));
      C2 : constant Allocation := Miners_Core_Point (Nat (2));
      V6 : constant Characteristic := Make_Miners (Nat (6));
      C6 : constant Allocation := Miners_Core_Point (Nat (6));
   begin
      Check (Is_In_Core (Nat (2), V2, C2), "miners2 in core");
      Check (Is_In_Core (Nat (6), V6, C6), "miners6 in core");
      Check (Near (Sum_Allocation (C6), W (3.0)), "miners6 sum=3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Majority (odd N empty core)");
   ---------------------------------------------------------------------
   declare
      V3  : constant Characteristic := Make_Majority (Nat (3));
      Eq  : constant Allocation :=
        [1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0];
      One : constant Allocation := [1 => 1.0, 2 => 0.0, 3 => 0.0];
   begin
      Check (Near (V3 (0), 0.0), "maj empty");
      Check (Near (V3 (1), 0.0), "maj singleton");
      Check (Near (V3 (3), 1.0), "maj pair wins");
      Check (Near (V3 (7), 1.0), "maj grand");
      Check (Is_Imputation (Nat (3), V3, Eq), "maj equal imputation");
      Check (not Is_In_Core (Nat (3), V3, Eq), "maj equal not in core");
      Check (Blocks (Nat (3), V3, Eq, Nat (3)), "maj {1,2} blocks equal");
      Check (Is_Imputation (Nat (3), V3, One), "maj (1,0,0) imputation");
      Check (not Is_In_Core (Nat (3), V3, One), "maj (1,0,0) not core");
      Check (Count_Blocking (Nat (3), V3, One) > 0, "maj one blocked");
   end;

   for N in 3 .. 7 loop
      if N mod 2 = 1 then
         declare
            V : constant Characteristic := Make_Majority (PC (N));
            X : Allocation (1 .. Player_Id (N));
         begin
            for I in X'Range loop
               X (I) := 1.0 / Worth (N);
            end loop;
            Check (Is_Imputation (PC (N), V, X),
                   "maj equal imput n=" & Natural'Image (N));
            Check (not Is_In_Core (PC (N), V, X),
                   "maj equal not core n=" & Natural'Image (N));
         end;
      end if;
   end loop;

   ---------------------------------------------------------------------
   Section ("7. Unanimity / zero / additive");
   ---------------------------------------------------------------------
   declare
      Vu   : constant Characteristic := Make_Unanimity (Nat (4));
      Eu   : constant Allocation := Unanimity_Equal_Point (Nat (4));
      Zu   : constant Allocation :=
        [1 => 1.0, 2 => 0.0, 3 => 0.0, 4 => 0.0];
      Zv   : constant Characteristic := Make_Zero (Nat (3));
      Zx   : constant Allocation := [1 => 0.0, 2 => 0.0, 3 => 0.0];
      Sing : constant Allocation := [1 => 2.0, 2 => 3.0, 3 => 5.0];
      Va   : constant Characteristic := Make_Additive (Sing);
      Ca   : constant Allocation := Additive_Core_Point (Sing);
   begin
      Check (Near (Vu (0), 0.0) and then Near (Vu (15), 1.0), "unan ends");
      Check (Near (Vu (7), 0.0), "unan proper subset 0");
      Check (Is_In_Core (Nat (4), Vu, Eu), "unan equal in core");
      Check (Is_In_Core (Nat (4), Vu, Zu), "unan corner in core");
      Check (Is_In_Core (Nat (3), Zv, Zx), "zero game core {0}");
      Check (Near (Va (0), 0.0), "additive empty");
      Check (Near (Va (1), 2.0) and then Near (Va (2), 3.0), "add sing");
      Check (Near (Va (4), 5.0), "add p3");
      Check (Near (Va (7), 10.0), "add grand");
      Check (Is_In_Core (Nat (3), Va, Ca), "additive core");
      Check (Vec_Near (Ca, Sing), "additive point = singleton worths");

      declare
         Bad : Allocation := Ca;
      begin
         --  Additive games: unique imputation = core point; any transfer
         --  violates IR for the donor.
         Bad (1) := Bad (1) + 1.0;
         Bad (2) := Bad (2) - 1.0;
         Check (not Is_Individually_Rational (Nat (3), Va, Bad),
                "add perturb not IR");
         Check (not Is_Imputation (Nat (3), Va, Bad), "add perturb not imput");
         Check (not Is_In_Core (Nat (3), Va, Bad), "add perturb not core");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Equal surplus probe");
   ---------------------------------------------------------------------
   declare
      V  : constant Characteristic := Make_Pair_Gloves;
      Xs : constant Allocation := Equal_Surplus_Allocation (Nat (2), V);
      Vg : constant Characteristic := Make_Gloves;
      Xg : constant Allocation := Equal_Surplus_Allocation (Nat (3), Vg);
      Mid : constant Allocation := [1 => 7.5, 2 => 7.5];
   begin
      Check (Vec_Near (Xs, Mid), "pair equal surplus");
      Check (Is_In_Core (Nat (2), V, Xs), "pair surplus in core");
      Check (Near (Sum_Allocation (Xg), 1.0), "gloves surplus efficient");
      Check (not Is_In_Core (Nat (3), Vg, Xg),
             "gloves equal surplus not in core");
   end;

   ---------------------------------------------------------------------
   Section ("9. Excess / worst coalition diagnostics");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Gloves;
      X : constant Allocation := [1 => 0.5, 2 => 0.5, 3 => 0.0];
   begin
      Check (Is_Imputation (Nat (3), V, X), "diag imput");
      Check (Near (Coalition_Excess (Nat (3), V, X, Nat (5)), 0.5),
             "excess {1,3}=0.5");
      Check (Near (Coalition_Excess (Nat (3), V, X, Nat (6)), 0.5),
             "excess {2,3}=0.5");
      Check (Near (Coalition_Excess (Nat (3), V, X, Nat (7)), 0.0),
             "excess grand 0");
      Check (Max_Excess (Nat (3), V, X) > 0.0, "max excess positive");
      Check (Worst_Coalition (Nat (3), V, X) = 5
               or else Worst_Coalition (Nat (3), V, X) = 6,
             "worst is a mixed pair");
      Check (Count_Blocking (Nat (3), V, X) >= 2, "at least two blockers");
   end;

   ---------------------------------------------------------------------
   Section ("10. Instance builder");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      V    : constant Characteristic := Make_Gloves;
      C    : constant Allocation := Gloves_Core_Point;
      Bad1 : constant Characteristic := [1 => 0.0, 2 => 0.0];
      Bad2 : constant Characteristic := [0 => 0.0, 1 => 0.0, 2 => 0.0];
   begin
      Clear (Inst, Nat (3));
      Check (Size (Inst) = 3, "instance size 3");
      Check (Near (Get_Worth (Inst, Nat (0)), 0.0), "clear zeros");
      Load (Inst, V);
      Check (Near (Grand_Worth (Inst), 1.0), "grand worth");
      Check (Is_Imputation (Inst, C), "inst imputation");
      Check (Is_In_Core (Inst, C), "inst in core");
      Check (Near (Coalition_Excess (Inst, C, Nat (5)), 0.0),
             "inst excess {1,3}");
      Set_Worth (Inst, Nat (3), 0.5);
      Check (Near (Get_Worth (Inst, Nat (3)), 0.5), "set worth");
      Clear (Inst, Nat (0));
      Check (Size (Inst) = 0, "clear to empty");
      Check (Clear_Raises (Nat (13)), "clear >Max_N raises");
      Check (Load_Raises (Bad1), "load non-0-based raises");
      Check (Load_Raises (Bad2), "load non-power2 raises");
      Check (Set_Worth_Raises (Nat (2), Nat (4)), "set OOB raises");
      Check (Set_Worth_Raises (Nat (0), Nat (0)), "set on empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid arguments / edge cases");
   ---------------------------------------------------------------------
   declare
      V     : constant Characteristic := Make_Gloves;
      X     : constant Allocation := Gloves_Core_Point;
      Bad_X : constant Allocation := [1 => 0.0, 2 => 1.0];
      Bad_V : constant Characteristic := [0 => 0.0, 1 => 1.0];
   begin
      Check (Imputation_Raises (Nat (0), V, X), "N=0 raises");
      Check (Imputation_Raises (Nat (3), V, Bad_X), "alloc size raises");
      Check (Core_Raises (Nat (3), Bad_V, X), "bad V length raises");
      Check (Excess_Raises (Nat (3), V, X, Nat (8)), "mask OOB raises");
      Check (Make_Miners_Raises (Nat (0)), "Make_Miners 0");
      Check (Make_Majority_Raises (Nat (0)), "Make_Majority 0");
      Check (Make_Unanimity_Raises (Nat (13)), "Make_Unanimity 13");
      Check (Make_Zero_Raises (Nat (13)), "Make_Zero 13");
   end;

   ---------------------------------------------------------------------
   Section ("12. Efficiency / IR helpers");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Pair_Gloves;
      X : constant Allocation := [1 => 7.0, 2 => 8.0];
      Y : constant Allocation := [1 => 7.0, 2 => 7.0];
      Z : constant Allocation := [1 => 4.0, 2 => 11.0];
   begin
      Check (Is_Efficient (X, W (15.0)), "efficient 7+8");
      Check (not Is_Efficient (Y, W (15.0)), "not efficient 7+7");
      Check (Is_Individually_Rational (Nat (2), V, X), "IR ok");
      Check (not Is_Individually_Rational (Nat (2), V, Z), "IR fail");
      Check (Is_Imputation (Nat (2), V, X), "imputation ok");
      Check (not Is_Imputation (Nat (2), V, Y), "imputation fail eff");
      Check (not Is_Imputation (Nat (2), V, Z), "imputation fail IR");
   end;

   ---------------------------------------------------------------------
   Section ("13. Batch: unanimity corners for N=1..4");
   ---------------------------------------------------------------------
   for N in 1 .. 4 loop
      declare
         V : constant Characteristic := Make_Unanimity (PC (N));
         E : constant Allocation := Unanimity_Equal_Point (PC (N));
      begin
         Check (Is_In_Core (PC (N), V, E),
                "unan equal core n=" & Natural'Image (N));
         for K in 1 .. N loop
            declare
               X : Allocation (1 .. Player_Id (N)) := [others => 0.0];
            begin
               X (Player_Id (K)) := 1.0;
               Check (Is_In_Core (PC (N), V, X),
                      "unan corner k=" & Natural'Image (K)
                      & " n=" & Natural'Image (N));
            end;
         end loop;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("14. Batch: additive games N=1..5");
   ---------------------------------------------------------------------
   for N in 1 .. 5 loop
      declare
         Sing : Allocation (1 .. Player_Id (N));
         V    : Characteristic (0 .. Power2 (PC (N)) - 1);
         C    : Allocation (1 .. Player_Id (N));
      begin
         for I in Sing'Range loop
            Sing (I) := Worth (Natural (I));
         end loop;
         V := Make_Additive (Sing);
         C := Additive_Core_Point (Sing);
         Check (Is_In_Core (PC (N), V, C),
                "additive core n=" & Natural'Image (N));
         Check (Near (Sum_Allocation (C), V (Power2 (PC (N)) - 1)),
                "additive efficient n=" & Natural'Image (N));
         if N >= 2 then
            declare
               Bad : Allocation := C;
            begin
               Bad (1) := Bad (1) + 0.25;
               Bad (2) := Bad (2) - 0.25;
               Check (not Is_In_Core (PC (N), V, Bad),
                      "additive transfer out n=" & Natural'Image (N));
            end;
         end if;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("15. Batch: miners even cores N=2..8");
   ---------------------------------------------------------------------
   for N in 2 .. 8 loop
      if N mod 2 = 0 then
         declare
            V : constant Characteristic := Make_Miners (PC (N));
            C : constant Allocation := Miners_Core_Point (PC (N));
         begin
            Check (Is_In_Core (PC (N), V, C),
                   "miners core n=" & Natural'Image (N));
            Check (Near (Max_Excess (PC (N), V, C), 0.0),
                   "miners maxexc=0 n=" & Natural'Image (N));
         end;
      else
         Check (Miners_Point_Raises (PC (N)),
                "miners odd raises n=" & Natural'Image (N));
      end if;
   end loop;

   ---------------------------------------------------------------------
   Section ("16. Batch: zero games");
   ---------------------------------------------------------------------
   for N in 1 .. 4 loop
      declare
         V : constant Characteristic := Make_Zero (PC (N));
         X : constant Allocation (1 .. Player_Id (N)) := [others => 0.0];
      begin
         Check (Is_In_Core (PC (N), V, X),
                "zero core n=" & Natural'Image (N));
         if N >= 2 then
            declare
               Y : Allocation (1 .. Player_Id (N)) := [others => 0.0];
            begin
               Y (1) := 1.0;
               Y (2) := -1.0;
               Check (not Is_Imputation (PC (N), V, Y),
                      "zero nonzero not imput n=" & Natural'Image (N));
            end;
         end if;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("17. Batch: bitmask consistency");
   ---------------------------------------------------------------------
   for N in 1 .. 6 loop
      declare
         All_M : constant Natural := Power2 (PC (N)) - 1;
      begin
         Check (Has_Player (All_M, Pid (1)),
                "grand has p1 n=" & Natural'Image (N));
         Check (Has_Player (All_M, Player_Id (N)),
                "grand has pN n=" & Natural'Image (N));
         Check (not Has_Player (Nat (0), Pid (1)),
                "empty no p1 n=" & Natural'Image (N));
         Check (Bit_Count (All_M) = N,
                "grand popcount n=" & Natural'Image (N));
      end;
   end loop;

   declare
      Mask : Natural := 0;
   begin
      while Mask <= 255 loop
         declare
            C : constant Natural := Bit_Count (Nat (Mask));
            R : Natural := 0;
            M : Natural := Mask;
         begin
            while M > 0 loop
               R := R + (M mod 2);
               M := M / 2;
            end loop;
            Check (C = R, "popcount ref m=" & Natural'Image (Mask));
         end;
         Mask := Mask + 8;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("18. Batch: equal-surplus on additive = core");
   ---------------------------------------------------------------------
   for N in 1 .. 5 loop
      declare
         Sing : Allocation (1 .. Player_Id (N));
         V    : Characteristic (0 .. Power2 (PC (N)) - 1);
         Xs   : Allocation (1 .. Player_Id (N));
      begin
         for I in Sing'Range loop
            Sing (I) := Worth (10 + Natural (I));
         end loop;
         V  := Make_Additive (Sing);
         Xs := Equal_Surplus_Allocation (PC (N), V);
         Check (Vec_Near (Xs, Sing),
                "surplus=solo additive n=" & Natural'Image (N));
         Check (Is_In_Core (PC (N), V, Xs),
                "surplus in additive core n=" & Natural'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("19. Micro: Is_Efficient tol / Near batch");
   ---------------------------------------------------------------------
   for K in 0 .. 8 loop
      declare
         A : constant Worth := Worth (K);
         B : constant Worth := Worth (K) + 1.0E-12;
         X : constant Allocation := [1 => A, 2 => 0.0];
      begin
         Check (Near (A, B), "near micro k=" & Natural'Image (K));
         Check (Is_Efficient (X, A, W (1.0E-6)),
                "eff micro k=" & Natural'Image (K));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("20. Micro: Player_Bit powers");
   ---------------------------------------------------------------------
   declare
      Samples : constant array (Positive range <>) of Player_Id :=
        [1, 2, 8, Player_Id (Max_N)];
   begin
      for I of Samples loop
         Check (Player_Bit (I) = 2 ** (Natural (I) - 1),
                "Player_Bit i=" & Player_Id'Image (I));
      end loop;
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
