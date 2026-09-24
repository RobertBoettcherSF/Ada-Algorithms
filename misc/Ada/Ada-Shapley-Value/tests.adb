--  Standalone test suite for Shapley_Value.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Shapley_Value; use Shapley_Value;

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

   function Approx
     (A, B : Worth; Tol : Worth := 1.0E-9) return Boolean
   is (Near (A, B, Tol));

   function Vec_Near
     (A, B : Value_Vector; Tol : Worth := 1.0E-9) return Boolean
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

   function Fact_Raises (K : Natural) return Boolean is
      Unused : Worth;
   begin
      Unused := Factorial (K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Fact_Raises;

   function Weight_Raises (Sz : Natural; N : Natural) return Boolean is
      Unused : Worth;
   begin
      Unused := Shapley_Weight (Sz, N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Weight_Raises;

   function Power2_Raises (N : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Power2 (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Power2_Raises;

   function Compute_Raises
     (N : Natural; V : Characteristic) return Boolean
   is
   begin
      declare
         Phi : constant Value_Vector := Compute (N, V);
         pragma Unreferenced (Phi);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

   function Compute_Null_Raises (N : Natural) return Boolean is
   begin
      declare
         Phi : constant Value_Vector := Compute (N, null);
         pragma Unreferenced (Phi);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Null_Raises;

   function Perm_Raises
     (N : Natural; V : Characteristic) return Boolean
   is
   begin
      declare
         Phi : constant Value_Vector := Compute_By_Permutations (N, V);
         pragma Unreferenced (Phi);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Perm_Raises;

   function Clear_Raises (Size : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_Worth_Raises
     (Inst : in out Instance; Mask : Natural; Val : Worth) return Boolean
   is
   begin
      Set_Worth (Inst, Mask, Val);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Worth_Raises;

   function Get_Worth_Raises
     (Inst : Instance; Mask : Natural) return Boolean
   is
      Unused : Worth;
   begin
      Unused := Get_Worth (Inst, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Worth_Raises;

   function Load_Raises (V : Characteristic) return Boolean is
      Inst : Instance;
   begin
      Load (Inst, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Raises;

   function Marginal_Raises
     (V : Characteristic; S : Natural; I : Player_Id) return Boolean
   is
      Unused : Worth;
   begin
      Unused := Marginal (V, S, I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Marginal_Raises;

   function Empty_Compute_Raises return Boolean is
      Inst : Instance;
      Phi  : Value_Vector (1 .. 1);
      pragma Unreferenced (Phi);
   begin
      Clear (Inst, 0);
      Phi := Compute (Inst);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Compute_Raises;

   ---------------------------------------------------------------------------
   -- Classic games
   ---------------------------------------------------------------------------

   --  Glove game: players 1,2 right-hand; 3 left-hand.
   --  v = 1 on {1,3}, {2,3}, {1,2,3}; else 0.  φ = (1/6, 1/6, 2/3).
   function Glove_V return Characteristic is
      V : Characteristic (0 .. 7) := [others => 0.0];
   begin
      V (2#101#) := 1.0;  -- {1,3}
      V (2#110#) := 1.0;  -- {2,3}
      V (2#111#) := 1.0;  -- {1,2,3}
      return V;
   end Glove_V;

   --  Simple majority (3 players): v(S)=1 iff |S|≥2.
   function Majority3_V return Characteristic is
      V : Characteristic (0 .. 7) := [others => 0.0];
   begin
      for M in 0 .. 7 loop
         if Bit_Count (M) >= 2 then
            V (M) := 1.0;
         end if;
      end loop;
      return V;
   end Majority3_V;

   --  Additive game: v(S) = Σ_{i∈S} a_i.
   function Additive_V
     (N : Player_Count; A : Value_Vector) return Characteristic
   is
      V : Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
      S : Worth;
   begin
      for M in V'Range loop
         S := 0.0;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (M, I) then
               S := S + A (I);
            end if;
         end loop;
         V (M) := S;
      end loop;
      return V;
   end Additive_V;

   --  Airport cost game: c(S) = max_{i∈S} c_i  (c(∅)=0).
   function Airport_V
     (N : Player_Count; Costs : Value_Vector) return Characteristic
   is
      V : Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
      Mx : Worth;
   begin
      for M in 1 .. V'Last loop
         Mx := 0.0;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (M, I) and then Costs (I) > Mx then
               Mx := Costs (I);
            end if;
         end loop;
         V (M) := Mx;
      end loop;
      return V;
   end Airport_V;

   --  Unanimity / carrier game on a set T: v(S)=1 iff T ⊆ S.
   function Unanimity_V
     (N : Player_Count; T_Mask : Natural) return Characteristic
   is
      V  : Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
      Ok : Boolean;
   begin
      for M in V'Range loop
         Ok := True;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (T_Mask, I) and then not Has_Player (M, I) then
               Ok := False;
            end if;
         end loop;
         if Ok then
            V (M) := 1.0;
         end if;
      end loop;
      return V;
   end Unanimity_V;

   --  Callback wrappers for glove
   function Glove_Cb (Mask : Natural) return Worth is
      V : constant Characteristic := Glove_V;
   begin
      return V (Mask);
   end Glove_Cb;

begin
   Put_Line ("Shapley_Value test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Near / tolerances");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Near_Raises (W (-1.0)), "Near negative Tol raises");
   Check (Approx (W (0.5), W (0.5)), "Approx helper");

   ---------------------------------------------------------------------
   Section ("2. Bitmask helpers");
   ---------------------------------------------------------------------
   Check (Player_Bit (Pid (1)) = Nat (1), "Player_Bit 1 = 1");
   Check (Player_Bit (Pid (2)) = Nat (2), "Player_Bit 2 = 2");
   Check (Player_Bit (Pid (3)) = Nat (4), "Player_Bit 3 = 4");
   Check (Player_Bit (Pid (4)) = Nat (8), "Player_Bit 4 = 8");
   Check (Bit_Count (Nat (0)) = Nat (0), "Bit_Count 0");
   Check (Bit_Count (Nat (1)) = Nat (1), "Bit_Count 1");
   Check (Bit_Count (Nat (7)) = Nat (3), "Bit_Count 7");
   Check (Bit_Count (Nat (8)) = Nat (1), "Bit_Count 8");
   Check (Bit_Count (Nat (15)) = Nat (4), "Bit_Count 15");
   Check (Coalition_Size (Nat (5)) = Nat (2), "Coalition_Size alias");
   Check (Has_Player (Nat (5), Pid (1)), "Has_Player bit0");
   Check (not Has_Player (Nat (5), Pid (2)), "Has_Player bit1 clear");
   Check (Has_Player (Nat (5), Pid (3)), "Has_Player bit2");
   Check (Power2 (PC (0)) = Nat (1), "Power2 0");
   Check (Power2 (PC (1)) = Nat (2), "Power2 1");
   Check (Power2 (PC (3)) = Nat (8), "Power2 3");
   Check (Power2 (PC (12)) = Nat (4096), "Power2 12");
   Check (Power2_Raises (Nat (13)), "Power2 13 raises");

   ---------------------------------------------------------------------
   Section ("3. Factorial / binomial / Shapley weight");
   ---------------------------------------------------------------------
   Check (Near (Factorial (Nat (0)), 1.0), "0!");
   Check (Near (Factorial (Nat (1)), 1.0), "1!");
   Check (Near (Factorial (Nat (2)), 2.0), "2!");
   Check (Near (Factorial (Nat (3)), 6.0), "3!");
   Check (Near (Factorial (Nat (4)), 24.0), "4!");
   Check (Near (Factorial (Nat (5)), 120.0), "5!");
   Check (Near (Factorial (Nat (10)), 3_628_800.0), "10!");
   Check (Fact_Raises (Nat (21)), "21! raises");
   Check (Near (Binomial (Nat (5), Nat (2)), 10.0), "C(5,2)");
   Check (Near (Binomial (Nat (6), Nat (0)), 1.0), "C(6,0)");
   Check (Near (Binomial (Nat (6), Nat (6)), 1.0), "C(6,6)");
   Check (Near (Binomial (Nat (6), Nat (7)), 0.0), "C(6,7)=0");
   Check (Near (Binomial (Nat (10), Nat (3)), 120.0), "C(10,3)");
   --  weight for |S|=0, n=3: 0! 2! / 3! = 2/6 = 1/3
   Check (Near (Shapley_Weight (Nat (0), PC (3)), 1.0 / 3.0),
          "weight |S|=0 n=3");
   --  |S|=1, n=3: 1! 1! / 3! = 1/6
   Check (Near (Shapley_Weight (Nat (1), PC (3)), 1.0 / 6.0),
          "weight |S|=1 n=3");
   --  |S|=2, n=3: 2! 0! / 3! = 2/6 = 1/3
   Check (Near (Shapley_Weight (Nat (2), PC (3)), 1.0 / 3.0),
          "weight |S|=2 n=3");
   Check (Weight_Raises (Nat (0), PC (0)), "weight n=0 raises");
   Check (Weight_Raises (Nat (3), PC (3)), "weight |S|>=n raises");
   Check (Weight_Raises (Nat (4), PC (3)), "weight |S|>n raises");

   ---------------------------------------------------------------------
   Section ("4. Marginal");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic := Glove_V;
   begin
      Check (Near (Marginal (V, Nat (0), Pid (1)), 0.0),
             "glove marg empty+1");
      Check (Near (Marginal (V, Nat (0), Pid (3)), 0.0),
             "glove marg empty+3");
      Check (Near (Marginal (V, Nat (1), Pid (3)), 1.0),
             "glove marg {1}+3");
      Check (Near (Marginal (V, Nat (4), Pid (1)), 1.0),
             "glove marg {3}+1");
      Check (Near (Marginal (V, Nat (3), Pid (3)), 1.0),
             "glove marg {1,2}+3");
      Check (Near (Marginal (V, Nat (5), Pid (2)), 0.0),
             "glove marg {1,3}+2");
      Check (Marginal_Raises (V, Nat (1), Pid (1)),
             "marg when i already in S");
      Check (Marginal_Raises (V, Nat (8), Pid (1)),
             "marg mask out of range");
      declare
         Bad : constant Characteristic (1 .. 8) := [others => 0.0];
      begin
         Check (Marginal_Raises (Bad, Nat (0), Pid (1)),
                "marg non-0-based raises");
      end;
      Check (Near (Marginal (Glove_Cb'Access, Nat (1), Pid (3)), 1.0),
             "callback marginal");
   end;

   ---------------------------------------------------------------------
   Section ("5. Glove game (classic)");
   ---------------------------------------------------------------------
   declare
      V   : constant Characteristic := Glove_V;
      Phi : constant Value_Vector := Compute (PC (3), V);
      Exp : constant Value_Vector (1 .. 3) :=
        [1.0 / 6.0, 1.0 / 6.0, 2.0 / 3.0];
      Perm : constant Value_Vector :=
        Compute_By_Permutations (PC (3), V);
      Cb : constant Value_Vector := Compute (PC (3), Glove_Cb'Access);
   begin
      Check (Vec_Near (Phi, Exp), "glove coalition formula");
      Check (Vec_Near (Perm, Exp), "glove permutation formula");
      Check (Vec_Near (Cb, Exp), "glove callback Compute");
      Check (Vec_Near (Values (PC (3), V), Exp), "Values alias");
      Check (Is_Efficient (Phi, V (7)), "glove efficient");
      Check (Near (Phi (1), Phi (2)), "glove symmetry 1~2");
      Check (Are_Symmetric (PC (3), V, Pid (1), Pid (2)),
             "Are_Symmetric 1,2");
      Check (not Are_Symmetric (PC (3), V, Pid (1), Pid (3)),
             "not symmetric 1,3");
      Check (Near (Sum_Values (Phi), 1.0), "glove sum=1");
      Check (Near (Phi (3), 2.0 / 3.0), "glove left-glove gets 2/3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Majority voting (n=3)");
   ---------------------------------------------------------------------
   declare
      V   : constant Characteristic := Majority3_V;
      Phi : constant Value_Vector := Compute (PC (3), V);
      Perm : constant Value_Vector :=
        Compute_By_Permutations (PC (3), V);
   begin
      Check (Near (Phi (1), 1.0 / 3.0), "majority φ1");
      Check (Near (Phi (2), 1.0 / 3.0), "majority φ2");
      Check (Near (Phi (3), 1.0 / 3.0), "majority φ3");
      Check (Vec_Near (Phi, Perm), "majority perm cross-check");
      Check (Is_Efficient (Phi, 1.0), "majority efficient");
      Check (Are_Symmetric (PC (3), V, Pid (1), Pid (2)),
             "majority sym 1,2");
      Check (Are_Symmetric (PC (3), V, Pid (2), Pid (3)),
             "majority sym 2,3");
   end;

   --  Weighted voting: weights (3,2,2), quota 4. Swing players.
   --  Winning: masks with weight sum ≥ 4.
   declare
      Weights : constant array (1 .. 3) of Natural := [3, 2, 2];
      V : Characteristic (0 .. 7) := [others => 0.0];
      Wsum : Natural;
      Phi : Value_Vector (1 .. 3);
   begin
      for M in 0 .. 7 loop
         Wsum := 0;
         for I in 1 .. 3 loop
            if Has_Player (M, Pid (I)) then
               Wsum := Wsum + Weights (I);
            end if;
         end loop;
         if Wsum >= 5 then
            V (M) := 1.0;
         end if;
      end loop;
      Phi := Compute (PC (3), V);
      --  Player 1 (weight 3) is pivotal more often; φ1 > φ2 = φ3
      Check (Phi (1) > Phi (2), "weighted majority φ1 > φ2");
      Check (Near (Phi (2), Phi (3)), "weighted majority φ2=φ3");
      Check (Is_Efficient (Phi, 1.0), "weighted majority efficient");
      Check (Near (Sum_Values (Phi), 1.0), "weighted sum 1");
      --  Quota 5: {2,3} loses; φ = (2/3, 1/6, 1/6)
      Check (Near (Phi (1), 2.0 / 3.0), "weighted φ1=2/3");
      Check (Near (Phi (2), 1.0 / 6.0), "weighted φ2=1/6");
      Check (Near (Phi (3), 1.0 / 6.0), "weighted φ3=1/6");
   end;

   ---------------------------------------------------------------------
   Section ("7. Additive game (φ_i = v({i}))");
   ---------------------------------------------------------------------
   declare
      A : constant Value_Vector (1 .. 4) := [3.0, -1.0, 2.5, 0.0];
      V : constant Characteristic := Additive_V (PC (4), A);
      Phi : constant Value_Vector := Compute (PC (4), V);
      Perm : constant Value_Vector :=
        Compute_By_Permutations (PC (4), V);
   begin
      Check (Near (Phi (1), 3.0), "additive φ1");
      Check (Near (Phi (2), -1.0), "additive φ2");
      Check (Near (Phi (3), 2.5), "additive φ3");
      Check (Near (Phi (4), 0.0), "additive φ4");
      Check (Vec_Near (Phi, Perm), "additive perm match");
      Check (Is_Efficient (Phi, V (15)), "additive efficient");
      Check (Is_Dummy (PC (4), V, Pid (4)), "player 4 dummy (a4=0)");
      Check (not Is_Dummy (PC (4), V, Pid (1)), "player 1 not dummy");
   end;

   --  Two-player additive
   declare
      A : constant Value_Vector (1 .. 2) := [10.0, 20.0];
      V : constant Characteristic := Additive_V (PC (2), A);
      Phi : constant Value_Vector := Compute (PC (2), V);
   begin
      Check (Near (Phi (1), 10.0), "2p additive φ1");
      Check (Near (Phi (2), 20.0), "2p additive φ2");
      Check (Is_Efficient (Phi, 30.0), "2p additive efficient");
   end;

   ---------------------------------------------------------------------
   Section ("8. Airport / cost-sharing toy");
   ---------------------------------------------------------------------
   declare
      Costs : constant Value_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Characteristic := Airport_V (PC (3), Costs);
      Phi : constant Value_Vector := Compute (PC (3), V);
      --  Airport formula: φ1=c1/3, φ2=c1/3+(c2-c1)/2,
      --  φ3=c1/3+(c2-c1)/2+(c3-c2)/1
      E1 : constant Worth := 1.0 / 3.0;
      E2 : constant Worth := 1.0 / 3.0 + 1.0 / 2.0;
      E3 : constant Worth := 1.0 / 3.0 + 1.0 / 2.0 + 1.0;
      Perm : constant Value_Vector :=
        Compute_By_Permutations (PC (3), V);
   begin
      Check (Near (V (0), 0.0), "airport empty 0");
      Check (Near (V (1), 1.0), "airport {1}");
      Check (Near (V (2), 2.0), "airport {2}");
      Check (Near (V (4), 3.0), "airport {3}");
      Check (Near (V (3), 2.0), "airport {1,2}=max");
      Check (Near (V (7), 3.0), "airport grand");
      Check (Near (Phi (1), E1), "airport φ1");
      Check (Near (Phi (2), E2), "airport φ2");
      Check (Near (Phi (3), E3), "airport φ3");
      Check (Vec_Near (Phi, Perm), "airport perm match");
      Check (Is_Efficient (Phi, 3.0), "airport efficient");
      Check (Near (Sum_Values (Phi), 3.0), "airport sum costs");
   end;

   --  Four-player airport costs 1,2,3,6
   declare
      Costs : constant Value_Vector (1 .. 4) := [1.0, 2.0, 3.0, 6.0];
      V : constant Characteristic := Airport_V (PC (4), Costs);
      Phi : constant Value_Vector := Compute (PC (4), V);
      E1 : constant Worth := 1.0 / 4.0;
      E2 : constant Worth := 1.0 / 4.0 + 1.0 / 3.0;
      E3 : constant Worth := 1.0 / 4.0 + 1.0 / 3.0 + 1.0 / 2.0;
      E4 : constant Worth :=
        1.0 / 4.0 + 1.0 / 3.0 + 1.0 / 2.0 + 3.0 / 1.0;
   begin
      Check (Near (Phi (1), E1), "airport4 φ1");
      Check (Near (Phi (2), E2), "airport4 φ2");
      Check (Near (Phi (3), E3), "airport4 φ3");
      Check (Near (Phi (4), E4), "airport4 φ4");
      Check (Is_Efficient (Phi, 6.0), "airport4 efficient");
   end;

   ---------------------------------------------------------------------
   Section ("9. Unanimity / carrier games");
   ---------------------------------------------------------------------
   declare
      --  u_{{1,2}} on N=3: v(S)=1 iff {1,2}⊆S
      V : constant Characteristic :=
        Unanimity_V (PC (3), Nat (2#011#));
      Phi : constant Value_Vector := Compute (PC (3), V);
   begin
      Check (Near (V (3), 1.0), "unanimity {1,2}");
      Check (Near (V (7), 1.0), "unanimity grand");
      Check (Near (V (1), 0.0), "unanimity singleton 0");
      Check (Near (Phi (1), 0.5), "unanimity φ1=1/2");
      Check (Near (Phi (2), 0.5), "unanimity φ2=1/2");
      Check (Near (Phi (3), 0.0), "unanimity φ3=0 (dummy)");
      Check (Is_Dummy (PC (3), V, Pid (3)), "player 3 dummy");
      Check (Is_Efficient (Phi, 1.0), "unanimity efficient");
   end;

   declare
      V : constant Characteristic :=
        Unanimity_V (PC (3), Nat (2#001#));
      Phi : constant Value_Vector := Compute (PC (3), V);
   begin
      Check (Near (Phi (1), 1.0), "singleton unanimity φ1");
      Check (Near (Phi (2), 0.0), "singleton unanimity φ2");
      Check (Near (Phi (3), 0.0), "singleton unanimity φ3");
   end;

   ---------------------------------------------------------------------
   Section ("10. One-player and trivial games");
   ---------------------------------------------------------------------
   declare
      V : constant Characteristic (0 .. 1) := [0.0, 5.0];
      Phi : constant Value_Vector := Compute (PC (1), V);
   begin
      Check (Near (Phi (1), 5.0), "n=1 φ=v(N)");
      Check (Is_Efficient (Phi, 5.0), "n=1 efficient");
      Check (Near (Compute_By_Permutations (PC (1), V) (1), 5.0),
             "n=1 perm");
   end;

   declare
      V : constant Characteristic (0 .. 3) := [0.0, 0.0, 0.0, 0.0];
      Phi : constant Value_Vector := Compute (PC (2), V);
   begin
      Check (Near (Phi (1), 0.0), "zero game φ1");
      Check (Near (Phi (2), 0.0), "zero game φ2");
      Check (Is_Dummy (PC (2), V, Pid (1)), "zero game dummy1");
      Check (Is_Dummy (PC (2), V, Pid (2)), "zero game dummy2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Additivity axiom (linearity)");
   ---------------------------------------------------------------------
   declare
      V1 : constant Characteristic := Glove_V;
      V2 : constant Characteristic := Majority3_V;
      Sum : Characteristic (0 .. 7);
      P1 : constant Value_Vector := Compute (PC (3), V1);
      P2 : constant Value_Vector := Compute (PC (3), V2);
      PS : Value_Vector (1 .. 3);
   begin
      for M in 0 .. 7 loop
         Sum (M) := V1 (M) + V2 (M);
      end loop;
      PS := Compute (PC (3), Sum);
      Check (Near (PS (1), P1 (1) + P2 (1)), "additivity φ1");
      Check (Near (PS (2), P1 (2) + P2 (2)), "additivity φ2");
      Check (Near (PS (3), P1 (3) + P2 (3)), "additivity φ3");
      --  Scalar: 2·v
      declare
         Two : Characteristic (0 .. 7);
         P2v : Value_Vector (1 .. 3);
      begin
         for M in 0 .. 7 loop
            Two (M) := 2.0 * V1 (M);
         end loop;
         P2v := Compute (PC (3), Two);
         Check (Near (P2v (1), 2.0 * P1 (1)), "homogeneity φ1");
         Check (Near (P2v (2), 2.0 * P1 (2)), "homogeneity φ2");
         Check (Near (P2v (3), 2.0 * P1 (3)), "homogeneity φ3");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Instance API");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Phi  : Value_Vector (1 .. 3);
      V    : constant Characteristic := Glove_V;
   begin
      Clear (Inst, PC (3));
      Check (Size (Inst) = PC (3), "Clear size 3");
      Check (Near (Get_Worth (Inst, Nat (0)), 0.0), "fresh empty worth");
      Set_Worth (Inst, Nat (2#101#), 1.0);
      Set_Worth (Inst, Nat (2#110#), 1.0);
      Set_Worth (Inst, Nat (2#111#), 1.0);
      Check (Near (Get_Worth (Inst, Nat (5)), 1.0), "Set/Get worth");
      Check (Near (Grand_Worth (Inst), 1.0), "Grand_Worth glove");
      Phi := Compute (Inst);
      Check (Near (Phi (3), 2.0 / 3.0), "Instance Compute glove");
      Check (Vec_Near (Compute_By_Permutations (Inst), Phi),
             "Instance perm match");

      Load (Inst, V);
      Check (Size (Inst) = PC (3), "Load size");
      Check (Vec_Near (Compute (Inst), Phi), "Load then Compute");

      Clear (Inst, PC (0));
      Check (Size (Inst) = PC (0), "Clear empty");
      Check (Empty_Compute_Raises, "Compute empty raises");
      Check (Clear_Raises (Nat (13)), "Clear >Max_N raises");
      Clear (Inst, PC (2));
      Check (Set_Worth_Raises (Inst, Nat (4), 1.0),
             "Set_Worth OOB raises");
      Check (Get_Worth_Raises (Inst, Nat (4)), "Get_Worth OOB raises");
   end;

   declare
      Bad1 : constant Characteristic (0 .. 2) := [others => 0.0];
      Bad2 : constant Characteristic (1 .. 4) := [others => 0.0];
      Ok0  : constant Characteristic (0 .. 0) := [0.0];
      Inst : Instance;
   begin
      Check (Load_Raises (Bad1), "Load non-power2 raises");
      Check (Load_Raises (Bad2), "Load non-0-based raises");
      Load (Inst, Ok0);
      Check (Size (Inst) = PC (0), "Load N=0 length-1");
   end;

   ---------------------------------------------------------------------
   Section ("13. Invalid arguments");
   ---------------------------------------------------------------------
   declare
      V3 : constant Characteristic (0 .. 7) := [others => 0.0];
      V_Bad_Len : constant Characteristic (0 .. 5) := [others => 0.0];
      V_Bad_Base : constant Characteristic (1 .. 8) := [others => 0.0];
   begin
      Check (Compute_Raises (PC (0), V3), "Compute N=0 raises");
      Check (Compute_Raises (Nat (13), V3), "Compute N>Max raises");
      Check (Compute_Raises (PC (3), V_Bad_Len), "Compute bad length");
      Check (Compute_Raises (PC (3), V_Bad_Base), "Compute bad First");
      Check (Compute_Null_Raises (PC (3)), "Compute null cb raises");
      Check (Perm_Raises (PC (0), V3), "Perm N=0 raises");
      Check (Perm_Raises (Nat (11), V3), "Perm N>Max_Perm raises");
      --  N=3 with wrong length for perm
      Check (Perm_Raises (PC (3), V_Bad_Len), "Perm bad length");
   end;

   ---------------------------------------------------------------------
   Section ("14. Permutation cross-check (n=2..5)");
   ---------------------------------------------------------------------
   for N in 2 .. 5 loop
      declare
         A : Value_Vector (1 .. Player_Id (N));
         V : Characteristic (0 .. Power2 (PC (N)) - 1);
         Phi, Perm : Value_Vector (1 .. Player_Id (N));
      begin
         for I in A'Range loop
            A (I) := Worth (Natural (I)) * 0.5;
         end loop;
         V := Additive_V (PC (N), A);
         Phi  := Compute (PC (N), V);
         Perm := Compute_By_Permutations (PC (N), V);
         Check (Vec_Near (Phi, Perm),
                "perm cross-check additive n=" &
                Natural'Image (N));
         Check (Is_Efficient (Phi, V (V'Last)),
                "efficient additive n=" & Natural'Image (N));
      end;
   end loop;

   --  Random-ish characteristic for n=4
   declare
      V : constant Characteristic (0 .. 15) :=
        [0.0, 1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0,
         0.5, 1.5, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7];
      Phi  : constant Value_Vector := Compute (PC (4), V);
      Perm : constant Value_Vector :=
        Compute_By_Permutations (PC (4), V);
   begin
      Check (Vec_Near (Phi, Perm, 1.0E-8), "n=4 arbitrary perm match");
      Check (Is_Efficient (Phi, V (15)), "n=4 arbitrary efficient");
   end;

   ---------------------------------------------------------------------
   Section ("15. Symmetry / dummy / efficiency stress");
   ---------------------------------------------------------------------
   declare
      --  All players symmetric: v(S) depends only on |S|
      V : Characteristic (0 .. 15) := [others => 0.0];
      Phi : Value_Vector (1 .. 4);
   begin
      for M in 0 .. 15 loop
         V (M) := Worth (Bit_Count (M)) ** 2;
      end loop;
      Phi := Compute (PC (4), V);
      Check (Near (Phi (1), Phi (2)), "symmetric game φ1=φ2");
      Check (Near (Phi (2), Phi (3)), "symmetric game φ2=φ3");
      Check (Near (Phi (3), Phi (4)), "symmetric game φ3=φ4");
      Check (Are_Symmetric (PC (4), V, Pid (1), Pid (4)),
             "Are_Symmetric all");
      Check (Is_Efficient (Phi, V (15)), "symmetric efficient");
      Check (Near (Sum_Values (Phi), V (15)), "sum = grand");
   end;

   declare
      --  Dummy player 4: v ignores bit 3
      V : Characteristic (0 .. 15) := [others => 0.0];
      Phi : Value_Vector (1 .. 4);
      Base : Worth;
   begin
      for M in 0 .. 15 loop
         Base := 0.0;
         if Has_Player (M, Pid (1)) then
            Base := Base + 1.0;
         end if;
         if Has_Player (M, Pid (2)) then
            Base := Base + 2.0;
         end if;
         if Has_Player (M, Pid (3)) then
            Base := Base + 4.0;
         end if;
         V (M) := Base;  --  independent of player 4
      end loop;
      Phi := Compute (PC (4), V);
      Check (Is_Dummy (PC (4), V, Pid (4)), "constructed dummy");
      Check (Near (Phi (4), 0.0), "dummy gets 0");
      Check (Near (Phi (1), 1.0), "dummy-game φ1");
      Check (Near (Phi (2), 2.0), "dummy-game φ2");
      Check (Near (Phi (3), 4.0), "dummy-game φ3");
   end;

   ---------------------------------------------------------------------
   Section ("16. Larger n (coalition path only)");
   ---------------------------------------------------------------------
   declare
      N : constant Player_Count := 8;
      A : Value_Vector (1 .. 8);
      V : Characteristic (0 .. 255);
      Phi : Value_Vector (1 .. 8);
      S : Worth := 0.0;
   begin
      for I in A'Range loop
         A (I) := Worth (Natural (I));
         S := S + A (I);
      end loop;
      V := Additive_V (N, A);
      Phi := Compute (N, V);
      for I in Phi'Range loop
         Check (Near (Phi (I), A (I)),
                "n=8 additive φ" & Player_Id'Image (I));
      end loop;
      Check (Is_Efficient (Phi, S), "n=8 efficient");
   end;

   declare
      N : constant Player_Count := 6;
      V : Characteristic (0 .. 63) := [others => 0.0];
      Phi : Value_Vector (1 .. 6);
   begin
      --  Majority of 6: win if |S| >= 4
      for M in 0 .. 63 loop
         if Bit_Count (M) >= 4 then
            V (M) := 1.0;
         end if;
      end loop;
      Phi := Compute (N, V);
      for I in Phi'Range loop
         Check (Near (Phi (I), 1.0 / 6.0),
                "n=6 majority φ" & Player_Id'Image (I));
      end loop;
      Check (Is_Efficient (Phi, 1.0), "n=6 majority efficient");
      Check (Vec_Near (Phi, Compute_By_Permutations (N, V)),
             "n=6 majority perm");
   end;

   ---------------------------------------------------------------------
   Section ("17. Callback permutation path");
   ---------------------------------------------------------------------
   declare
      Phi : constant Value_Vector :=
        Compute_By_Permutations (PC (3), Glove_Cb'Access);
   begin
      Check (Near (Phi (1), 1.0 / 6.0), "cb perm glove φ1");
      Check (Near (Phi (2), 1.0 / 6.0), "cb perm glove φ2");
      Check (Near (Phi (3), 2.0 / 3.0), "cb perm glove φ3");
   end;

   ---------------------------------------------------------------------
   Section ("18. Batch micro-checks");
   ---------------------------------------------------------------------
   for K in 0 .. 10 loop
      Check (Near (Factorial (Nat (K)) * Worth (K + 1),
                   Factorial (Nat (K + 1))),
             "fact recurrence k=" & Natural'Image (K));
   end loop;

   for N in 1 .. 8 loop
      for K in 0 .. N loop
         Check
           (Near
              (Binomial (Nat (N), Nat (K)),
               Binomial (Nat (N), Nat (N - K))),
            "C sym n=" & Natural'Image (N) &
            " k=" & Natural'Image (K));
      end loop;
   end loop;

   --  Weights for each |S| sum to 1 over the 2^{n-1} coalitions of i
   for N in 1 .. 7 loop
      declare
         Acc : Worth := 0.0;
         Total_Coalitions : constant Natural := Power2 (PC (N - 1));
      begin
         for Sz in 0 .. N - 1 loop
            --  C(n-1, |S|) coalitions of that size
            Acc := Acc
              + Shapley_Weight (Nat (Sz), PC (N))
              * Binomial (Nat (N - 1), Nat (Sz));
         end loop;
         Check (Near (Acc, 1.0),
                "weights sum to 1 n=" & Natural'Image (N));
         Check (Total_Coalitions = 2 ** (N - 1),
                "2^(n-1) coalitions n=" & Natural'Image (N));
      end;
   end loop;

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
