--  Standalone test suite for Banzhaf_Power_Index.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Banzhaf_Power_Index; use Banzhaf_Power_Index;

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
   function Wth (X : Worth) return Worth is (X);

   function Vec_Near
     (A, B : Index_Vector; Tol : Worth := 1.0E-9) return Boolean
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

   function Counts_Eq (A, B : Count_Vector) return Boolean is
   begin
      if A'First /= B'First or else A'Last /= B'Last then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Counts_Eq;

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

   function Binom_Raises (N, K : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Binomial (N, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Binom_Raises;

   function Power2_Raises (N : Natural) return Boolean is
      Unused : Natural;
   begin
      Unused := Power2 (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Power2_Raises;

   function Weighted_Raises
     (Quota : Natural; Weights : Weight_Vector) return Boolean
   is
      G : Instance;
   begin
      G := Weighted (Quota, Weights);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Weighted_Raises;

   function Char_Raises
     (N : Natural; Winning : Characteristic) return Boolean
   is
      G : Instance;
   begin
      G := From_Characteristic (N, Winning);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Char_Raises;

   function Majority_Raises (N : Natural) return Boolean is
      G : Instance;
   begin
      G := Majority (N);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Majority_Raises;

   function Equal_Raises
     (N : Natural; Each : Natural; Quota : Natural) return Boolean
   is
      G : Instance;
   begin
      G := Equal_Weights (N, Each, Quota);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Equal_Raises;

   function Swing_Null_Raises (N : Natural) return Boolean is
      Eta : Count_Vector (1 .. 1);
   begin
      Eta := Swing_Counts (N, null);
      pragma Unreferenced (Eta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Swing_Null_Raises;

   function Winning_Raises (G : Instance; Mask : Natural) return Boolean is
      Unused : Boolean;
   begin
      Unused := Is_Winning (G, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Winning_Raises;

   function Critical_Raises
     (G : Instance; Mask : Natural; I : Player_Id) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Critical (G, Mask, I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Critical_Raises;

   function Weight_Of_Raises
     (G : Instance; I : Player_Id) return Boolean
   is
      Unused : Natural;
   begin
      Unused := Weight_Of (G, I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Weight_Of_Raises;

   function Quota_Raises (G : Instance) return Boolean is
      Unused : Natural;
   begin
      Unused := Quota_Of (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Quota_Raises;

   function Empty_Swing_Raises return Boolean is
      G   : Instance;
      Eta : Count_Vector (1 .. 1);
   begin
      Eta := Swing_Counts (G);
      pragma Unreferenced (Eta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Swing_Raises;

   function Empty_Abs_Raises return Boolean is
      G    : Instance;
      Beta : Index_Vector (1 .. 1);
   begin
      Beta := Absolute_Banzhaf (G);
      pragma Unreferenced (Beta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Abs_Raises;

   function Empty_Norm_Raises return Boolean is
      G    : Instance;
      Beta : Index_Vector (1 .. 1);
   begin
      Beta := Normalized_Banzhaf (G);
      pragma Unreferenced (Beta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Norm_Raises;

   function Empty_Char_Raises return Boolean is
      G : Instance;
      V : Characteristic (0 .. 0);
   begin
      V := Characteristic_Of (G);
      pragma Unreferenced (V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Char_Raises;

   function Empty_Weights_Raises return Boolean is
      G : Instance;
      W : Weight_Vector (1 .. 1);
   begin
      W := Weights_Of (G);
      pragma Unreferenced (W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Weights_Raises;

   function Norm_Zero_Raises (G : Instance) return Boolean is
      Beta : Index_Vector (1 .. 1);
   begin
      Beta := Normalized_Banzhaf (G);
      pragma Unreferenced (Beta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Norm_Zero_Raises;

   function Coleman_P_Raises (G : Instance) return Boolean is
      Beta : Index_Vector (1 .. 1);
   begin
      Beta := Coleman_Prevent (G);
      pragma Unreferenced (Beta);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Coleman_P_Raises;

   function Dummy_Raises
     (G : Instance; I : Player_Id) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Dummy (G, I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dummy_Raises;

   function Coalition_W_Raises
     (Weights : Weight_Vector; Mask : Natural) return Boolean
   is
      Unused : Long_Long_Integer;
   begin
      Unused := Coalition_Weight (Weights, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Coalition_W_Raises;

   function Weighted_Win_Raises
     (Quota : Natural; Weights : Weight_Vector; Mask : Natural)
      return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Winning (Quota, Weights, Mask);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Weighted_Win_Raises;

   ---------------------------------------------------------------------------
   -- Callbacks used by several sections
   ---------------------------------------------------------------------------

   function Maj3 (Mask : Natural) return Boolean is
   begin
      return Bit_Count (Mask) >= Nat (2);
   end Maj3;

   function Unanim3 (Mask : Natural) return Boolean is
   begin
      return Mask = Nat (7);
   end Unanim3;

   function Dict1_N3 (Mask : Natural) return Boolean is
   begin
      return Has_Player (Mask, Pid (1));
   end Dict1_N3;

   ---------------------------------------------------------------------------
   -- 1. Bitmask helpers
   ---------------------------------------------------------------------------

begin
   Section ("1. Bitmask helpers");

   Check (Player_Bit (Pid (1)) = Nat (1), "bit 1 = 1");
   Check (Player_Bit (Pid (2)) = Nat (2), "bit 2 = 2");
   Check (Player_Bit (Pid (3)) = Nat (4), "bit 3 = 4");
   Check (Player_Bit (Pid (4)) = Nat (8), "bit 4 = 8");
   Check (Player_Bit (Pid (5)) = Nat (16), "bit 5 = 16");
   Check (Player_Bit (Pid (8)) = Nat (128), "bit 8 = 128");

   Check (Bit_Count (Nat (0)) = Nat (0), "pop 0");
   Check (Bit_Count (Nat (1)) = Nat (1), "pop 1");
   Check (Bit_Count (Nat (2)) = Nat (1), "pop 2");
   Check (Bit_Count (Nat (3)) = Nat (2), "pop 3");
   Check (Bit_Count (Nat (7)) = Nat (3), "pop 7");
   Check (Bit_Count (Nat (8)) = Nat (1), "pop 8");
   Check (Bit_Count (Nat (15)) = Nat (4), "pop 15");
   Check (Bit_Count (Nat (255)) = Nat (8), "pop 255");
   Check (Coalition_Size (Nat (5)) = Nat (2), "size rename 5");

   Check (Has_Player (Nat (0), Pid (1)) = False, "empty has 1");
   Check (Has_Player (Nat (1), Pid (1)), "1 has 1");
   Check (Has_Player (Nat (1), Pid (2)) = False, "1 misses 2");
   Check (Has_Player (Nat (5), Pid (1)), "5 has 1");
   Check (Has_Player (Nat (5), Pid (3)), "5 has 3");
   Check (Has_Player (Nat (5), Pid (2)) = False, "5 misses 2");

   Check (Power2 (Nat (0)) = Nat (1), "2^0");
   Check (Power2 (Nat (1)) = Nat (2), "2^1");
   Check (Power2 (Nat (4)) = Nat (16), "2^4");
   Check (Power2 (Nat (8)) = Nat (256), "2^8");
   Check (Power2 (Nat (10)) = Nat (1024), "2^10");
   Check (Power2_Raises (Nat (Max_N + 1)), "2^Max_N+1 raises");
   Check (Power2_Raises (Nat (32)), "2^32 raises");

   ---------------------------------------------------------------------------
   -- 2. Factorial / binomial / Near
   ---------------------------------------------------------------------------
   Section ("2. Factorial, binomial, Near");

   Check (Near (Factorial (Nat (0)), Wth (1.0)), "0!");
   Check (Near (Factorial (Nat (1)), Wth (1.0)), "1!");
   Check (Near (Factorial (Nat (2)), Wth (2.0)), "2!");
   Check (Near (Factorial (Nat (5)), Wth (120.0)), "5!");
   Check (Near (Factorial (Nat (6)), Wth (720.0)), "6!");
   Check (Fact_Raises (Nat (21)), "21! raises");
   Check (Fact_Raises (Nat (30)), "30! raises");

   Check (Binomial (Nat (5), Nat (0)) = Nat (1), "C(5,0)");
   Check (Binomial (Nat (5), Nat (1)) = Nat (5), "C(5,1)");
   Check (Binomial (Nat (5), Nat (2)) = Nat (10), "C(5,2)");
   Check (Binomial (Nat (5), Nat (3)) = Nat (10), "C(5,3)");
   Check (Binomial (Nat (5), Nat (5)) = Nat (1), "C(5,5)");
   Check (Binomial (Nat (6), Nat (3)) = Nat (20), "C(6,3)");
   Check (Binomial (Nat (10), Nat (2)) = Nat (45), "C(10,2)");
   Check (Binomial (Nat (10), Nat (5)) = Nat (252), "C(10,5)");
   Check (Binomial (Nat (4), Nat (5)) = Nat (0), "C(4,5)=0");
   Check (Binomial (Nat (0), Nat (0)) = Nat (1), "C(0,0)");
   Check (Binom_Raises (Nat (21), Nat (1)), "C(21,1) raises");

   Check (Near (Wth (1.0), Wth (1.0)), "near equal");
   Check (Near (Wth (1.0), Wth (1.0 + 1.0E-12)), "near close");
   Check (not Near (Wth (1.0), Wth (1.1)), "near far");
   Check (Near_Raises (Wth (-1.0E-6)), "near tol<0");

   ---------------------------------------------------------------------------
   -- 3. Straffin [6; 4, 3, 2, 1]
   ---------------------------------------------------------------------------
   Section ("3. Straffin [6; 4, 3, 2, 1]");

   declare
      G   : constant Instance := Weighted (6, [4, 3, 2, 1]);
      Eta : constant Count_Vector := Swing_Counts (G);
      Abv : constant Index_Vector := Absolute_Banzhaf (G);
      Nrm : constant Index_Vector := Normalized_Banzhaf (G);
      E2  : constant Count_Vector := Swing_Counts (6, Weight_Vector'[4, 3, 2, 1]);
   begin
      Check (Size (G) = PC (4), "n=4");
      Check (Is_Weighted_Game (G), "weighted form");
      Check (Quota_Of (G) = Nat (6), "quota 6");
      Check (Weight_Of (G, Pid (1)) = Nat (4), "wA=4");
      Check (Weight_Of (G, Pid (2)) = Nat (3), "wB=3");
      Check (Weight_Of (G, Pid (3)) = Nat (2), "wC=2");
      Check (Weight_Of (G, Pid (4)) = Nat (1), "wD=1");
      Check (Eta (1) = Nat (5), "ηA=5");
      Check (Eta (2) = Nat (3), "ηB=3");
      Check (Eta (3) = Nat (3), "ηC=3");
      Check (Eta (4) = Nat (1), "ηD=1");
      Check (Total_Swings (Eta) = Nat (12), "Ση=12");
      Check (Total_Swings (G) = Nat (12), "instance Ση=12");
      Check (Counts_Eq (Eta, E2), "overload matches instance");
      Check (Near (Abv (1), Wth (5.0 / 8.0)), "β'A=5/8");
      Check (Near (Abv (2), Wth (3.0 / 8.0)), "β'B=3/8");
      Check (Near (Abv (3), Wth (3.0 / 8.0)), "β'C=3/8");
      Check (Near (Abv (4), Wth (1.0 / 8.0)), "β'D=1/8");
      Check (Near (Nrm (1), Wth (5.0 / 12.0)), "βA=5/12");
      Check (Near (Nrm (2), Wth (3.0 / 12.0)), "βB=3/12");
      Check (Near (Nrm (3), Wth (3.0 / 12.0)), "βC=3/12");
      Check (Near (Nrm (4), Wth (1.0 / 12.0)), "βD=1/12");
      Check (Is_Normalized (Nrm), "normalized sums to 1");
      Check (Vec_Near (Nrm, Normalized_Banzhaf (6, Weight_Vector'[4, 3, 2, 1])),
             "norm overload");
      Check (Vec_Near (Abv, Absolute_Banzhaf (6, Weight_Vector'[4, 3, 2, 1])),
             "abs overload");
      Check (Vec_Near (Abv, Penrose_Banzhaf (G)), "Penrose alias");
      Check (not Is_Dummy (G, Pid (1)), "A not dummy");
      Check (not Is_Dummy (G, Pid (4)), "D not dummy");
      Check (not Is_Dictator (G, Pid (1)), "A not dictator");
      Check (Is_Vetoer (G, Pid (1)) = False, "A not vetoer");
      Check (Are_Symmetric (G, Pid (2), Pid (3)), "B ~ C");
      Check (not Are_Symmetric (G, Pid (1), Pid (2)), "A !~ B");
      Check (Are_Symmetric (G, Pid (1), Pid (1)), "A ~ A");
   end;

   --  Winning / critical census for Straffin (Wikipedia list).
   declare
      G : constant Instance := Weighted (6, [4, 3, 2, 1]);
      --  masks: A=1 B=2 C=4 D=8
      --  winning: AB=3, AC=5, ABC=7, ABD=11, ACD=13, BCD=14, ABCD=15
      Win_Masks : constant array (Positive range <>) of Natural :=
        [3, 5, 7, 11, 13, 14, 15];
      Lose_Count : Natural := 0;
      Crit_A     : Natural := 0;
   begin
      for M in 0 .. 15 loop
         if Is_Winning (G, M) then
            null;
         else
            Lose_Count := Lose_Count + 1;
         end if;
      end loop;
      Check (Winning_Count (G) = Nat (7), "7 winning coalitions");
      Check (Losing_Count (G) = Nat (9), "9 losing");
      Check (Lose_Count = Nat (9), "census losing");
      Check (Is_Winning (G, Nat (3)), "AB wins");
      Check (Is_Winning (G, Nat (5)), "AC wins");
      Check (not Is_Winning (G, Nat (9)), "AD loses (5<6)");
      Check (not Is_Winning (G, Nat (6)), "BC loses");
      Check (Is_Winning (G, Nat (14)), "BCD wins");
      Check (Is_Winning (6, Weight_Vector'[4, 3, 2, 1], Nat (7)), "ABC via overload");
      Check (Is_Critical (G, Nat (3), Pid (1)), "A crit in AB");
      Check (Is_Critical (G, Nat (3), Pid (2)), "B crit in AB");
      Check (not Is_Critical (G, Nat (3), Pid (3)), "C not in AB");
      Check (Is_Critical (G, Nat (5), Pid (1)), "A crit in AC");
      Check (Is_Critical (G, Nat (14), Pid (2)), "B crit in BCD");
      Check (Is_Critical (G, Nat (14), Pid (3)), "C crit in BCD");
      Check (Is_Critical (G, Nat (14), Pid (4)), "D crit in BCD");
      Check (not Is_Critical (G, Nat (15), Pid (4)), "D not crit in ABCD");
      Check (not Is_Critical (G, Nat (15), Pid (1)), "A not crit in ABCD");
      for M of Win_Masks loop
         if Is_Critical (G, M, Pid (1)) then
            Crit_A := Crit_A + 1;
         end if;
      end loop;
      Check (Crit_A = Nat (5), "A critical in 5 winning coalitions");
      Check (Coalition_Weight ([4, 3, 2, 1], Nat (3)) = 7, "w(AB)=7");
      Check (Coalition_Weight ([4, 3, 2, 1], Nat (0)) = 0, "w(empty)=0");
   end;

   ---------------------------------------------------------------------------
   -- 4. Nassau County [16; 9, 9, 7, 3, 1, 1]
   ---------------------------------------------------------------------------
   Section ("4. Nassau County [16; 9, 9, 7, 3, 1, 1]");

   declare
      G   : constant Instance := Weighted (16, [9, 9, 7, 3, 1, 1]);
      Eta : constant Count_Vector := Swing_Counts (G);
      Nrm : constant Index_Vector := Normalized_Banzhaf (G);
   begin
      Check (Size (G) = PC (6), "n=6");
      Check (Eta (1) = Nat (16), "Hempstead1 η=16");
      Check (Eta (2) = Nat (16), "Hempstead2 η=16");
      Check (Eta (3) = Nat (16), "N.Hempstead η=16");
      Check (Eta (4) = Nat (0), "Oyster Bay η=0");
      Check (Eta (5) = Nat (0), "Glen Cove η=0");
      Check (Eta (6) = Nat (0), "Long Beach η=0");
      Check (Total_Swings (Eta) = Nat (48), "48 swing votes");
      Check (Near (Nrm (1), Wth (16.0 / 48.0)), "β H1=16/48");
      Check (Near (Nrm (4), Wth (0.0)), "β Oyster=0");
      Check (Is_Dummy (G, Pid (4)), "Oyster dummy");
      Check (Is_Dummy (G, Pid (5)), "Glen Cove dummy");
      Check (Is_Dummy (G, Pid (6)), "Long Beach dummy");
      Check (not Is_Dummy (G, Pid (1)), "H1 not dummy");
      Check (Are_Symmetric (G, Pid (1), Pid (2)), "two Hempsteads");
      Check (Are_Symmetric (G, Pid (5), Pid (6)), "two 1-vote towns");
      Check (not Are_Symmetric (G, Pid (3), Pid (4)), "7 !~ 3");
      Check (not Is_Dictator (G, Pid (1)), "no dictator");
   end;

   ---------------------------------------------------------------------------
   -- 5. Majority games (closed form η = C(n-1, q-1))
   ---------------------------------------------------------------------------
   Section ("5. Majority games");

   for N in 1 .. 8 loop
      declare
         G   : constant Instance := Majority (N);
         Q   : constant Natural := N / 2 + 1;
         Exp : constant Natural := Binomial (N - 1, Q - 1);
         Eta : constant Count_Vector := Swing_Counts (G);
         Abv : constant Index_Vector := Absolute_Banzhaf (G);
         Nrm : constant Index_Vector := Normalized_Banzhaf (G);
         Ok  : Boolean := True;
      begin
         Check (Size (G) = PC (N), "maj n size" & Natural'Image (N));
         Check (Quota_Of (G) = Q, "maj quota" & Natural'Image (N));
         for I in Eta'Range loop
            if Eta (I) /= Exp then
               Ok := False;
            end if;
            if not Near (Abv (I), Worth (Exp) / Worth (Power2 (N - 1))) then
               Ok := False;
            end if;
            if not Near (Nrm (I), 1.0 / Worth (N)) then
               Ok := False;
            end if;
            if not Are_Symmetric (G, Eta'First, I) then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "maj closed form n=" & Natural'Image (N));
         Check (Is_Normalized (Nrm), "maj norm n=" & Natural'Image (N));
      end;
   end loop;

   declare
      G : constant Instance := Majority (3);
   begin
      Check (Is_Winning (G, Nat (3)), "maj3 {1,2} wins");
      Check (not Is_Winning (G, Nat (1)), "maj3 singleton loses");
      Check (Is_Critical (G, Nat (3), Pid (1)), "maj3 crit pair");
      Check (not Is_Dictator (G, Pid (1)), "maj3 no dictator");
      Check (not Is_Vetoer (G, Pid (1)), "maj3 no vetoer");
   end;

   ---------------------------------------------------------------------------
   -- 6. UN Security Council toy
   ---------------------------------------------------------------------------
   Section ("6. UN Security Council toy");

   declare
      G   : constant Instance := UN_Security_Council;
      Eta : constant Count_Vector := Swing_Counts (G);
      Nrm : constant Index_Vector := Normalized_Banzhaf (G);
      Abv : constant Index_Vector := Absolute_Banzhaf (G);
      OkP : Boolean := True;
      OkR : Boolean := True;
   begin
      Check (Size (G) = PC (15), "UNSC n=15");
      Check (Quota_Of (G) = Nat (39), "UNSC q=39");
      Check (Weight_Of (G, Pid (1)) = Nat (7), "P5 weight");
      Check (Weight_Of (G, Pid (6)) = Nat (1), "rotating weight");
      for I in 1 .. Pid (5) loop
         if Eta (I) /= Nat (848) then
            OkP := False;
         end if;
         if not Is_Vetoer (G, I) then
            OkP := False;
         end if;
      end loop;
      for I in Pid (6) .. Pid (15) loop
         if Eta (I) /= Nat (84) then
            OkR := False;
         end if;
         if Is_Vetoer (G, I) then
            OkR := False;
         end if;
      end loop;
      Check (OkP, "P5 η=848 and veto");
      Check (OkR, "rotating η=84, no veto");
      Check (Total_Swings (Eta) = Nat (5080), "UNSC Ση=5080");
      Check (Near (Nrm (1), Wth (848.0 / 5080.0)), "P5 β");
      Check (Near (Nrm (15), Wth (84.0 / 5080.0)), "rotating β");
      Check (Near (Abv (1), Wth (848.0 / 16384.0)), "P5 β' / 2^14");
      Check (Is_Normalized (Nrm), "UNSC normalized");
      Check (Are_Symmetric (G, Pid (1), Pid (5)), "P5 symmetric");
      Check (Are_Symmetric (G, Pid (6), Pid (15)), "rotating symmetric");
      Check (not Are_Symmetric (G, Pid (1), Pid (6)), "P5 !~ rotating");
   end;

   ---------------------------------------------------------------------------
   -- 7. Corporate shareholders [51; 40, 30, 20, 10]
   ---------------------------------------------------------------------------
   Section ("7. Corporate shareholders");

   declare
      G   : constant Instance := Corporate_Shareholders;
      Eta : constant Count_Vector := Swing_Counts (G);
      Nrm : constant Index_Vector := Normalized_Banzhaf (G);
      S   : constant Instance := Weighted (6, [4, 3, 2, 1]);
   begin
      Check (Size (G) = PC (4), "corp n=4");
      Check (Quota_Of (G) = Nat (51), "corp q=51");
      Check (Weight_Of (G, Pid (1)) = Nat (40), "40%");
      Check (Counts_Eq (Eta, Swing_Counts (S)),
             "equivalent to Straffin swings");
      Check (Vec_Near (Nrm, Normalized_Banzhaf (S)),
             "equivalent to Straffin β");
      Check (Eta (1) = Nat (5), "corp η1=5");
      Check (Eta (4) = Nat (1), "corp η4=1");
      Check (Is_Normalized (Nrm), "corp normalized");
   end;

   ---------------------------------------------------------------------------
   -- 8. Equal weights / unanimity / dictator
   ---------------------------------------------------------------------------
   Section ("8. Equal weights, unanimity, dictator");

   declare
      U   : constant Instance := Equal_Weights (4, 1, 4);
      Eta : constant Count_Vector := Swing_Counts (U);
      --  Unanimity: only grand coalition wins, every player critical there.
      --  η_i = 1 (S = N \ {i}).
   begin
      Check (Quota_Of (U) = Nat (4), "unan q=4");
      Check (Eta (1) = Nat (1), "unan η1=1");
      Check (Eta (2) = Nat (1), "unan η2=1");
      Check (Eta (3) = Nat (1), "unan η3=1");
      Check (Eta (4) = Nat (1), "unan η4=1");
      Check (Winning_Count (U) = Nat (1), "only grand wins");
      Check (Is_Vetoer (U, Pid (1)), "unan veto 1");
      Check (Is_Vetoer (U, Pid (4)), "unan veto 4");
      Check (Is_Normalized (Normalized_Banzhaf (U)), "unan norm");
      Check (Near (Normalized_Banzhaf (U) (1), Wth (0.25)), "unan β=1/4");
   end;

   declare
      --  Player 1 weight 3, others 1, quota 3 → dictator.
      D   : constant Instance := Weighted (3, [3, 1, 1]);
      Eta : constant Count_Vector := Swing_Counts (D);
   begin
      Check (Is_Dictator (D, Pid (1)), "player 1 dictator");
      Check (not Is_Dictator (D, Pid (2)), "player 2 not");
      Check (Is_Dummy (D, Pid (2)), "player 2 dummy");
      Check (Is_Dummy (D, Pid (3)), "player 3 dummy");
      Check (Eta (1) = Nat (4), "dictator η=2^{2}");
      Check (Eta (2) = Nat (0), "dummy η=0");
      Check (Near (Normalized_Banzhaf (D) (1), Wth (1.0)), "dictator β=1");
      Check (Near (Absolute_Banzhaf (D) (1), Wth (1.0)), "dictator β'=1");
      Check (Is_Vetoer (D, Pid (1)), "dictator is vetoer");
   end;

   declare
      --  Georgia electoral toy: CA=55, TX=38, GA=16, majority of 109 is 55.
      E : constant Instance := Weighted (55, [55, 38, 16]);
   begin
      Check (Is_Dictator (E, Pid (1)), "CA dictator vs GA");
      Check (Is_Dummy (E, Pid (2)), "TX dummy");
      Check (Is_Dummy (E, Pid (3)), "GA dummy");
      Check (Near (Normalized_Banzhaf (E) (1), Wth (1.0)), "CA β=1");
   end;

   declare
      --  CA=55, TX=38, NY=29; total 122; majority 62. Equal power.
      E   : constant Instance := Weighted (62, [55, 38, 29]);
      Eta : constant Count_Vector := Swing_Counts (E);
   begin
      Check (Eta (1) = Nat (2), "CA η=2");
      Check (Eta (2) = Nat (2), "TX η=2");
      Check (Eta (3) = Nat (2), "NY η=2");
      Check (Near (Normalized_Banzhaf (E) (1), Wth (1.0 / 3.0)),
             "three-state β=1/3");
      Check (not Is_Dictator (E, Pid (1)), "CA not dictator at q=62");
   end;

   ---------------------------------------------------------------------------
   -- 9. Simple-game characteristic path
   ---------------------------------------------------------------------------
   Section ("9. Simple-game characteristic");

   declare
      --  Majority n=3 as a 0/1 table.
      V   : constant Characteristic :=
        [0 => 0, 1 => 0, 2 => 0, 3 => 1,
         4 => 0, 5 => 1, 6 => 1, 7 => 1];
      G   : constant Instance := From_Characteristic (3, V);
      Eta : constant Count_Vector := Swing_Counts (G);
      M   : constant Instance := Majority (3);
   begin
      Check (not Is_Weighted_Game (G), "table form");
      Check (Quota_Of (G) = Nat (0), "table quota 0");
      Check (Weight_Of (G, Pid (1)) = Nat (0), "table weight 0");
      Check (Size (G) = PC (3), "table n=3");
      Check (Counts_Eq (Eta, Swing_Counts (M)), "table vs majority η");
      Check (Vec_Near (Normalized_Banzhaf (G), Normalized_Banzhaf (M)),
             "table vs majority β");
      Check (Is_Winning (3, V, Nat (3)), "table {1,2} wins");
      Check (not Is_Winning (3, V, Nat (1)), "table singleton loses");
      Check (Is_Critical (3, V, Nat (3), Pid (2)), "table crit");
      Check (Counts_Eq (Eta, Swing_Counts (3, V)), "table overload");
      declare
         T : constant Characteristic := Characteristic_Of (G);
         Ok : Boolean := True;
      begin
         for K in T'Range loop
            if T (K) /= V (K) then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "Characteristic_Of round-trip");
      end;
   end;

   declare
      --  Glove simple game: win iff contains player 3 and at least one of 1,2.
      V : constant Characteristic :=
        [0 => 0, 1 => 0, 2 => 0, 3 => 0,
         4 => 0, 5 => 1, 6 => 1, 7 => 1];
      G : constant Instance := From_Characteristic (3, V);
      Eta : constant Count_Vector := Swing_Counts (G);
   begin
      Check (Eta (1) = Nat (1), "glove η1=1");
      Check (Eta (2) = Nat (1), "glove η2=1");
      Check (Eta (3) = Nat (3), "glove η3=3");
      Check (Near (Normalized_Banzhaf (G) (3), Wth (3.0 / 5.0)),
             "glove β3=3/5");
      Check (Is_Vetoer (G, Pid (3)), "left glove is vetoer");
      Check (not Is_Dictator (G, Pid (3)), "left glove not dictator");
      Check (Are_Symmetric (G, Pid (1), Pid (2)), "two right gloves");
   end;

   ---------------------------------------------------------------------------
   -- 10. Callback path
   ---------------------------------------------------------------------------
   Section ("10. Callback characteristic");

   declare
      Eta : constant Count_Vector := Swing_Counts (3, Maj3'Access);
      G   : constant Instance := Majority (3);
   begin
      Check (Counts_Eq (Eta, Swing_Counts (G)), "cb maj3");
      Check (Eta (1) = Binomial (2, 1), "cb η=C(2,1)");
   end;

   declare
      Eta : constant Count_Vector := Swing_Counts (3, Unanim3'Access);
   begin
      Check (Eta (1) = Nat (1), "cb unan η1");
      Check (Eta (2) = Nat (1), "cb unan η2");
      Check (Eta (3) = Nat (1), "cb unan η3");
   end;

   declare
      Eta : constant Count_Vector := Swing_Counts (3, Dict1_N3'Access);
   begin
      Check (Eta (1) = Nat (4), "cb dict η1=4");
      Check (Eta (2) = Nat (0), "cb dict η2=0");
      Check (Eta (3) = Nat (0), "cb dict η3=0");
   end;

   ---------------------------------------------------------------------------
   -- 11. Coleman indices
   ---------------------------------------------------------------------------
   Section ("11. Coleman prevent / initiate");

   declare
      G   : constant Instance := Weighted (6, [4, 3, 2, 1]);
      P   : constant Index_Vector := Coleman_Prevent (G);
      I   : constant Index_Vector := Coleman_Initiate (G);
      Eta : constant Count_Vector := Swing_Counts (G);
      W   : constant Worth := Worth (Winning_Count (G));
      L   : constant Worth := Worth (Losing_Count (G));
   begin
      Check (Near (P (1), Worth (Eta (1)) / W), "Coleman prevent A");
      Check (Near (P (4), Worth (Eta (4)) / W), "Coleman prevent D");
      Check (Near (I (1), Worth (Eta (1)) / L), "Coleman initiate A");
      Check (Near (I (2), Worth (Eta (2)) / L), "Coleman initiate B");
      Check (Winning_Count (G) = Nat (7), "ω=7");
      Check (Losing_Count (G) = Nat (9), "λ=9");
   end;

   ---------------------------------------------------------------------------
   -- 12. Instance accessors / Weights_Of
   ---------------------------------------------------------------------------
   Section ("12. Instance accessors");

   declare
      G : constant Instance := Weighted (5, [2, 2, 1]);
      W : constant Weight_Vector := Weights_Of (G);
      V : constant Characteristic := Characteristic_Of (G);
      Empty : Instance;
   begin
      Check (W'Length = Nat (3), "weights length");
      Check (W (1) = Nat (2), "w1");
      Check (W (3) = Nat (1), "w3");
      Check (V'First = Nat (0), "char first");
      Check (V'Length = Nat (8), "char length 8");
      Check (V (0) = Nat (0), "empty loses");
      Check (V (1) = Nat (0), "{1} loses");
      Check (V (3) = Nat (0), "{1,2} loses 4<5");
      Check (Size (Empty) = PC (0), "default empty");
      Check (not Is_Weighted_Game (Empty), "empty not weighted");
   end;

   ---------------------------------------------------------------------------
   -- 13. Invalid_Argument
   ---------------------------------------------------------------------------
   Section ("13. Invalid_Argument");

   Check (Weighted_Raises (Nat (0), [1, 1]), "quota 0");
   Check (Majority_Raises (Nat (0)), "majority n=0");
   Check (Majority_Raises (Nat (17)), "majority n=17");
   Check (Equal_Raises (Nat (0), Nat (1), Nat (1)), "equal n=0");
   Check (Equal_Raises (Nat (3), Nat (1), Nat (0)), "equal quota 0");
   Check (Swing_Null_Raises (Nat (3)), "null callback");
   Check (Swing_Null_Raises (Nat (0)), "null callback n=0");

   declare
      Bad_First : constant Characteristic (1 .. 4) := [0, 0, 0, 1];
      Bad_Len   : constant Characteristic (0 .. 2) := [0, 0, 1];
      Bad_Val   : constant Characteristic (0 .. 3) := [0, 0, 0, 2];
      Empty_Win : constant Characteristic (0 .. 3) := [1, 1, 1, 1];
      Non_Mono  : constant Characteristic (0 .. 3) := [0, 1, 0, 0];
   begin
      Check (Char_Raises (Nat (2), Bad_First), "char not 0-based");
      Check (Char_Raises (Nat (2), Bad_Len), "char wrong length");
      Check (Char_Raises (Nat (2), Bad_Val), "char entry=2");
      Check (Char_Raises (Nat (2), Empty_Win), "empty winning");
      Check (Char_Raises (Nat (2), Non_Mono), "non-monotonic");
      Check (Char_Raises (Nat (0), [0 => 0]), "char n=0");
   end;

   declare
      G : constant Instance := Majority (3);
   begin
      Check (Winning_Raises (G, Nat (8)), "mask 8 for n=3");
      Check (Critical_Raises (G, Nat (8), Pid (1)), "crit mask OOB");
      Check (Critical_Raises (G, Nat (1), Pid (4)), "crit player OOB");
      Check (Weight_Of_Raises (G, Pid (4)), "weight player OOB");
      Check (Dummy_Raises (G, Pid (4)), "dummy player OOB");
   end;

   declare
      Empty : Instance;
   begin
      Check (Quota_Raises (Empty), "quota of empty");
      Check (Empty_Swing_Raises, "swing empty");
      Check (Empty_Abs_Raises, "abs empty");
      Check (Empty_Norm_Raises, "norm empty");
      Check (Empty_Char_Raises, "char of empty");
      Check (Empty_Weights_Raises, "weights of empty");
      Check (Dummy_Raises (Empty, Pid (1)), "dummy empty");
      Check (Winning_Raises (Empty, Nat (0)), "win empty");
   end;

   declare
      --  Quota above total weight: no winning coalition, Ση = 0.
      Dead : constant Instance := Weighted (100, [1, 1, 1]);
   begin
      Check (Winning_Count (Dead) = Nat (0), "dead ω=0");
      Check (Swing_Counts (Dead) (1) = Nat (0), "dead η=0");
      Check (Norm_Zero_Raises (Dead), "norm dead raises");
      Check (Coleman_P_Raises (Dead), "Coleman prevent dead");
      Check (Near (Absolute_Banzhaf (Dead) (1), Wth (0.0)),
             "abs dead = 0");
   end;

   declare
      Off : constant Weight_Vector (2 .. 4) := [1, 1, 1];
   begin
      Check (Weighted_Raises (Nat (2), Off), "weights not 1-based");
      Check (Coalition_W_Raises (Off, Nat (0)), "coal. weight bounds");
      Check (Weighted_Win_Raises (Nat (2), Off, Nat (0)),
             "win overload bounds");
   end;

   Check (Weighted_Win_Raises (Nat (2), [1, 1], Nat (4)),
          "win overload mask OOB");

   ---------------------------------------------------------------------------
   -- 14. [3; 2, 1, 1] Banzhaf vs note on Shapley–Shubik
   ---------------------------------------------------------------------------
   Section ("14. [3; 2, 1, 1] and dummy-weight player");

   declare
      G   : constant Instance := Weighted (3, [2, 1, 1]);
      Eta : constant Count_Vector := Swing_Counts (G);
      Nrm : constant Index_Vector := Normalized_Banzhaf (G);
   begin
      Check (Eta (1) = Nat (3), "[3;2,1,1] ηA=3");
      Check (Eta (2) = Nat (1), "[3;2,1,1] ηB=1");
      Check (Eta (3) = Nat (1), "[3;2,1,1] ηC=1");
      Check (Near (Nrm (1), Wth (3.0 / 5.0)), "βA=3/5 (≠ SS 4/6)");
      Check (Near (Nrm (2), Wth (1.0 / 5.0)), "βB=1/5");
      Check (Is_Normalized (Nrm), "[3;2,1,1] norm");
      Check (not Is_Dictator (G, Pid (1)), "A not dictator");
      Check (Is_Vetoer (G, Pid (1)), "A is vetoer");
   end;

   declare
      --  Zero-weight dummy alongside a majority of two.
      G   : constant Instance := Weighted (2, [1, 1, 0]);
      Eta : constant Count_Vector := Swing_Counts (G);
   begin
      Check (Eta (1) = Nat (2), "zero-w η1");
      Check (Eta (2) = Nat (2), "zero-w η2");
      Check (Eta (3) = Nat (0), "zero-w dummy");
      Check (Is_Dummy (G, Pid (3)), "zero weight dummy");
      Check (Are_Symmetric (G, Pid (1), Pid (2)), "two unit weights");
      Check (not Are_Symmetric (G, Pid (1), Pid (3)), "unit !~ zero");
   end;

   ---------------------------------------------------------------------------
   -- 15. One- and two-player games
   ---------------------------------------------------------------------------
   Section ("15. One- and two-player games");

   declare
      One : constant Instance := Majority (1);
      Eta : constant Count_Vector := Swing_Counts (One);
   begin
      Check (Size (One) = PC (1), "n=1");
      Check (Eta (1) = Nat (1), "n=1 η=1");
      Check (Near (Absolute_Banzhaf (One) (1), Wth (1.0)), "n=1 β'=1");
      Check (Near (Normalized_Banzhaf (One) (1), Wth (1.0)), "n=1 β=1");
      Check (Is_Dictator (One, Pid (1)), "n=1 dictator");
      Check (Is_Vetoer (One, Pid (1)), "n=1 vetoer");
      Check (Is_Winning (One, Nat (1)), "n=1 {1} wins");
      Check (not Is_Winning (One, Nat (0)), "n=1 empty loses");
      Check (Is_Critical (One, Nat (1), Pid (1)), "n=1 critical");
   end;

   declare
      Two : constant Instance := Majority (2);
      Eta : constant Count_Vector := Swing_Counts (Two);
   begin
      --  q=2, both needed. η_i = C(1,1) = 1.
      Check (Eta (1) = Nat (1), "maj2 η1=1");
      Check (Eta (2) = Nat (1), "maj2 η2=1");
      Check (Is_Vetoer (Two, Pid (1)), "maj2 veto");
      Check (not Is_Dictator (Two, Pid (1)), "maj2 not dictator");
      Check (Near (Normalized_Banzhaf (Two) (1), Wth (0.5)), "maj2 β=1/2");
   end;

   ---------------------------------------------------------------------------
   -- 16. Batch micro-checks
   ---------------------------------------------------------------------------
   Section ("16. Batch micro-checks");

   for K in 0 .. 6 loop
      Check (Near (Factorial (Nat (K)) * Worth (K + 1),
                   Factorial (Nat (K + 1))),
             "fact recurrence k=" & Natural'Image (K));
   end loop;

   for N in 1 .. 8 loop
      for K in 0 .. N loop
         Check
           (Binomial (Nat (N), Nat (K)) = Binomial (Nat (N), Nat (N - K)),
            "C sym n=" & Natural'Image (N) &
            " k=" & Natural'Image (K));
      end loop;
   end loop;

   --  Pascal identity C(n,k) = C(n-1,k) + C(n-1,k-1) for 1 ≤ k ≤ n, n≤8.
   for N in 1 .. 6 loop
      for K in 1 .. N loop
         Check
           (Binomial (Nat (N), Nat (K))
            = Binomial (Nat (N - 1), Nat (K))
            + Binomial (Nat (N - 1), Nat (K - 1)),
            "Pascal n=" & Natural'Image (N) &
            " k=" & Natural'Image (K));
      end loop;
   end loop;

   --  Absolute coordinates lie in [0, 1]; normalized sum to 1.
   declare
      Games : constant array (Positive range <>) of Instance :=
        [Majority (4),
         Weighted (6, [4, 3, 2, 1]),
         Equal_Weights (5, 2, 6),
         Corporate_Shareholders];
   begin
      for G of Games loop
         declare
            Abv : constant Index_Vector := Absolute_Banzhaf (G);
            Nrm : constant Index_Vector := Normalized_Banzhaf (G);
            Ok  : Boolean := True;
         begin
            for I in Abv'Range loop
               if Abv (I) < 0.0 or else Abv (I) > 1.0 + 1.0E-12 then
                  Ok := False;
               end if;
               if Nrm (I) < 0.0 then
                  Ok := False;
               end if;
            end loop;
            Check (Ok, "range n=" & Player_Count'Image (Size (G)));
            Check (Is_Normalized (Nrm),
                   "sum1 n=" & Player_Count'Image (Size (G)));
         end;
      end loop;
   end;

   --  Weights_Of / Characteristic_Of agree with Is_Winning on majority n=4.
   declare
      G : constant Instance := Majority (4);
      V : constant Characteristic := Characteristic_Of (G);
      Ok : Boolean := True;
   begin
      for M in 0 .. 15 loop
         if (V (M) = 1) /= Is_Winning (G, M) then
            Ok := False;
         end if;
         if (Bit_Count (M) >= 3) /= Is_Winning (G, M) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "maj4 table agrees with quota");
   end;

   --  Equal_Weights(n,1,n/2+1) coincides with Majority(n).
   for N in 2 .. 6 loop
      declare
         A : constant Instance := Majority (N);
         B : constant Instance := Equal_Weights (N, 1, N / 2 + 1);
      begin
         Check (Counts_Eq (Swing_Counts (A), Swing_Counts (B)),
                "equal≡maj n=" & Natural'Image (N));
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
