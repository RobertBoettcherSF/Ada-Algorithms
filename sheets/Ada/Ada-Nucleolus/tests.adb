--  Standalone test suite for Nucleolus.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Nucleolus; use Nucleolus;

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
     (A, B : Allocation; Tol : Worth := 1.0E-6) return Boolean
   is (Allocations_Near (A, B, Tol));

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

   function Find_Raises
     (N : Natural; V : Characteristic) return Boolean
   is
   begin
      declare
         X : constant Allocation := Find_Nucleolus (N, V);
         pragma Unreferenced (X);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

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

   function Excess_Raises
     (N : Natural; V : Characteristic; X : Allocation; Mask : Natural)
      return Boolean
   is
      Unused : Worth;
   begin
      Unused := Excess (N, V, X, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Excess_Raises;

   function Clear_Raises (Size : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Majority_Raises (N : Natural) return Boolean is
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
   end Majority_Raises;

   function Bankruptcy_Raises
     (Estate : Worth; Claims : Allocation) return Boolean
   is
   begin
      declare
         V : constant Characteristic := Make_Bankruptcy (Estate, Claims);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Bankruptcy_Raises;

   function Airport_Raises (Costs : Allocation) return Boolean is
   begin
      declare
         V : constant Characteristic := Make_Airport (Costs);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Airport_Raises;

   function Lex_Raises
     (A, B : Excess_Vector) return Boolean
   is
      Unused : Lex_Order;
   begin
      Unused := Lex_Compare (A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Lex_Raises;

begin
   Put_Line ("Nucleolus Ada 2023 — test suite");
   Put_Line ("Schmeidler excess e(S,x)=v(S)-sum x_i; leximin of sorted e");

   ---------------------------------------------------------------------
   Section ("1. Bitmask / Near / Power2");
   ---------------------------------------------------------------------
   Check (Player_Bit (Pid (1)) = Nat (1), "Player_Bit 1");
   Check (Player_Bit (Pid (3)) = Nat (4), "Player_Bit 3");
   Check (Bit_Count (Nat (0)) = Nat (0), "Bit_Count 0");
   Check (Bit_Count (Nat (7)) = Nat (3), "Bit_Count 7");
   Check (Bit_Count (Nat (10)) = Nat (2), "Bit_Count 10");
   Check (Has_Player (Nat (5), Pid (1)), "Has_Player 5 has 1");
   Check (not Has_Player (Nat (5), Pid (2)), "Has_Player 5 no 2");
   Check (Has_Player (Nat (5), Pid (3)), "Has_Player 5 has 3");
   Check (Coalition_Size (Nat (6)) = Nat (2), "Coalition_Size rename");
   Check (Power2 (Nat (0)) = Nat (1), "Power2 0");
   Check (Power2 (Nat (3)) = Nat (8), "Power2 3");
   Check (Power2 (Nat (8)) = Nat (256), "Power2 Max_N");
   Check (Power2_Raises (Nat (9)), "Power2 >Max_N raises");
   Check (Near (W (1.0), W (1.0 + 1.0E-12)), "Near close");
   Check (not Near (W (1.0), W (1.1), W (0.01)), "Near far");
   Check (Near_Raises (W (-1.0)), "Near negative tol raises");

   ---------------------------------------------------------------------
   Section ("2. Sums / imputation helpers");
   ---------------------------------------------------------------------
   declare
      X : constant Allocation (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Characteristic := Make_Additive (X);
   begin
      Check (Near (Sum_Allocation (X), W (6.0)), "Sum_Allocation");
      Check (Near (Coalition_Payoff (X, Nat (5)), W (4.0)),
             "Coalition_Payoff {1,3}");
      Check (Is_Efficient (X, W (6.0)), "Is_Efficient");
      Check (Is_Individually_Rational (PC (3), V, X), "IR additive");
      Check (Is_Imputation (PC (3), V, X), "imputation additive");
      Check (Imputation_Set_Nonempty (PC (3), V), "imp set nonempty");
   end;

   declare
      V : constant Characteristic := Make_Gloves;
      Bad : constant Allocation (1 .. 3) := [0.5, 0.5, 0.5];
      Good : constant Allocation (1 .. 3) := [0.0, 0.0, 1.0];
   begin
      Check (Is_Imputation (PC (3), V, Good), "gloves imputation");
      Check (not Is_Imputation (PC (3), V, Bad), "gloves not efficient");
   end;

   ---------------------------------------------------------------------
   Section ("3. Excess Schmeidler sign");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Gloves;
      X : constant Allocation (1 .. 3) := [0.0, 0.0, 1.0];
   begin
      --  e({1,3},x) = v({1,3}) - (x1+x3) = 1 - 1 = 0
      Check (Near (Excess (PC (3), V, X, Nat (5)), W (0.0)),
             "excess {1,3} at nucleolus");
      --  e({1,2},x) = 0 - 0 = 0
      Check (Near (Excess (PC (3), V, X, Nat (3)), W (0.0)),
             "excess {1,2} at nucleolus");
      Check (Near (Excess (PC (3), V, X, Nat (0)), W (0.0)),
             "excess empty");
      Check (Near (Excess (PC (3), V, X, Nat (7)), W (0.0)),
             "excess grand");
      Check (Near (Max_Excess (PC (3), V, X), W (0.0)),
             "max excess gloves nucleolus = 0 (in core)");
   end;

   declare
      V : constant Characteristic := Make_Gloves;
      X : constant Allocation (1 .. 3) := [0.5, 0.5, 0.0];
   begin
      --  e({3},x) = 0 - 0 = 0; e({1,3})=1-(0.5+0)=0.5 > 0 unhappy
      Check (Near (Excess (PC (3), V, X, Nat (5)), W (0.5)),
             "positive excess = unhappy coalition");
      Check (Max_Excess (PC (3), V, X) > W (0.0),
             "max excess positive off-core");
   end;

   ---------------------------------------------------------------------
   Section ("4. Sorted excess + Lex_Compare");
   ---------------------------------------------------------------------
   declare
      A : Excess_Vector (0 .. 3) := [3.0, 1.0, 2.0, 0.0];
      B : Excess_Vector (0 .. 3) := [2.5, 2.0, 1.0, 0.0];
      C : Excess_Vector (0 .. 3) := [3.0, 1.0, 2.0, 0.0];
   begin
      --  Manual: after sort nonincreasing A becomes 3,2,1,0
      declare
         V : constant Characteristic := Make_Zero (PC (2));
         X : constant Allocation (1 .. 2) := [0.0, 0.0];
         S : constant Excess_Vector :=
           Sorted_Excess_Vector (PC (2), V, X);
      begin
         Check (S'Length = Nat (4), "sorted length 2^2");
         Check (S (S'First) >= S (S'First + 1), "nonincreasing 0>=1");
         Check (S (S'First + 1) >= S (S'First + 2), "nonincreasing 1>=2");
         Check (S (S'First + 2) >= S (S'Last), "nonincreasing 2>=3");
      end;
      pragma Unreferenced (A, B, C);
   end;

   declare
      Left  : constant Excess_Vector (1 .. 3) := [1.0, 0.0, -1.0];
      Right : constant Excess_Vector (1 .. 3) := [2.0, 0.0, -1.0];
      Same  : constant Excess_Vector (1 .. 3) := [1.0, 0.0, -1.0];
   begin
      Check (Lex_Compare (Left, Right) = Left_Better,
             "lex: smaller first entry is better");
      Check (Lex_Compare (Right, Left) = Right_Better,
             "lex: larger first entry is worse");
      Check (Lex_Compare (Left, Same) = Equal, "lex equal");
   end;

   declare
      L : constant Excess_Vector (1 .. 3) := [1.0, -0.5, -1.0];
      R : constant Excess_Vector (1 .. 3) := [1.0, 0.0, -2.0];
   begin
      Check (Lex_Compare (L, R) = Left_Better,
             "lex tie-break on second entry");
   end;

   declare
      A : constant Excess_Vector (1 .. 2) := [1.0, 0.0];
      B : constant Excess_Vector (1 .. 3) := [1.0, 0.0, -1.0];
   begin
      Check (Lex_Raises (A, B), "lex length mismatch raises");
   end;

   ---------------------------------------------------------------------
   Section ("5. Gloves nucleolus");
   ---------------------------------------------------------------------
   declare
      V  : constant Characteristic := Make_Gloves;
      Nu : constant Allocation := Gloves_Nucleolus;
      Fn : constant Allocation := Find_Nucleolus (PC (3), V);
   begin
      Check (Vec_Near (Nu, Allocation'(1 => 0.0, 2 => 0.0, 3 => 1.0)),
             "closed-form gloves (0,0,1)");
      Check (Is_Imputation (PC (3), V, Nu), "gloves nu imputation");
      Check (Near (Max_Excess (PC (3), V, Nu), W (0.0)),
             "gloves nu in least core / core");
      Check (Vec_Near (Fn, Nu, W (0.05)),
             "grid Find_Nucleolus ≈ gloves closed form");
   end;

   ---------------------------------------------------------------------
   Section ("6. Pair gloves / additive / zero");
   ---------------------------------------------------------------------
   declare
      V  : constant Characteristic := Make_Pair_Gloves;
      Nu : constant Allocation := Pair_Gloves_Nucleolus;
      Fn : constant Allocation := Find_Nucleolus (PC (2), V);
   begin
      Check (Vec_Near (Nu, Allocation'(1 => 7.5, 2 => 7.5)),
             "pair gloves (7.5,7.5)");
      Check (Vec_Near (Fn, Nu, W (0.05)), "grid ≈ pair gloves");
      Check (Is_Imputation (PC (2), V, Nu), "pair gloves imputation");
   end;

   declare
      Sing : constant Allocation (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      V    : constant Characteristic := Make_Additive (Sing);
      Nu   : constant Allocation := Additive_Nucleolus (Sing);
      Fn   : constant Allocation := Find_Nucleolus (PC (4), V);
   begin
      Check (Vec_Near (Nu, Sing), "additive closed form");
      Check (Vec_Near (Fn, Sing, W (0.15)), "grid ≈ additive n=4");
      Check (Is_Imputation (PC (4), V, Fn), "additive grid imputation");
   end;

   declare
      V  : constant Characteristic := Make_Zero (PC (3));
      Nu : constant Allocation := Zero_Nucleolus (PC (3));
      Fn : constant Allocation := Find_Nucleolus (PC (3), V);
   begin
      Check (Vec_Near (Nu, Allocation'(1 => 0.0, 2 => 0.0, 3 => 0.0)),
             "zero nucleolus");
      Check (Vec_Near (Fn, Nu), "grid zero");
   end;

   ---------------------------------------------------------------------
   Section ("7. Unanimity / majority equal split");
   ---------------------------------------------------------------------
   for N in 2 .. 5 loop
      declare
         VU : constant Characteristic := Make_Unanimity (PC (N));
         VM : constant Characteristic := Make_Majority (PC (N));
         NU : constant Allocation := Unanimity_Nucleolus (PC (N));
         NM : constant Allocation := Majority_Nucleolus (PC (N));
         FU : constant Allocation := Find_Nucleolus (PC (N), VU);
         FM : constant Allocation := Find_Nucleolus (PC (N), VM);
         Eq : constant Worth := 1.0 / Worth (N);
      begin
         Check (Near (NU (1), Eq),
                "unanimity equal n=" & Natural'Image (N));
         Check (Vec_Near (FU, NU, W (0.08)),
                "grid unanimity n=" & Natural'Image (N));
         Check (Vec_Near (NM, NU),
                "majority closed = unanimity closed n=" &
                Natural'Image (N));
         Check (Vec_Near (FM, NM, W (0.08)),
                "grid majority n=" & Natural'Image (N));
         Check (Is_Imputation (PC (N), VU, FU),
                "unanimity grid imputation n=" & Natural'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("8. Contested garment / Talmud bankruptcy");
   ---------------------------------------------------------------------
   declare
      --  Classic: estate 100, claims 100 and 50? garment: one claims all
      --  (1), other half (0.5), estate 1 → awards 0.75 and 0.25
      CG : constant Allocation :=
        Contested_Garment (W (1.0), W (1.0), W (0.5));
   begin
      Check (Near (CG (1), W (0.75), W (1.0E-9)), "CG 3/4");
      Check (Near (CG (2), W (0.25), W (1.0E-9)), "CG 1/4");
   end;

   declare
      Claims : constant Allocation (1 .. 2) := [100.0, 100.0];
      Estate : constant Worth := 100.0;
      V      : constant Characteristic :=
        Make_Bankruptcy (Estate, Claims);
      Tal    : constant Allocation :=
        Talmud_Nucleolus (Estate, Claims);
      Fn     : constant Allocation := Find_Nucleolus (PC (2), V);
      CG     : constant Allocation :=
        Contested_Garment (Estate, W (100.0), W (100.0));
   begin
      Check (Near (Tal (1), W (50.0)), "Talmud equal claims 50");
      Check (Near (Tal (2), W (50.0)), "Talmud equal claims 50 b");
      Check (Vec_Near (Tal, CG), "Talmud = CG for n=2");
      Check (Vec_Near (Fn, Tal, W (1.0)), "grid ≈ Talmud n=2");
      Check (Near (V (0), W (0.0)), "bankruptcy v empty");
      Check (Near (V (3), Estate), "bankruptcy v grand = estate");
   end;

   declare
      --  Talmud example: estate 120, claims 40,60,80? common 300/100/200/300
      --  Use estate 100, claims 40, 60 → half sum 50, estate > 50 so
      --  dual CEA path.
      Claims : constant Allocation (1 .. 2) := [40.0, 60.0];
      Estate : constant Worth := 100.0;
      Tal    : constant Allocation :=
        Talmud_Nucleolus (Estate, Claims);
      V      : constant Characteristic :=
        Make_Bankruptcy (Estate, Claims);
      Fn     : constant Allocation := Find_Nucleolus (PC (2), V);
   begin
      Check (Near (Sum_Allocation (Tal), Estate), "Talmud efficient");
      Check (Tal (1) <= Claims (1) + W (1.0E-9), "Talmud ≤ claim1");
      Check (Tal (2) <= Claims (2) + W (1.0E-9), "Talmud ≤ claim2");
      Check (Vec_Near (Fn, Tal, W (1.5)), "grid ≈ Talmud 40/60");
   end;

   declare
      Claims : constant Allocation (1 .. 3) := [100.0, 200.0, 300.0];
      --  Estate 100 ≤ half-sum 300 → CEA on half-claims
      Tal100 : constant Allocation :=
        Talmud_Nucleolus (W (100.0), Claims);
      V100   : constant Characteristic :=
        Make_Bankruptcy (W (100.0), Claims);
      Fn100  : constant Allocation := Find_Nucleolus (PC (3), V100);
      --  Estate 200
      Tal200 : constant Allocation :=
        Talmud_Nucleolus (W (200.0), Claims);
      V200   : constant Characteristic :=
        Make_Bankruptcy (W (200.0), Claims);
      Fn200  : constant Allocation := Find_Nucleolus (PC (3), V200);
      --  Estate 300 = half total → boundary
      Tal300 : constant Allocation :=
        Talmud_Nucleolus (W (300.0), Claims);
   begin
      Check (Near (Sum_Allocation (Tal100), W (100.0)),
             "Talmud E=100 efficient");
      Check (Near (Sum_Allocation (Tal200), W (200.0)),
             "Talmud E=200 efficient");
      Check (Near (Sum_Allocation (Tal300), W (300.0)),
             "Talmud E=300 efficient");
      --  Famous: E=100 → (33.33..., 33.33..., 33.33...) approx equal awards
      Check (Near (Tal100 (1), Tal100 (2), W (0.01)),
             "Talmud E=100 ≈ equal awards");
      Check (Near (Tal100 (2), Tal100 (3), W (0.01)),
             "Talmud E=100 ≈ equal awards b");
      Check (Vec_Near (Fn100, Tal100, W (3.0)),
             "grid ≈ Talmud 3p E=100");
      Check (Vec_Near (Fn200, Tal200, W (5.0)),
             "grid ≈ Talmud 3p E=200");
      --  E=300 = sum of half-claims → each gets half claim
      Check (Near (Tal300 (1), W (50.0)), "Talmud E=300 half1");
      Check (Near (Tal300 (2), W (100.0)), "Talmud E=300 half2");
      Check (Near (Tal300 (3), W (150.0)), "Talmud E=300 half3");
   end;

   ---------------------------------------------------------------------
   Section ("9. Airport nucleolus");
   ---------------------------------------------------------------------
   declare
      Costs : constant Allocation (1 .. 3) := [1.0, 2.0, 3.0];
      V     : constant Characteristic := Make_Airport (Costs);
      Nu    : constant Allocation := Airport_Nucleolus (Costs);
      Fn    : constant Allocation := Find_Nucleolus (PC (3), V);
      Ord   : constant Lex_Order :=
        Lex_Compare
          (Sorted_Excess_Vector (PC (3), V, Fn),
           Sorted_Excess_Vector (PC (3), V, Nu));
   begin
      --  Littlechild–Owen sequential shares (Shapley of the cost game),
      --  negated for TU worth v(S)=−max c_i:
      --  1/3, 5/6, 11/6 → (−1/3, −5/6, −11/6).
      Check (Near (Nu (1), W (-1.0 / 3.0), W (1.0E-9)), "airport LO x1");
      Check (Near (Nu (2), W (-5.0 / 6.0), W (1.0E-9)), "airport LO x2");
      Check (Near (Nu (3), W (-11.0 / 6.0), W (1.0E-9)), "airport LO x3");
      Check (Near (Sum_Allocation (Nu), V (7)), "airport LO efficient");
      Check (Is_Imputation (PC (3), V, Nu), "airport LO imputation");
      Check (Near (Max_Excess (PC (3), V, Nu), W (0.0), W (1.0E-9)),
             "airport LO in core");
      Check (Is_Imputation (PC (3), V, Fn), "airport grid imputation");
      Check (Max_Excess (PC (3), V, Fn) <= W (1.0E-9),
             "airport grid in core");
      Check (Ord = Left_Better or else Ord = Equal,
             "grid nucleolus lex ≥ LO shares");
      Check (Near (V (1), W (-1.0)), "airport v({1})");
      Check (Near (V (7), W (-3.0)), "airport v(N)");
   end;

   declare
      Costs : constant Allocation (1 .. 2) := [4.0, 10.0];
      Nu    : constant Allocation := Airport_Nucleolus (Costs);
   begin
      --  shares 4/2=2, 2+(10-4)/1=8; TU neg
      Check (Near (Nu (1), W (-2.0)), "airport 2p x1");
      Check (Near (Nu (2), W (-8.0)), "airport 2p x2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Compute alias / Instance API");
   ---------------------------------------------------------------------
   declare
      V  : constant Characteristic := Make_Unanimity (PC (3));
      C1 : constant Allocation := Compute (PC (3), V);
      C2 : constant Allocation := Find_Nucleolus (PC (3), V);
      Inst : Instance;
   begin
      Check (Vec_Near (C1, C2), "Compute renames Find_Nucleolus");
      Clear (Inst, Nat (3));
      Check (Size (Inst) = PC (3), "Instance Size");
      Load (Inst, V);
      Check (Near (Grand_Worth (Inst), W (1.0)), "Grand_Worth");
      Check (Near (Get_Worth (Inst, Nat (7)), W (1.0)), "Get_Worth grand");
      Check (Near (Get_Worth (Inst, Nat (0)), W (0.0)), "Get_Worth empty");
      declare
         Nu : constant Allocation := Find_Nucleolus (Inst);
      begin
         Check (Vec_Near (Nu, Unanimity_Nucleolus (PC (3)), W (0.08)),
                "Instance Find_Nucleolus");
         Check (Is_Imputation (Inst, Nu), "Instance Is_Imputation");
         Check (Near (Excess (Inst, Nu, Nat (0)), W (0.0)),
                "Instance Excess empty");
      end;
      Set_Worth (Inst, Nat (3), W (0.25));
      Check (Near (Get_Worth (Inst, Nat (3)), W (0.25)), "Set_Worth");
   end;

   declare
      Inst : Instance;
   begin
      Clear (Inst, Nat (0));
      Check (Size (Inst) = PC (0), "Clear size 0");
      Check (Clear_Raises (Nat (9)), "Clear >Max_N raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument coverage");
   ---------------------------------------------------------------------
   declare
      V3 : constant Characteristic := Make_Gloves;
      V_Bad_Len : constant Characteristic (0 .. 5) := [others => 0.0];
      V_Bad_Base : constant Characteristic (1 .. 8) := [others => 0.0];
      X3 : constant Allocation (1 .. 3) := [0.0, 0.0, 1.0];
      X2 : constant Allocation (1 .. 2) := [0.0, 0.0];
   begin
      Check (Find_Raises (Nat (0), V3), "Find N=0 raises");
      Check (Find_Raises (Nat (7), V3), "Find N>Max_Search raises");
      Check (Find_Raises (PC (3), V_Bad_Len), "Find bad length");
      Check (Find_Raises (PC (3), V_Bad_Base), "Find bad First");
      Check (Imputation_Raises (PC (3), V3, X2), "imputation bounds");
      Check (Excess_Raises (PC (3), V3, X3, Nat (99)), "excess bad mask");
      Check (Majority_Raises (Nat (0)), "majority N=0");
      Check (Majority_Raises (Nat (9)), "majority N>Max");
   end;

   declare
      Bad_Claims : constant Allocation (1 .. 2) := [1.0, -1.0];
      Good : constant Allocation (1 .. 2) := [1.0, 2.0];
      Decr : constant Allocation (1 .. 3) := [3.0, 2.0, 1.0];
   begin
      Check (Bankruptcy_Raises (W (-1.0), Good), "bankruptcy neg estate");
      Check (Bankruptcy_Raises (W (1.0), Bad_Claims), "bankruptcy neg claim");
      Check (Airport_Raises (Decr), "airport decreasing costs");
   end;

   --  Empty imputation set: v(N) < sum v({i})
   declare
      V : constant Characteristic (0 .. 3) := [0.0, 5.0, 5.0, 5.0];
   begin
      Check (not Imputation_Set_Nonempty (PC (2), V),
             "imp set empty detected");
      Check (Find_Raises (PC (2), V), "Find empty imp set raises");
   end;

   ---------------------------------------------------------------------
   Section ("12. Lex / excess stress on small games");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Gloves;
      Better : constant Allocation (1 .. 3) := [0.0, 0.0, 1.0];
      Worse  : constant Allocation (1 .. 3) := [0.4, 0.4, 0.2];
      SB : constant Excess_Vector :=
        Sorted_Excess_Vector (PC (3), V, Better);
      SW : constant Excess_Vector :=
        Sorted_Excess_Vector (PC (3), V, Worse);
   begin
      Check (Lex_Compare (SB, SW) = Left_Better,
             "gloves nucleolus lex-beats off-core");
      Check (Is_Imputation (PC (3), V, Worse),
             "worse still imputation");
   end;

   for N in 1 .. 4 loop
      declare
         V  : constant Characteristic := Make_Zero (PC (N));
         Nu : constant Allocation := Find_Nucleolus (PC (N), V);
      begin
         Check (Is_Imputation (PC (N), V, Nu),
                "zero grid imputation n=" & Natural'Image (N));
         Check (Near (Max_Excess (PC (N), V, Nu), W (0.0), W (1.0E-7)),
                "zero max excess n=" & Natural'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("13. N=1 trivial / two-player standard");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic (0 .. 1) := [0.0, 10.0];
      Nu : constant Allocation := Find_Nucleolus (PC (1), V);
   begin
      Check (Near (Nu (1), W (10.0)), "N=1 nucleolus = v(N)");
   end;

   declare
      --  Two-player: nucleolus = midpoint of core =
      --  x1 = (v(N)+v({1})-v({2}))/2
      V : constant Characteristic (0 .. 3) := [0.0, 1.0, 3.0, 10.0];
      Nu : constant Allocation := Find_Nucleolus (PC (2), V);
      Expect1 : constant Worth := (10.0 + 1.0 - 3.0) / 2.0;
      Expect2 : constant Worth := 10.0 - Expect1;
   begin
      Check (Near (Nu (1), Expect1, W (0.05)), "2p standard x1");
      Check (Near (Nu (2), Expect2, W (0.05)), "2p standard x2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Grid_Step override / Max_N tables");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Unanimity (PC (3));
      A : constant Allocation :=
        Find_Nucleolus (PC (3), V, Grid_Step => W (0.1));
      B : constant Allocation := Unanimity_Nucleolus (PC (3));
   begin
      Check (Vec_Near (A, B, W (0.12)), "explicit Grid_Step");
   end;

   declare
      V : constant Characteristic := Make_Zero (PC (8));
   begin
      Check (V'Length = Nat (256), "Max_N=8 table length");
      Check (Near (V (0), W (0.0)), "Max_N zero empty");
      Check (Near (V (255), W (0.0)), "Max_N zero grand");
   end;

   --  Make_Majority / Unanimity at Max_N (construct only; no search)
   declare
      VM : constant Characteristic := Make_Majority (PC (8));
      VU : constant Characteristic := Make_Unanimity (PC (8));
   begin
      Check (Near (VM (255), W (1.0)), "majority n=8 grand");
      Check (Near (VU (255), W (1.0)), "unanimity n=8 grand");
      Check (Near (VM (1), W (0.0)), "majority singleton 0");
      Check (Near (Equal_Split_Nucleolus (PC (8), W (1.0)) (1),
                   W (0.125)),
             "equal split 1/8");
   end;

   ---------------------------------------------------------------------
   Section ("15. Allocations_Near / Load edge cases");
   ---------------------------------------------------------------------
   declare
      A : constant Allocation (1 .. 2) := [1.0, 2.0];
      B : constant Allocation (1 .. 2) := [1.0, 2.0 + 1.0E-12];
      C : constant Allocation (1 .. 2) := [1.0, 3.0];
      D : constant Allocation (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Check (Allocations_Near (A, B), "Allocations_Near close");
      Check (not Allocations_Near (A, C), "Allocations_Near far");
      Check (not Allocations_Near (A, D), "Allocations_Near bounds");
   end;

   declare
      Inst : Instance;
      V1 : constant Characteristic (0 .. 0) := [0.0];
   begin
      Load (Inst, V1);
      Check (Size (Inst) = PC (0), "Load length-1 empty game");
   end;

   ---------------------------------------------------------------------
   Section ("16. Batch constructor sanity");
   ---------------------------------------------------------------------
   for N in 1 .. 6 loop
      declare
         Z : constant Characteristic := Make_Zero (PC (N));
         U : constant Characteristic := Make_Unanimity (PC (N));
         M : constant Characteristic := Make_Majority (PC (N));
      begin
         Check (Z'Length = Power2 (PC (N)),
                "zero len n=" & Natural'Image (N));
         Check (Near (U (U'Last), W (1.0)),
                "unanimity grand n=" & Natural'Image (N));
         Check (Near (M (M'Last), W (1.0)),
                "majority grand n=" & Natural'Image (N));
         if N >= 2 then
            Check (Near (M (1), W (0.0)),
                   "majority sing0 n=" & Natural'Image (N));
         end if;
      end;
   end loop;

   declare
      Sing : constant Allocation (1 .. 5) :=
        [0.5, 1.5, 2.5, 3.5, 4.5];
      V : constant Characteristic := Make_Additive (Sing);
   begin
      Check (Near (V (0), W (0.0)), "additive empty");
      Check (Near (V (V'Last), Sum_Allocation (Sing)),
             "additive grand");
      Check (Near (V (1), W (0.5)), "additive {1}");
   end;

   ---------------------------------------------------------------------
   Section ("17. Nucleolus uniqueness probe (symmetric)");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Unanimity (PC (4));
      Nu : constant Allocation := Find_Nucleolus (PC (4), V);
      Alt : constant Allocation (1 .. 4) := [0.4, 0.2, 0.2, 0.2];
      SNu : constant Excess_Vector :=
        Sorted_Excess_Vector (PC (4), V, Nu);
      SAlt : constant Excess_Vector :=
        Sorted_Excess_Vector (PC (4), V, Alt);
   begin
      Check (Is_Imputation (PC (4), V, Alt), "alt unanimity imputation");
      Check (Lex_Compare (SNu, SAlt) = Left_Better,
             "equal split lex-beats unequal unanimity");
      Check (Near (Nu (1), Nu (2), W (0.08)), "sym φ approx equal a");
      Check (Near (Nu (2), Nu (3), W (0.08)), "sym φ approx equal b");
      Check (Near (Nu (3), Nu (4), W (0.08)), "sym φ approx equal c");
   end;

   ---------------------------------------------------------------------
   Section ("18. More Talmud / CG consistency");
   ---------------------------------------------------------------------
   declare
      Claims : constant Allocation (1 .. 2) := [120.0, 240.0];
   begin
      for E in 1 .. 8 loop
         declare
            Estate : constant Worth := Worth (E) * 40.0;
            Tal : constant Allocation :=
              Talmud_Nucleolus (Estate, Claims);
            CG  : constant Allocation :=
              Contested_Garment (Estate, Claims (1), Claims (2));
         begin
            Check (Vec_Near (Tal, CG, W (1.0E-6)),
                   "Talmud=CG E=" & Worth'Image (Estate));
            Check (Near (Sum_Allocation (Tal), Estate, W (1.0E-6)),
                   "Talmud eff E=" & Worth'Image (Estate));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("19. Instance Set/Get bounds + Find step");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Raised : Boolean := False;
   begin
      Clear (Inst, Nat (2));
      begin
         Set_Worth (Inst, Nat (4), W (1.0));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Set_Worth OOB raises");
      Raised := False;
      begin
         declare
            Unused : Worth := Get_Worth (Inst, Nat (4));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Get_Worth OOB raises");
   end;

   ---------------------------------------------------------------------
   Section ("20. Gloves excess vector structure");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Make_Gloves;
      X : constant Allocation := Gloves_Nucleolus;
      S : constant Excess_Vector :=
        Sorted_Excess_Vector (PC (3), V, X);
   begin
      Check (S'Length = Nat (8), "gloves 8 excesses");
      --  All excesses ≤ 0 for core point; max is 0
      Check (S (S'First) <= W (1.0E-9), "gloves first excess ≤ 0");
      Check (Near (S (S'First), W (0.0), W (1.0E-9)),
             "gloves worst excess = 0");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("RESULT: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Put_Line ("========================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
