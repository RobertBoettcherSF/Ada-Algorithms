package body Slot_Machine is

   function Is_Valid_Mapping
     (Mapping  : Virtual_Mapping;
      Max_Stop : Reel_Stop_Index) return Boolean
   is
   begin
      for I in Mapping'Range loop
         if Mapping (I) > Max_Stop then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Mapping;

   function Get_Stop_Index
     (Mapping : Virtual_Mapping;
      RNG     : RNG_Value) return Reel_Stop_Index
   is
   begin
      -- Directly map the RNG value to a stop index
      return Mapping (RNG);
   end Get_Stop_Index;

   function Get_Visible_Window
     (Reel     : Reel_Def;
      Top_Stop : Reel_Stop_Index;
      Rows     : Positive) return Symbol_Array
   is
      Result  : Symbol_Array (1 .. Rows);
      Current : Reel_Stop_Index := Top_Stop;
   begin
      for I in 1 .. Rows loop
         Result (I) := Reel.Symbols (Current);
         -- Wrap around to the start of the reel if we hit the actual length
         if Current = Reel.Length then
            Current := 1;
         else
            Current := Current + 1;
         end if;
      end loop;
      return Result;
   end Get_Visible_Window;

   function Generate_Grid
     (Reels : Reel_Def_Array;
      Stops : Stop_Array;
      Rows  : Row_Count) return Reel_Grid
   is
      Result : Reel_Grid (Reels'Range, 1 .. Rows);
   begin
      -- For each reel, fetch its visible window and populate the column
      for C in Reels'Range loop
         declare
            Window : constant Symbol_Array :=
              Get_Visible_Window (Reels (C), Stops (C), Positive (Rows));
         begin
            for R in 1 .. Rows loop
               Result (C, R) := Window (Positive (R));
            end loop;
         end;
      end loop;
      return Result;
   end Generate_Grid;

   function Evaluate_Line_Classic
     (Line : Symbol_Array;
      Bet  : Payout_Amount) return Payout_Amount
   is
      First_Symbol : constant Symbol_ID := Line (Line'First);
      Match        : Boolean := True;
   begin
      -- Must be exactly homogeneous.
      for I in Line'Range loop
         if Line (I) /= First_Symbol then
            Match := False;
            exit;
         end if;
      end loop;

      if Match then
         case First_Symbol is
            when Cherry => return Bet * 10;
            when Lemon | Orange | Plum => return Bet * 20;
            when Bell => return Bet * 30;
            when Bar => return Bet * 50;
            when Seven => return Bet * 100;
            when others => return 0; -- Blanks, wilds, scatters unhandled here
         end case;
      end if;
      return 0;
   end Evaluate_Line_Classic;

   function Evaluate_Line_Wild
     (Line : Symbol_Array;
      Bet  : Payout_Amount) return Payout_Amount
   is
      Target : Symbol_ID := Wild;
      Match  : Boolean := True;
   begin
      -- Step 1: Discover the underlying target symbol being matched
      for I in Line'Range loop
         if Line (I) /= Wild and then Line (I) /= Scatter and then Line (I) /= Blank then
            Target := Line (I);
            exit;
         end if;
      end loop;

      -- Step 2: Verify all symbols match the target or are substituting wilds
      for I in Line'Range loop
         if Line (I) = Scatter or else Line (I) = Blank then
            Match := False;
            exit;
         end if;
         if Line (I) /= Wild and then Line (I) /= Target then
            Match := False;
            exit;
         end if;
      end loop;

      if Match then
         case Target is
            when Cherry => return Bet * 10;
            when Lemon | Orange | Plum => return Bet * 20;
            when Bell => return Bet * 30;
            when Bar => return Bet * 50;
            when Seven => return Bet * 100;
            when Wild => return Bet * 500; -- Jackpot for all wilds
            when others => return 0;
         end case;
      end if;
      return 0;
   end Evaluate_Line_Wild;

   function Evaluate_Scatter
     (Grid : Reel_Grid;
      Bet  : Payout_Amount) return Payout_Amount
   is
      Count : Natural := 0;
   begin
      -- Scatter symbols count regardless of payline positioning
      for C in Grid'Range (1) loop
         for R in Grid'Range (2) loop
            if Grid (C, R) = Scatter then
               Count := Count + 1;
            end if;
         end loop;
      end loop;

      case Count is
         when 0 .. 2 => return 0;
         when 3 => return Bet * 5;
         when 4 => return Bet * 20;
         when others => return Bet * 100; -- 5 or more
      end case;
   end Evaluate_Scatter;

   function Evaluate_Multi_Line
     (Grid  : Reel_Grid;
      Lines : Payline_Array;
      Bet   : Payout_Amount) return Payout_Amount
   is
      Total_Win : Payout_Amount := 0;
   begin
      -- Evaluate each defined payline independently and sum the payouts
      for I in Lines'Range (1) loop
         declare
            Line : Symbol_Array (1 .. Lines'Length (2));
            Idx  : Positive := 1;
         begin
            for C in Lines'Range (2) loop
               Line (Idx) := Grid (C, Lines (I, C));
               Idx := Idx + 1;
            end loop;
            Total_Win := Total_Win + Evaluate_Line_Wild (Line, Bet);
         end;
      end loop;
      return Total_Win;
   end Evaluate_Multi_Line;

   function Calculate_Line_Hit_Odds
     (Reel_Lengths  : Length_Array;
      Symbol_Counts : Count_Array) return Float
   is
      Odds : Float := 1.0;
   begin
      -- Combinatorics: probability is the product of independent probabilities
      for I in Reel_Lengths'Range loop
         Odds := Odds * (Float (Symbol_Counts (I)) / Float (Reel_Lengths (I)));
      end loop;
      return Odds;
   end Calculate_Line_Hit_Odds;

   function Calculate_Expected_Value
     (Odds   : Float;
      Payout : Payout_Amount) return Float
   is
   begin
      -- EV = Probability of occurrence * Pay amount
      return Odds * Float (Payout);
   end Calculate_Expected_Value;

end Slot_Machine;
