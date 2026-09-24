--  Nucleolus body — excesses, lex order, grid search, special games.

pragma Ada_2022;

package body Nucleolus
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Near
   ---------------------------------------------------------------------------

   function Near
     (A, B : Worth; Tol : Worth := Default_Tol) return Boolean
   is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
      return abs (A - B) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Bitmask helpers
   ---------------------------------------------------------------------------

   function Player_Bit (I : Player_Id) return Natural is
   begin
      return 2 ** (Natural (I) - 1);
   end Player_Bit;

   function Bit_Count (Mask : Natural) return Natural is
      M : Natural := Mask;
      C : Natural := 0;
   begin
      while M > 0 loop
         C := C + (M mod 2);
         M := M / 2;
      end loop;
      return C;
   end Bit_Count;

   function Has_Player (Mask : Natural; I : Player_Id) return Boolean is
   begin
      return (Mask / Player_Bit (I)) mod 2 = 1;
   end Has_Player;

   function Power2 (N : Natural) return Natural is
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      return 2 ** N;
   end Power2;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Table (N : Natural; V : Characteristic) is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if V'First /= 0 or else V'Length /= Power2 (N) then
         raise Invalid_Argument;
      end if;
   end Require_Table;

   procedure Require_Allocation (N : Natural; X : Allocation) is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if X'First /= 1 or else Natural (X'Last) /= N then
         raise Invalid_Argument;
      end if;
   end Require_Allocation;

   procedure Require_Tol (Tol : Worth) is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
   end Require_Tol;

   ---------------------------------------------------------------------------
   -- Sums
   ---------------------------------------------------------------------------

   function Sum_Allocation (X : Allocation) return Worth is
      S : Worth := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I);
      end loop;
      return S;
   end Sum_Allocation;

   function Coalition_Payoff
     (X : Allocation; Mask : Natural) return Worth
   is
      S : Worth := 0.0;
      M : Natural := Mask;
      I : Natural := 1;
   begin
      if X'First /= 1 then
         raise Invalid_Argument;
      end if;
      while M > 0 loop
         if M mod 2 = 1 then
            if I > Natural (X'Last) then
               raise Invalid_Argument;
            end if;
            S := S + X (Player_Id (I));
         end if;
         M := M / 2;
         I := I + 1;
      end loop;
      return S;
   end Coalition_Payoff;

   ---------------------------------------------------------------------------
   -- Efficiency / IR / imputation
   ---------------------------------------------------------------------------

   function Is_Efficient
     (X     : Allocation;
      Grand : Worth;
      Tol   : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Tol (Tol);
      return Near (Sum_Allocation (X), Grand, Tol);
   end Is_Efficient;

   function Is_Individually_Rational
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      Require_Tol (Tol);
      for I in 1 .. Player_Id (N) loop
         if X (I) + Tol < V (Player_Bit (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Individually_Rational;

   function Is_Imputation
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      Require_Tol (Tol);
      if not Near (Sum_Allocation (X), V (Power2 (N) - 1), Tol) then
         return False;
      end if;
      for I in 1 .. Player_Id (N) loop
         if X (I) + Tol < V (Player_Bit (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Imputation;

   function Imputation_Set_Nonempty
     (N   : Natural;
      V   : Characteristic;
      Tol : Worth := Default_Tol) return Boolean
   is
      Sum_Sing : Worth := 0.0;
   begin
      Require_Table (N, V);
      Require_Tol (Tol);
      for I in 1 .. Player_Id (N) loop
         Sum_Sing := Sum_Sing + V (Player_Bit (I));
      end loop;
      return V (Power2 (N) - 1) + Tol >= Sum_Sing;
   end Imputation_Set_Nonempty;

   ---------------------------------------------------------------------------
   -- Excess / sort / lex
   ---------------------------------------------------------------------------

   function Excess
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural) return Worth
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      if Mask > Power2 (N) - 1 then
         raise Invalid_Argument;
      end if;
      return V (Mask) - Coalition_Payoff (X, Mask);
   end Excess;

   function Max_Excess
     (N : Natural; V : Characteristic; X : Allocation) return Worth
   is
      All_M : Natural;
      Best  : Worth;
      E     : Worth;
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      All_M := Power2 (N) - 1;
      Best  := Excess (N, V, X, 0);
      for Mask in 1 .. All_M loop
         E := Excess (N, V, X, Mask);
         if E > Best then
            Best := E;
         end if;
      end loop;
      return Best;
   end Max_Excess;

   procedure Sort_Nonincreasing (A : in out Excess_Vector) is
      Tmp : Worth;
   begin
      --  Simple insertion sort (2^N ≤ 256).
      for I in A'First + 1 .. A'Last loop
         Tmp := A (I);
         declare
            J : Integer := I - 1;
         begin
            while J >= Integer (A'First) and then A (Natural (J)) < Tmp loop
               A (Natural (J + 1)) := A (Natural (J));
               J := J - 1;
            end loop;
            A (Natural (J + 1)) := Tmp;
         end;
      end loop;
   end Sort_Nonincreasing;

   function Sorted_Excess_Vector
     (N : Natural; V : Characteristic; X : Allocation) return Excess_Vector
   is
      All_M : constant Natural := Power2 (N) - 1;
      A     : Excess_Vector (0 .. All_M);
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      for Mask in 0 .. All_M loop
         A (Mask) := V (Mask) - Coalition_Payoff (X, Mask);
      end loop;
      Sort_Nonincreasing (A);
      return A;
   end Sorted_Excess_Vector;

   function Lex_Compare
     (Left, Right : Excess_Vector; Tol : Worth := Default_Tol)
      return Lex_Order
   is
   begin
      Require_Tol (Tol);
      if Left'Length /= Right'Length then
         raise Invalid_Argument;
      end if;
      if Left'Length = 0 then
         return Equal;
      end if;
      declare
         L0 : constant Natural := Left'First;
         R0 : constant Natural := Right'First;
         D  : Worth;
      begin
         for K in 0 .. Left'Length - 1 loop
            D := Left (L0 + K) - Right (R0 + K);
            if D < -Tol then
               return Left_Better;
            elsif D > Tol then
               return Right_Better;
            end if;
         end loop;
         return Equal;
      end;
   end Lex_Compare;

   function Allocations_Near
     (A, B : Allocation; Tol : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Tol (Tol);
      if A'First /= B'First or else A'Last /= B'Last then
         return False;
      end if;
      for I in A'Range loop
         if not Near (A (I), B (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Allocations_Near;

   ---------------------------------------------------------------------------
   -- Grid-search nucleolus
   ---------------------------------------------------------------------------

   function Auto_Step (Surplus : Worth; N : Natural) return Worth is
      Divs : Natural;
   begin
      if N <= 2 then
         Divs := 40;
      elsif N = 3 then
         Divs := 30;
      elsif N = 4 then
         Divs := 20;
      elsif N = 5 then
         Divs := 14;
      else
         Divs := 10;
      end if;
      if abs (Surplus) < 1.0E-15 then
         return 1.0;  --  unused when surplus ≈ 0
      end if;
      return abs (Surplus) / Worth (Divs);
   end Auto_Step;

   function Find_Nucleolus
     (N         : Natural;
      V         : Characteristic;
      Grid_Step : Worth := 0.0;
      Tol       : Worth := Default_Tol) return Allocation
   is
      Grand   : Worth;
      Surplus : Worth;
      Step    : Worth;
      Sum_L   : Worth := 0.0;
   begin
      Require_Table (N, V);
      Require_Tol (Tol);
      if N > Max_Search_N then
         raise Invalid_Argument;
      end if;
      if Grid_Step < 0.0 then
         raise Invalid_Argument;
      end if;

      Grand := V (Power2 (N) - 1);

      declare
         Lower    : Allocation (1 .. Player_Id (N));
         Best     : Allocation (1 .. Player_Id (N));
         Trial    : Allocation (1 .. Player_Id (N));
         Best_Ex  : Excess_Vector (0 .. Power2 (N) - 1);
         Trial_Ex : Excess_Vector (0 .. Power2 (N) - 1);
         Have     : Boolean := False;

         procedure Consider (Cand : Allocation) is
            Ord : Lex_Order;
         begin
            if not Is_Imputation (N, V, Cand, Tol) then
               return;
            end if;
            Trial_Ex := Sorted_Excess_Vector (N, V, Cand);
            if not Have then
               Best := Cand;
               Best_Ex := Trial_Ex;
               Have := True;
            else
               Ord := Lex_Compare (Trial_Ex, Best_Ex, Tol);
               if Ord = Left_Better then
                  Best := Cand;
                  Best_Ex := Trial_Ex;
               end if;
            end if;
         end Consider;

         procedure Recurse (P : Natural; Remain : Worth) is
            K     : Natural;
            Share : Worth;
         begin
            if P = N then
               Trial (Player_Id (N)) := Lower (Player_Id (N)) + Remain;
               Consider (Trial);
               return;
            end if;
            if Step <= 0.0 then
               Trial (Player_Id (P)) := Lower (Player_Id (P));
               Recurse (P + 1, Remain);
               return;
            end if;
            K := 0;
            loop
               Share := Worth (K) * Step;
               exit when Share > Remain + Tol * 0.5;
               Trial (Player_Id (P)) := Lower (Player_Id (P)) + Share;
               Recurse (P + 1, Remain - Share);
               K := K + 1;
               exit when K > 10_000;
            end loop;
            if Remain >= -Tol then
               Trial (Player_Id (P)) := Lower (Player_Id (P)) + Remain;
               Recurse (P + 1, 0.0);
            end if;
         end Recurse;

         procedure Refine_Local is
            Nudge     : Worth;
            Other     : Player_Id;
            Improved  : Boolean;
            Passes    : Natural := 0;
            Step_Delta : Worth;
         begin
            if not Have or else N < 2 then
               return;
            end if;
            Nudge := Step;
            if Nudge <= 0.0 then
               Nudge := Auto_Step (abs (Surplus) + 1.0, N) * 0.25;
            end if;
            if Nudge <= 0.0 then
               Nudge := 0.01;
            end if;
            loop
               Improved := False;
               Passes := Passes + 1;
               exit when Passes > 40;
               for I in 1 .. Player_Id (N) loop
                  if I = Player_Id (N) then
                     Other := 1;
                  else
                     Other := Player_Id (Natural (I) + 1);
                  end if;
                  for Sign in 1 .. 2 loop
                     if Sign = 1 then
                        Step_Delta := Nudge;
                     else
                        Step_Delta := -Nudge;
                     end if;
                     Trial := Best;
                     Trial (I) := Trial (I) + Step_Delta;
                     Trial (Other) := Trial (Other) - Step_Delta;
                     if Is_Imputation (N, V, Trial, Tol) then
                        Trial_Ex := Sorted_Excess_Vector (N, V, Trial);
                        if Lex_Compare (Trial_Ex, Best_Ex, Tol) = Left_Better
                        then
                           Best := Trial;
                           Best_Ex := Trial_Ex;
                           Improved := True;
                        end if;
                     end if;
                  end loop;
               end loop;
               if not Improved then
                  Nudge := Nudge * 0.5;
                  exit when Nudge < Tol * 10.0 or else Nudge < 1.0E-12;
               end if;
            end loop;
         end Refine_Local;

      begin
         for I in 1 .. Player_Id (N) loop
            Lower (I) := V (Player_Bit (I));
            Sum_L := Sum_L + Lower (I);
         end loop;
         Surplus := Grand - Sum_L;
         if Surplus < -Tol then
            raise Invalid_Argument;
         end if;

         if N = 1 then
            Best (1) := Grand;
            return Best;
         end if;

         if Grid_Step = 0.0 then
            Step := Auto_Step (Surplus, N);
         else
            Step := Grid_Step;
         end if;

         for I in 1 .. Player_Id (N) loop
            Trial (I) := Lower (I) + Surplus / Worth (N);
         end loop;
         Consider (Trial);

         for J in 1 .. Player_Id (N) loop
            for I in 1 .. Player_Id (N) loop
               Trial (I) := Lower (I);
            end loop;
            Trial (J) := Trial (J) + Surplus;
            Consider (Trial);
         end loop;

         Recurse (1, Surplus);
         Refine_Local;

         if not Have then
            raise Invalid_Argument;
         end if;
         return Best;
      end;
   end Find_Nucleolus;

   function Compute
     (N : Natural; V : Characteristic) return Allocation
   is
   begin
      return Find_Nucleolus (N, V);
   end Compute;

   ---------------------------------------------------------------------------
   -- Special-game constructors
   ---------------------------------------------------------------------------

   function Make_Additive (Singleton : Allocation) return Characteristic is
      N     : constant Natural := Natural (Singleton'Length);
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
      S     : Worth;
   begin
      if Singleton'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         S := 0.0;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (Mask, I) then
               S := S + Singleton (I);
            end if;
         end loop;
         V (Mask) := S;
      end loop;
      return V;
   end Make_Additive;

   function Make_Gloves return Characteristic is
      V : Characteristic (0 .. 7) := [others => 0.0];
   begin
      V (5) := 1.0;
      V (6) := 1.0;
      V (7) := 1.0;
      return V;
   end Make_Gloves;

   function Make_Pair_Gloves return Characteristic is
      V : Characteristic (0 .. 3) := [others => 0.0];
   begin
      V (1) := 5.0;
      V (2) := 5.0;
      V (3) := 15.0;
      return V;
   end Make_Pair_Gloves;

   function Make_Majority (N : Natural) return Characteristic is
      All_M : Natural;
      Need  : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      Need  := N / 2 + 1;
      for Mask in 0 .. All_M loop
         if Bit_Count (Mask) >= Need then
            V (Mask) := 1.0;
         else
            V (Mask) := 0.0;
         end if;
      end loop;
      return V;
   end Make_Majority;

   function Make_Unanimity (N : Natural) return Characteristic is
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      V (All_M) := 1.0;
      return V;
   end Make_Unanimity;

   function Make_Zero (N : Natural) return Characteristic is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      declare
         V : constant Characteristic (0 .. Power2 (N) - 1) :=
           [others => 0.0];
      begin
         return V;
      end;
   end Make_Zero;

   function Make_Bankruptcy
     (Estate : Worth; Claims : Allocation) return Characteristic
   is
      N     : constant Natural := Natural (Claims'Length);
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
      Outside : Worth;
   begin
      if Claims'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if Estate < 0.0 then
         raise Invalid_Argument;
      end if;
      for I in Claims'Range loop
         if Claims (I) < 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         Outside := 0.0;
         for I in 1 .. Player_Id (N) loop
            if not Has_Player (Mask, I) then
               Outside := Outside + Claims (I);
            end if;
         end loop;
         V (Mask) := Worth'Max (0.0, Estate - Outside);
      end loop;
      return V;
   end Make_Bankruptcy;

   function Make_Airport (Costs : Allocation) return Characteristic is
      N     : constant Natural := Natural (Costs'Length);
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
      Mx    : Worth;
   begin
      if Costs'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      for I in Costs'Range loop
         if Costs (I) < 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;
      --  Require nondecreasing costs in player index.
      for I in 2 .. Player_Id (N) loop
         if Costs (I) + 1.0E-15 < Costs (Player_Id (Natural (I) - 1)) then
            raise Invalid_Argument;
         end if;
      end loop;
      All_M := Power2 (N) - 1;
      V (0) := 0.0;
      for Mask in 1 .. All_M loop
         Mx := 0.0;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (Mask, I) and then Costs (I) > Mx then
               Mx := Costs (I);
            end if;
         end loop;
         V (Mask) := -Mx;
      end loop;
      return V;
   end Make_Airport;

   ---------------------------------------------------------------------------
   -- Closed-form nucleoli
   ---------------------------------------------------------------------------

   function Additive_Nucleolus (Singleton : Allocation) return Allocation is
   begin
      if Singleton'First /= 1
        or else Singleton'Length = 0
        or else Singleton'Length > Max_N
      then
         raise Invalid_Argument;
      end if;
      return Singleton;
   end Additive_Nucleolus;

   function Gloves_Nucleolus return Allocation is
   begin
      return Allocation'(1 => 0.0, 2 => 0.0, 3 => 1.0);
   end Gloves_Nucleolus;

   function Pair_Gloves_Nucleolus return Allocation is
   begin
      return Allocation'(1 => 7.5, 2 => 7.5);
   end Pair_Gloves_Nucleolus;

   function Equal_Split_Nucleolus
     (N : Natural; Grand : Worth) return Allocation
   is
      X : Allocation (1 .. Player_Id (N));
      S : Worth;
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      S := Grand / Worth (N);
      for I in X'Range loop
         X (I) := S;
      end loop;
      return X;
   end Equal_Split_Nucleolus;

   function Unanimity_Nucleolus (N : Natural) return Allocation is
   begin
      return Equal_Split_Nucleolus (N, 1.0);
   end Unanimity_Nucleolus;

   function Majority_Nucleolus (N : Natural) return Allocation is
   begin
      return Equal_Split_Nucleolus (N, 1.0);
   end Majority_Nucleolus;

   function Zero_Nucleolus (N : Natural) return Allocation is
   begin
      return Equal_Split_Nucleolus (N, 0.0);
   end Zero_Nucleolus;

   function Contested_Garment
     (Estate : Worth; Claim_1, Claim_2 : Worth) return Allocation
   is
      U1, U2, Rest : Worth;
      X : Allocation (1 .. 2);
   begin
      if Estate < 0.0 or else Claim_1 < 0.0 or else Claim_2 < 0.0 then
         raise Invalid_Argument;
      end if;
      U1 := Worth'Max (0.0, Estate - Claim_2);
      U2 := Worth'Max (0.0, Estate - Claim_1);
      Rest := Estate - U1 - U2;
      X (1) := U1 + Rest / 2.0;
      X (2) := U2 + Rest / 2.0;
      return X;
   end Contested_Garment;

   --  Constrained equal awards: find λ with Σ min(d_i, λ) = E.
   function CEA
     (Estate : Worth; Claims : Allocation) return Allocation
   is
      N : constant Natural := Natural (Claims'Length);
      X : Allocation (1 .. Player_Id (N));
      Lo, Hi, Mid, Sum, Cap_Sum : Worth;
   begin
      if Estate <= 0.0 then
         for I in X'Range loop
            X (I) := 0.0;
         end loop;
         return X;
      end if;
      Cap_Sum := 0.0;
      Hi := 0.0;
      for I in Claims'Range loop
         Cap_Sum := Cap_Sum + Claims (I);
         if Claims (I) > Hi then
            Hi := Claims (I);
         end if;
      end loop;
      if Cap_Sum <= Estate + 1.0E-12 then
         return Claims;
      end if;
      Lo := 0.0;
      for Iter in 1 .. 100 loop
         Mid := (Lo + Hi) / 2.0;
         Sum := 0.0;
         for I in Claims'Range loop
            Sum := Sum + Worth'Min (Claims (I), Mid);
         end loop;
         if Sum < Estate then
            Lo := Mid;
         else
            Hi := Mid;
         end if;
      end loop;
      Mid := (Lo + Hi) / 2.0;
      for I in Claims'Range loop
         X (I) := Worth'Min (Claims (I), Mid);
      end loop;
      return X;
   end CEA;

   function Talmud_Nucleolus
     (Estate : Worth; Claims : Allocation) return Allocation
   is
      N : constant Natural := Natural (Claims'Length);
      Half : Allocation (1 .. Player_Id (N));
      Sum_Half : Worth := 0.0;
      Sum_D : Worth := 0.0;
      X : Allocation (1 .. Player_Id (N));
      Dual : Allocation (1 .. Player_Id (N));
   begin
      if Claims'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if Estate < 0.0 then
         raise Invalid_Argument;
      end if;
      for I in Claims'Range loop
         if Claims (I) < 0.0 then
            raise Invalid_Argument;
         end if;
         Half (I) := Claims (I) / 2.0;
         Sum_Half := Sum_Half + Half (I);
         Sum_D := Sum_D + Claims (I);
      end loop;
      if Estate <= Sum_Half + 1.0E-15 then
         return CEA (Estate, Half);
      else
         --  x_i = d_i − CEA_i (Σ d − E; d/2)
         Dual := CEA (Sum_D - Estate, Half);
         for I in X'Range loop
            X (I) := Claims (I) - Dual (I);
         end loop;
         return X;
      end if;
   end Talmud_Nucleolus;

   function Airport_Nucleolus (Costs : Allocation) return Allocation is
      N : constant Natural := Natural (Costs'Length);
      X : Allocation (1 .. Player_Id (N));
      Prev : Worth := 0.0;
      Diff : Worth;
      Share : Worth;
   begin
      if Costs'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      for I in Costs'Range loop
         if Costs (I) < 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;
      for I in 2 .. Player_Id (N) loop
         if Costs (I) + 1.0E-15 < Costs (Player_Id (Natural (I) - 1)) then
            raise Invalid_Argument;
         end if;
      end loop;
      for I in X'Range loop
         X (I) := 0.0;
      end loop;
      --  Positive cost shares, then negate for TU worth nucleolus.
      for J in 1 .. Player_Id (N) loop
         Diff := Costs (J) - Prev;
         Share := Diff / Worth (N - Natural (J) + 1);
         for I in J .. Player_Id (N) loop
            X (I) := X (I) + Share;
         end loop;
         Prev := Costs (J);
      end loop;
      for I in X'Range loop
         X (I) := -X (I);
      end loop;
      return X;
   end Airport_Nucleolus;

   ---------------------------------------------------------------------------
   -- Instance
   ---------------------------------------------------------------------------

   procedure Clear (Inst : in out Instance; Size : Natural) is
   begin
      if Size > Max_N then
         raise Invalid_Argument;
      end if;
      Inst.N := Player_Count (Size);
      Inst.V := [others => 0.0];
   end Clear;

   function Size (Inst : Instance) return Player_Count is
   begin
      return Inst.N;
   end Size;

   procedure Set_Worth
     (Inst : in out Instance; Mask : Natural; W : Worth)
   is
   begin
      if Natural (Inst.N) = 0 or else Mask >= Power2 (Natural (Inst.N)) then
         raise Invalid_Argument;
      end if;
      Inst.V (Mask) := W;
   end Set_Worth;

   function Get_Worth (Inst : Instance; Mask : Natural) return Worth is
   begin
      if Natural (Inst.N) = 0 or else Mask >= Power2 (Natural (Inst.N)) then
         raise Invalid_Argument;
      end if;
      return Inst.V (Mask);
   end Get_Worth;

   procedure Load (Inst : in out Instance; V : Characteristic) is
      Len : constant Natural := V'Length;
      N   : Natural := 0;
      P   : Natural := 1;
   begin
      if V'First /= 0 then
         raise Invalid_Argument;
      end if;
      if Len = 1 then
         Inst.N := 0;
         Inst.V := [others => 0.0];
         Inst.V (0) := V (0);
         return;
      end if;
      while P < Len loop
         N := N + 1;
         P := P * 2;
         if N > Max_N then
            raise Invalid_Argument;
         end if;
      end loop;
      if P /= Len then
         raise Invalid_Argument;
      end if;
      Inst.N := Player_Count (N);
      Inst.V := [others => 0.0];
      for M in V'Range loop
         Inst.V (M) := V (M);
      end loop;
   end Load;

   function Grand_Worth (Inst : Instance) return Worth is
   begin
      if Natural (Inst.N) = 0 then
         return Inst.V (0);
      end if;
      return Inst.V (Power2 (Natural (Inst.N)) - 1);
   end Grand_Worth;

   function Is_Imputation
     (Inst : Instance;
      X    : Allocation;
      Tol  : Worth := Default_Tol) return Boolean
   is
   begin
      return Is_Imputation
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         X,
         Tol);
   end Is_Imputation;

   function Excess
     (Inst : Instance;
      X    : Allocation;
      Mask : Natural) return Worth
   is
   begin
      return Excess
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         X,
         Mask);
   end Excess;

   function Find_Nucleolus
     (Inst      : Instance;
      Grid_Step : Worth := 0.0;
      Tol       : Worth := Default_Tol) return Allocation
   is
   begin
      return Find_Nucleolus
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         Grid_Step,
         Tol);
   end Find_Nucleolus;

end Nucleolus;
