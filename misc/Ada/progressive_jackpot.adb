package body Progressive_Jackpot is

   ---------------------------------------------------------------------------
   -- Helper Functions
   ---------------------------------------------------------------------------
   function Calculate_Contribution (Bet : Money; Contribution_Rate : Rate) return Money is
      Val : Float;
   begin
      if Bet < 0.0 then
         raise Invalid_Bet;
      end if;
      
      -- Convert to Float to calculate the fraction, then safely cast back to fixed point Money
      Val := Float (Bet) * Float (Contribution_Rate);
      return Money (Val);
   end Calculate_Contribution;


   ---------------------------------------------------------------------------
   -- 1. Standalone Progressive Jackpot
   ---------------------------------------------------------------------------
   procedure Initialize_Standalone
     (Jackpot  : out Standalone_Jackpot;
      Base     : Money;
      Inc_Rate : Rate)
   is
   begin
      if Base < 0.0 then
         raise Invalid_Configuration;
      end if;
      
      Jackpot.Base_Val    := Base;
      Jackpot.Current_Val := Base;
      Jackpot.Inc_Rate    := Inc_Rate;
   end Initialize_Standalone;

   procedure Play_Standalone
     (Jackpot : in out Standalone_Jackpot;
      Bet     : Money)
   is
   begin
      if Bet < 0.0 then
         raise Invalid_Bet;
      end if;
      
      -- Ada 2022: The target name symbol '@' prevents repetition of the LHS
      Jackpot.Current_Val := @ + Calculate_Contribution (Bet, Jackpot.Inc_Rate);
   end Play_Standalone;

   function Current_Value (Jackpot : Standalone_Jackpot) return Money is (Jackpot.Current_Val);
   function Base_Value (Jackpot : Standalone_Jackpot) return Money is (Jackpot.Base_Val);


   ---------------------------------------------------------------------------
   -- 2. Must-Hit-By (Mystery) Progressive Jackpot
   ---------------------------------------------------------------------------
   procedure Initialize_Mystery
     (Jackpot  : out Mystery_Jackpot;
      Base     : Money;
      Must_Hit : Money;
      Inc_Rate : Rate)
   is
   begin
      if Base < 0.0 or else Must_Hit <= Base then
         raise Invalid_Configuration;
      end if;
      
      Jackpot.Base_Val     := Base;
      Jackpot.Current_Val  := Base;
      Jackpot.Must_Hit_Val := Must_Hit;
      Jackpot.Inc_Rate     := Inc_Rate;
   end Initialize_Mystery;

   procedure Play_Mystery
     (Jackpot : in out Mystery_Jackpot;
      Bet     : Money;
      Is_Hit  : out Boolean)
   is
   begin
      if Bet < 0.0 then
         raise Invalid_Bet;
      end if;

      Jackpot.Current_Val := @ + Calculate_Contribution (Bet, Jackpot.Inc_Rate);

      -- Check if the threshold is reached or exceeded
      if Jackpot.Current_Val >= Jackpot.Must_Hit_Val then
         Is_Hit := True;
         -- Immediately reset back to the base value as payout is handled externally
         Jackpot.Current_Val := Jackpot.Base_Val; 
      else
         Is_Hit := False;
      end if;
   end Play_Mystery;

   function Current_Value (Jackpot : Mystery_Jackpot) return Money is (Jackpot.Current_Val);
   function Base_Value (Jackpot : Mystery_Jackpot) return Money is (Jackpot.Base_Val);
   function Must_Hit_Threshold (Jackpot : Mystery_Jackpot) return Money is (Jackpot.Must_Hit_Val);


   ---------------------------------------------------------------------------
   -- 3. Network Progressive (Local & Wide Area)
   ---------------------------------------------------------------------------
   procedure Initialize_Network
     (Jackpot   : out Network_Jackpot;
      Class     : Network_Class;
      Base      : Money;
      Inc_Rate  : Rate;
      Admin_Fee : Rate := 0.0)
   is
   begin
      if Base < 0.0 then
         raise Invalid_Configuration;
      end if;
      
      if Class = Wide_Area and then Admin_Fee >= Inc_Rate then
         -- A WAN shouldn't deduct more in fees than the contribution rate itself
         raise Invalid_Configuration;
      end if;

      Jackpot.Class          := Class;
      Jackpot.Base_Val       := Base;
      Jackpot.Current_Val    := Base;
      Jackpot.Inc_Rate       := Inc_Rate;
      Jackpot.Admin_Fee_Rate := Admin_Fee;
   end Initialize_Network;

   procedure Play_Network
     (Jackpot : in out Network_Jackpot;
      Bets    : Bet_Array)
   is
      Total_Addition : Money := 0.0;
      Effective_Rate : Rate;
   begin
      -- Wide Area Networks apply an administrative fee overhead that reduces 
      -- the net increment rate directed to the pool.
      if Jackpot.Class = Wide_Area then
         Effective_Rate := Jackpot.Inc_Rate - Jackpot.Admin_Fee_Rate;
      else
         Effective_Rate := Jackpot.Inc_Rate;
      end if;

      for B of Bets loop
         if B < 0.0 then
            raise Invalid_Bet;
         end if;
         Total_Addition := @ + Calculate_Contribution (B, Effective_Rate);
      end loop;

      Jackpot.Current_Val := @ + Total_Addition;
   end Play_Network;

   function Current_Value (Jackpot : Network_Jackpot) return Money is (Jackpot.Current_Val);
   function Base_Value (Jackpot : Network_Jackpot) return Money is (Jackpot.Base_Val);


   ---------------------------------------------------------------------------
   -- 4. Qualifying Bet (Max Bet Constraint)
   ---------------------------------------------------------------------------
   procedure Play_With_Qualification
     (Jackpot   : in out Standalone_Jackpot;
      Bet       : Money;
      Threshold : Money;
      Qualifies : out Boolean)
   is
   begin
      if Bet < 0.0 or else Threshold < 0.0 then
         raise Invalid_Bet;
      end if;

      -- Every single bet contributes to the pot size ...
      Play_Standalone (Jackpot, Bet);

      -- ... but only maximum (qualifying) bets enable the jackpot payout logic.
      Qualifies := (Bet >= Threshold);
   end Play_With_Qualification;

end Progressive_Jackpot;
