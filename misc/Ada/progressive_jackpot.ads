package Progressive_Jackpot is
   -- Represents currency values in the system
   type Money is delta 0.01 digits 14;

   -- Represents a percentage rate (0.0 to 1.0)
   type Rate is new Float range 0.0 .. 1.0;

   -- Exceptions for invalid operations and states
   Invalid_Configuration : exception;
   Invalid_Bet           : exception;

   -- ========================================================================
   -- 1. Standalone Progressive Jackpot
   -- A basic progressive jackpot connected to a single slot machine.
   -- ========================================================================
   type Standalone_Jackpot is private;

   procedure Initialize_Standalone
     (Jackpot  : out Standalone_Jackpot;
      Base     : Money;
      Inc_Rate : Rate)
     with Global => null,
          Pre    => Base >= 0.0,
          Post   => Current_Value (Jackpot) = Base;

   procedure Play_Standalone
     (Jackpot : in out Standalone_Jackpot;
      Bet     : Money)
     with Global => null,
          Pre    => Bet >= 0.0,
          Post   => Current_Value (Jackpot) >= Current_Value (Jackpot)'Old;

   function Current_Value (Jackpot : Standalone_Jackpot) return Money
     with Global => null;

   function Base_Value (Jackpot : Standalone_Jackpot) return Money
     with Global => null;


   -- ========================================================================
   -- 2. Must-Hit-By (Mystery) Progressive Jackpot
   -- Triggers automatically when the pool reaches a specific threshold.
   -- ========================================================================
   type Mystery_Jackpot is private;

   procedure Initialize_Mystery
     (Jackpot  : out Mystery_Jackpot;
      Base     : Money;
      Must_Hit : Money;
      Inc_Rate : Rate)
     with Global => null,
          Pre    => Base >= 0.0 and Must_Hit > Base,
          Post   => Current_Value (Jackpot) = Base;

   procedure Play_Mystery
     (Jackpot : in out Mystery_Jackpot;
      Bet     : Money;
      Is_Hit  : out Boolean)
     with Global => null,
          Pre    => Bet >= 0.0;

   function Current_Value (Jackpot : Mystery_Jackpot) return Money
     with Global => null;

   function Base_Value (Jackpot : Mystery_Jackpot) return Money
     with Global => null;

   function Must_Hit_Threshold (Jackpot : Mystery_Jackpot) return Money
     with Global => null;


   -- ========================================================================
   -- 3. Network Progressive (Local & Wide Area)
   -- Connects multiple machines. Wide Area Networks (WANs) typically have 
   -- administrative fees deducted from the increment rate.
   -- ========================================================================
   type Network_Class is (Local_Area, Wide_Area);
   type Network_Jackpot is private;
   type Bet_Array is array (Positive range <>) of Money;

   procedure Initialize_Network
     (Jackpot   : out Network_Jackpot;
      Class     : Network_Class;
      Base      : Money;
      Inc_Rate  : Rate;
      Admin_Fee : Rate := 0.0)
     with Global => null,
          Pre    => Base >= 0.0;

   procedure Play_Network
     (Jackpot : in out Network_Jackpot;
      Bets    : Bet_Array)
     with Global => null;

   function Current_Value (Jackpot : Network_Jackpot) return Money
     with Global => null;

   function Base_Value (Jackpot : Network_Jackpot) return Money
     with Global => null;


   -- ========================================================================
   -- 4. Qualifying Bet (Max Bet Constraint)
   -- A win is only possible if the player's bet meets or exceeds a threshold.
   -- However, all bets (even non-qualifying ones) contribute to the pool.
   -- ========================================================================
   procedure Play_With_Qualification
     (Jackpot   : in out Standalone_Jackpot;
      Bet       : Money;
      Threshold : Money;
      Qualifies : out Boolean)
     with Global => null,
          Pre    => Bet >= 0.0 and Threshold >= 0.0;


   -- ========================================================================
   -- Helper Functions
   -- ========================================================================
   function Calculate_Contribution (Bet : Money; Contribution_Rate : Rate) return Money
     with Global => null,
          Pre    => Bet >= 0.0;

private
   type Standalone_Jackpot is record
      Base_Val     : Money := 0.0;
      Current_Val  : Money := 0.0;
      Inc_Rate     : Rate := 0.0;
   end record;

   type Mystery_Jackpot is record
      Base_Val     : Money := 0.0;
      Current_Val  : Money := 0.0;
      Inc_Rate     : Rate := 0.0;
      Must_Hit_Val : Money := 1.0;
   end record;

   type Network_Jackpot is record
      Class          : Network_Class := Local_Area;
      Base_Val       : Money := 0.0;
      Current_Val    : Money := 0.0;
      Inc_Rate       : Rate := 0.0;
      Admin_Fee_Rate : Rate := 0.0;
   end record;
end Progressive_Jackpot;
