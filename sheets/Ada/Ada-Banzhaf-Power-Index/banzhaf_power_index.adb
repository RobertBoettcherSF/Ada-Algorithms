--  Banzhaf_Power_Index body — swing enumeration for weighted and simple
--  games, absolute (Penrose–Banzhaf) and normalized indices, Coleman
--  prevent / initiate, and dummy / dictator / veto / symmetry helpers.

pragma Ada_2022;

package body Banzhaf_Power_Index
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
   -- Bitmask / combinatorial helpers
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

   function Factorial (K : Natural) return Worth is
      R : Worth := 1.0;
   begin
      if K > 20 then
         raise Invalid_Argument;
      end if;
      for I in 2 .. K loop
         R := R * Worth (I);
      end loop;
      return R;
   end Factorial;

   function Binomial (N, K : Natural) return Natural is
      KK : Natural;
      R  : Long_Long_Integer := 1;
   begin
      if N > 20 then
         raise Invalid_Argument;
      end if;
      if K > N then
         return 0;
      end if;
      KK := K;
      if KK > N - KK then
         KK := N - KK;
      end if;
      for I in 1 .. KK loop
         R := R * Long_Long_Integer (N - KK + I) / Long_Long_Integer (I);
      end loop;
      return Natural (R);
   end Binomial;

   function Coalition_Weight
     (Weights : Weight_Vector; Mask : Natural) return Long_Long_Integer
   is
      S : Long_Long_Integer := 0;
   begin
      if Weights'First /= 1 then
         raise Invalid_Argument;
      end if;
      if Weights'Length = 0 or else Weights'Length > Max_N then
         raise Invalid_Argument;
      end if;
      for I in Weights'Range loop
         if Has_Player (Mask, I) then
            S := S + Long_Long_Integer (Weights (I));
         end if;
      end loop;
      return S;
   end Coalition_Weight;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_N (N : Natural) is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
   end Require_N;

   procedure Require_Player (N : Natural; I : Player_Id) is
   begin
      if N = 0 or else Natural (I) > N then
         raise Invalid_Argument;
      end if;
   end Require_Player;

   procedure Require_Mask (N : Natural; Mask : Natural) is
   begin
      Require_N (N);
      if Mask >= Power2 (N) then
         raise Invalid_Argument;
      end if;
   end Require_Mask;

   procedure Require_Weights (Quota : Natural; Weights : Weight_Vector) is
   begin
      if Quota = 0 then
         raise Invalid_Argument;
      end if;
      if Weights'First /= 1 then
         raise Invalid_Argument;
      end if;
      if Weights'Length = 0 or else Weights'Length > Max_N then
         raise Invalid_Argument;
      end if;
   end Require_Weights;

   procedure Require_Table (N : Natural; Winning : Characteristic) is
      All_M : Natural;
      Bit   : Natural;
      S     : Natural;
   begin
      Require_N (N);
      if Winning'First /= 0 or else Winning'Length /= Power2 (N) then
         raise Invalid_Argument;
      end if;
      for M in Winning'Range loop
         if Winning (M) > 1 then
            raise Invalid_Argument;
         end if;
      end loop;
      if Winning (0) /= 0 then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      for Raw in 0 .. All_M loop
         if Winning (Raw) = 1 then
            for I in 1 .. Player_Id (N) loop
               Bit := Player_Bit (I);
               if (Raw / Bit) mod 2 = 0 then
                  S := Raw + Bit;
                  if Winning (S) /= 1 then
                     raise Invalid_Argument;
                  end if;
               end if;
            end loop;
         end if;
      end loop;
   end Require_Table;

   ---------------------------------------------------------------------------
   -- Internal winning test (Mask already range-checked)
   ---------------------------------------------------------------------------

   function Wins_Unchecked
     (G : Instance; Mask : Natural) return Boolean
   is
      S : Long_Long_Integer := 0;
   begin
      case G.Form is
         when Weighted_Form =>
            for I in 1 .. Player_Id (G.N) loop
               if Has_Player (Mask, I) then
                  S := S + Long_Long_Integer (G.W (I));
               end if;
            end loop;
            return S >= Long_Long_Integer (G.Quota);
         when Simple_Form =>
            return G.Win (Mask);
      end case;
   end Wins_Unchecked;

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   function Weighted
     (Quota : Natural; Weights : Weight_Vector) return Instance
   is
      G : Instance;
      N : Natural;
   begin
      Require_Weights (Quota, Weights);
      N := Weights'Length;
      G.N     := Player_Count (N);
      G.Form  := Weighted_Form;
      G.Quota := Quota;
      G.W     := [others => 0];
      G.Win   := [others => False];
      for I in Weights'Range loop
         G.W (I) := Weights (I);
      end loop;
      return G;
   end Weighted;

   function From_Characteristic
     (N : Natural; Winning : Characteristic) return Instance
   is
      G     : Instance;
      All_M : Natural;
   begin
      Require_Table (N, Winning);
      All_M := Power2 (N) - 1;
      G.N     := Player_Count (N);
      G.Form  := Simple_Form;
      G.Quota := 0;
      G.W     := [others => 0];
      G.Win   := [others => False];
      for M in 0 .. All_M loop
         G.Win (M) := Winning (M) = 1;
      end loop;
      return G;
   end From_Characteristic;

   function Majority (N : Natural) return Instance is
   begin
      Require_N (N);
      declare
         Weights : constant Weight_Vector (1 .. Player_Id (N)) := [others => 1];
         Q       : constant Natural := N / 2 + 1;
      begin
         return Weighted (Q, Weights);
      end;
   end Majority;

   function Equal_Weights
     (N : Natural; Each : Natural; Quota : Natural) return Instance
   is
   begin
      Require_N (N);
      declare
         Weights : constant Weight_Vector (1 .. Player_Id (N)) := [others => Each];
      begin
         return Weighted (Quota, Weights);
      end;
   end Equal_Weights;

   function UN_Security_Council return Instance is
      W : constant Weight_Vector :=
        [7, 7, 7, 7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
   begin
      return Weighted (39, W);
   end UN_Security_Council;

   function Corporate_Shareholders return Instance is
   begin
      return Weighted (51, [40, 30, 20, 10]);
   end Corporate_Shareholders;

   function Size (G : Instance) return Player_Count is
   begin
      return G.N;
   end Size;

   function Is_Weighted_Game (G : Instance) return Boolean is
   begin
      return G.N > 0 and then G.Form = Weighted_Form;
   end Is_Weighted_Game;

   function Quota_Of (G : Instance) return Natural is
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      return G.Quota;
   end Quota_Of;

   function Weight_Of (G : Instance; I : Player_Id) return Natural is
   begin
      Require_Player (Natural (G.N), I);
      return G.W (I);
   end Weight_Of;

   function Weights_Of (G : Instance) return Weight_Vector is
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      return Weight_Vector (G.W (1 .. Player_Id (G.N)));
   end Weights_Of;

   function Characteristic_Of (G : Instance) return Characteristic is
      All_M : Natural;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (Natural (G.N)) - 1;
      declare
         V : Characteristic (0 .. All_M) := [others => 0];
      begin
         for M in 0 .. All_M loop
            if Wins_Unchecked (G, M) then
               V (M) := 1;
            end if;
         end loop;
         return V;
      end;
   end Characteristic_Of;

   ---------------------------------------------------------------------------
   -- Is_Winning / Is_Critical
   ---------------------------------------------------------------------------

   function Is_Winning (G : Instance; Mask : Natural) return Boolean is
   begin
      Require_Mask (Natural (G.N), Mask);
      return Wins_Unchecked (G, Mask);
   end Is_Winning;

   function Is_Winning
     (Quota : Natural; Weights : Weight_Vector; Mask : Natural)
      return Boolean
   is
   begin
      Require_Weights (Quota, Weights);
      if Mask >= Power2 (Weights'Length) then
         raise Invalid_Argument;
      end if;
      return Coalition_Weight (Weights, Mask) >= Long_Long_Integer (Quota);
   end Is_Winning;

   function Is_Winning
     (N : Natural; Winning : Characteristic; Mask : Natural)
      return Boolean
   is
   begin
      Require_Table (N, Winning);
      if Mask >= Power2 (N) then
         raise Invalid_Argument;
      end if;
      return Winning (Mask) = 1;
   end Is_Winning;

   function Is_Critical
     (G : Instance; Mask : Natural; I : Player_Id) return Boolean
   is
      Bit : Natural;
   begin
      Require_Mask (Natural (G.N), Mask);
      Require_Player (Natural (G.N), I);
      Bit := Player_Bit (I);
      if (Mask / Bit) mod 2 = 0 then
         return False;
      end if;
      return Wins_Unchecked (G, Mask)
        and then not Wins_Unchecked (G, Mask - Bit);
   end Is_Critical;

   function Is_Critical
     (Quota : Natural; Weights : Weight_Vector;
      Mask  : Natural; I : Player_Id) return Boolean
   is
      Bit : Natural;
   begin
      Require_Weights (Quota, Weights);
      Require_Player (Weights'Length, I);
      if Mask >= Power2 (Weights'Length) then
         raise Invalid_Argument;
      end if;
      Bit := Player_Bit (I);
      if (Mask / Bit) mod 2 = 0 then
         return False;
      end if;
      return Is_Winning (Quota, Weights, Mask)
        and then not Is_Winning (Quota, Weights, Mask - Bit);
   end Is_Critical;

   function Is_Critical
     (N       : Natural;
      Winning : Characteristic;
      Mask    : Natural;
      I       : Player_Id) return Boolean
   is
      Bit : Natural;
   begin
      Require_Table (N, Winning);
      Require_Player (N, I);
      if Mask >= Power2 (N) then
         raise Invalid_Argument;
      end if;
      Bit := Player_Bit (I);
      if (Mask / Bit) mod 2 = 0 then
         return False;
      end if;
      return Winning (Mask) = 1 and then Winning (Mask - Bit) = 0;
   end Is_Critical;

   ---------------------------------------------------------------------------
   -- Swing enumeration
   ---------------------------------------------------------------------------

   function Count_Swings
     (N    : Natural;
      Wins : access function (Mask : Natural) return Boolean)
      return Count_Vector
   is
      Eta   : Count_Vector (1 .. Player_Id (N)) := [others => 0];
      All_M : constant Natural := Power2 (N) - 1;
      Bit   : Natural;
   begin
      for I in 1 .. Player_Id (N) loop
         Bit := Player_Bit (I);
         for Raw in 0 .. All_M loop
            if (Raw / Bit) mod 2 = 0 then
               if (not Wins (Raw)) and then Wins (Raw + Bit) then
                  Eta (I) := Eta (I) + 1;
               end if;
            end if;
         end loop;
      end loop;
      return Eta;
   end Count_Swings;

   function Swing_Counts (G : Instance) return Count_Vector is
      function Wins (Mask : Natural) return Boolean is
      begin
         return Wins_Unchecked (G, Mask);
      end Wins;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      return Count_Swings (Natural (G.N), Wins'Access);
   end Swing_Counts;

   function Swing_Counts
     (Quota : Natural; Weights : Weight_Vector) return Count_Vector
   is
      function Wins (Mask : Natural) return Boolean is
      begin
         return Coalition_Weight (Weights, Mask)
           >= Long_Long_Integer (Quota);
      end Wins;
   begin
      Require_Weights (Quota, Weights);
      return Count_Swings (Weights'Length, Wins'Access);
   end Swing_Counts;

   function Swing_Counts
     (N : Natural; Winning : Characteristic) return Count_Vector
   is
      function Wins (Mask : Natural) return Boolean is
      begin
         return Winning (Mask) = 1;
      end Wins;
   begin
      Require_Table (N, Winning);
      return Count_Swings (N, Wins'Access);
   end Swing_Counts;

   function Swing_Counts
     (N    : Natural;
      Wins : access function (Mask : Natural) return Boolean)
      return Count_Vector
   is
   begin
      Require_N (N);
      if Wins = null then
         raise Invalid_Argument;
      end if;
      return Count_Swings (N, Wins);
   end Swing_Counts;

   function Total_Swings (Eta : Count_Vector) return Natural is
      S : Natural := 0;
   begin
      for I in Eta'Range loop
         S := S + Eta (I);
      end loop;
      return S;
   end Total_Swings;

   function Total_Swings (G : Instance) return Natural is
   begin
      return Total_Swings (Swing_Counts (G));
   end Total_Swings;

   ---------------------------------------------------------------------------
   -- Index vectors
   ---------------------------------------------------------------------------

   function Divide_Counts
     (Eta : Count_Vector; Den : Worth) return Index_Vector
   is
      Beta : Index_Vector (Eta'Range) := [others => 0.0];
   begin
      if Den = 0.0 then
         raise Invalid_Argument;
      end if;
      for I in Eta'Range loop
         Beta (I) := Worth (Eta (I)) / Den;
      end loop;
      return Beta;
   end Divide_Counts;

   function Absolute_Banzhaf (G : Instance) return Index_Vector is
      Eta : constant Count_Vector := Swing_Counts (G);
      Den : constant Worth :=
        Worth (Power2 (Natural (G.N) - 1));
   begin
      return Divide_Counts (Eta, Den);
   end Absolute_Banzhaf;

   function Absolute_Banzhaf
     (Quota : Natural; Weights : Weight_Vector) return Index_Vector
   is
   begin
      return Absolute_Banzhaf (Weighted (Quota, Weights));
   end Absolute_Banzhaf;

   function Absolute_Banzhaf
     (N : Natural; Winning : Characteristic) return Index_Vector
   is
   begin
      return Absolute_Banzhaf (From_Characteristic (N, Winning));
   end Absolute_Banzhaf;

   function Normalized_Banzhaf (G : Instance) return Index_Vector is
      Eta : constant Count_Vector := Swing_Counts (G);
      Den : constant Worth := Worth (Total_Swings (Eta));
   begin
      return Divide_Counts (Eta, Den);
   end Normalized_Banzhaf;

   function Normalized_Banzhaf
     (Quota : Natural; Weights : Weight_Vector) return Index_Vector
   is
   begin
      return Normalized_Banzhaf (Weighted (Quota, Weights));
   end Normalized_Banzhaf;

   function Normalized_Banzhaf
     (N : Natural; Winning : Characteristic) return Index_Vector
   is
   begin
      return Normalized_Banzhaf (From_Characteristic (N, Winning));
   end Normalized_Banzhaf;

   ---------------------------------------------------------------------------
   -- Coleman / roles
   ---------------------------------------------------------------------------

   function Winning_Count (G : Instance) return Natural is
      All_M : Natural;
      C     : Natural := 0;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (Natural (G.N)) - 1;
      for M in 0 .. All_M loop
         if Wins_Unchecked (G, M) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Winning_Count;

   function Losing_Count (G : Instance) return Natural is
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      return Power2 (Natural (G.N)) - Winning_Count (G);
   end Losing_Count;

   function Coleman_Prevent (G : Instance) return Index_Vector is
      Eta : constant Count_Vector := Swing_Counts (G);
      Den : constant Worth := Worth (Winning_Count (G));
   begin
      return Divide_Counts (Eta, Den);
   end Coleman_Prevent;

   function Coleman_Initiate (G : Instance) return Index_Vector is
      Eta : constant Count_Vector := Swing_Counts (G);
      Den : constant Worth := Worth (Losing_Count (G));
   begin
      return Divide_Counts (Eta, Den);
   end Coleman_Initiate;

   function Is_Dummy (G : Instance; I : Player_Id) return Boolean is
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Require_Player (Natural (G.N), I);
      declare
         Eta : constant Count_Vector := Swing_Counts (G);
      begin
         return Eta (I) = 0;
      end;
   end Is_Dummy;

   function Is_Dictator (G : Instance; I : Player_Id) return Boolean is
      Bit : Natural;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Require_Player (Natural (G.N), I);
      Bit := Player_Bit (I);
      return Wins_Unchecked (G, Bit);
   end Is_Dictator;

   function Is_Vetoer (G : Instance; I : Player_Id) return Boolean is
      All_M : Natural;
      Bit   : Natural;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Require_Player (Natural (G.N), I);
      Bit   := Player_Bit (I);
      All_M := Power2 (Natural (G.N)) - 1;
      return not Wins_Unchecked (G, All_M - Bit);
   end Is_Vetoer;

   function Are_Symmetric
     (G : Instance; I, J : Player_Id) return Boolean
   is
      Bi, Bj : Natural;
      All_M  : Natural;
      S      : Natural;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Require_Player (Natural (G.N), I);
      Require_Player (Natural (G.N), J);
      if I = J then
         return True;
      end if;
      Bi    := Player_Bit (I);
      Bj    := Player_Bit (J);
      All_M := Power2 (Natural (G.N)) - 1;
      for Raw in 0 .. All_M loop
         if (Raw / Bi) mod 2 = 0 and then (Raw / Bj) mod 2 = 0 then
            S := Raw;
            if Wins_Unchecked (G, S + Bi) /=
              Wins_Unchecked (G, S + Bj)
            then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Are_Symmetric;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Sum_Indices (Beta : Index_Vector) return Worth is
      S : Worth := 0.0;
   begin
      for I in Beta'Range loop
         S := S + Beta (I);
      end loop;
      return S;
   end Sum_Indices;

   function Is_Normalized
     (Beta : Index_Vector; Tol : Worth := Default_Tol) return Boolean
   is
   begin
      return Near (Sum_Indices (Beta), 1.0, Tol);
   end Is_Normalized;

end Banzhaf_Power_Index;
