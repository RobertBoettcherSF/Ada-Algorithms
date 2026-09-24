package Slot_Machine
  with Preelaborate
is
   -- Symbols commonly found on classic and video slot machines.
   -- Blank represents the space between symbols on mechanical reels.
   type Symbol_ID is (Blank, Cherry, Lemon, Orange, Plum, Bell, Bar, Seven, Wild, Scatter);

   -- Strong typing for domain concepts
   type Payout_Amount is new Natural;

   type Reel_Stop_Index is range 1 .. 256;
   type RNG_Value is range 1 .. 65_536;
   type Reel_Count is range 1 .. 5;
   type Row_Count is range 1 .. 5;

   -- A single reel's physical strip of symbols
   type Reel_Strip_Array is array (Reel_Stop_Index) of Symbol_ID;

   -- Definition of a reel including its actual length up to the maximum stops
   type Reel_Def is record
      Symbols : Reel_Strip_Array := [others => Blank];
      Length  : Reel_Stop_Index := 1;
   end record;

   type Reel_Def_Array is array (Reel_Count range <>) of Reel_Def;
   type Stop_Array is array (Reel_Count range <>) of Reel_Stop_Index;

   -- Virtual reel mapping: maps a larger RNG range to a smaller set of physical stops,
   -- allowing for non-uniform probabilities (e.g. creating "near misses").
   type Virtual_Mapping is array (RNG_Value range <>) of Reel_Stop_Index;

   type Symbol_Array is array (Positive range <>) of Symbol_ID;
   
   -- Grid for video slots (columns are reels, rows are visible symbols)
   type Reel_Grid is array (Reel_Count range <>, Row_Count range <>) of Symbol_ID;
   
   -- Paylines defined as a 2D array of (Payline_Index, Reel_Column) yielding the Row_Count
   type Payline_Array is array (Positive range <>, Reel_Count range <>) of Row_Count;

   -- Arrays for probability calculations
   type Length_Array is array (Positive range <>) of Positive;
   type Count_Array is array (Positive range <>) of Natural;

   -----------------------------------------------------------------------------
   -- Algorithm Variants and Evaluators
   -----------------------------------------------------------------------------

   -- Validates that a virtual mapping does not point to a stop beyond the physical reel limit.
   function Is_Valid_Mapping
     (Mapping  : Virtual_Mapping;
      Max_Stop : Reel_Stop_Index) return Boolean
     with Global => null;

   -- Translates an RNG output into a physical reel stop using a virtual mapping.
   function Get_Stop_Index
     (Mapping : Virtual_Mapping;
      RNG     : RNG_Value) return Reel_Stop_Index
     with Global => null,
          Pre => Mapping'First <= RNG and then Mapping'Last >= RNG;

   -- Extracts the visible symbols from a reel starting at a specific stop, 
   -- correctly wrapping around to the beginning if the window exceeds reel length.
   function Get_Visible_Window
     (Reel     : Reel_Def;
      Top_Stop : Reel_Stop_Index;
      Rows     : Positive) return Symbol_Array
     with Global => null,
          Pre => Top_Stop <= Reel.Length,
          Post => Get_Visible_Window'Result'Length = Rows;

   -- Evaluates the spin over multiple reels to construct the complete video slot grid.
   function Generate_Grid
     (Reels : Reel_Def_Array;
      Stops : Stop_Array;
      Rows  : Row_Count) return Reel_Grid
     with Global => null,
          Pre => Reels'Length = Stops'Length and then Reels'Length > 0;

   -- Classic multi-symbol evaluator: requires an exact match of all symbols (no wilds).
   function Evaluate_Line_Classic
     (Line : Symbol_Array;
      Bet  : Payout_Amount) return Payout_Amount
     with Global => null;

   -- Advanced multi-symbol evaluator: incorporates Wilds that substitute for any standard symbol.
   function Evaluate_Line_Wild
     (Line : Symbol_Array;
      Bet  : Payout_Amount) return Payout_Amount
     with Global => null;

   -- Scatter symbol evaluator: calculates payouts based on occurrence count regardless of paylines.
   function Evaluate_Scatter
     (Grid : Reel_Grid;
      Bet  : Payout_Amount) return Payout_Amount
     with Global => null;

   -- Evaluates a full multi-line video slot grid across multiple defined payline paths.
   function Evaluate_Multi_Line
     (Grid  : Reel_Grid;
      Lines : Payline_Array;
      Bet   : Payout_Amount) return Payout_Amount
     with Global => null;

   -- Calculates the theoretical hit probability for a specific combination on a payline.
   function Calculate_Line_Hit_Odds
     (Reel_Lengths  : Length_Array;
      Symbol_Counts : Count_Array) return Float
     with Global => null,
          Pre => Reel_Lengths'Length = Symbol_Counts'Length;

   -- Calculates the Expected Value for a single winning combination.
   function Calculate_Expected_Value
     (Odds   : Float;
      Payout : Payout_Amount) return Float
     with Global => null,
          Pre => Odds >= 0.0;

end Slot_Machine;
