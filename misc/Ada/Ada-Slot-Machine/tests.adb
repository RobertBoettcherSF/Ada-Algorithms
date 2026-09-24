with Ada.Text_IO; use Ada.Text_IO;
with Slot_Machine; use Slot_Machine;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("--- Slot Machine Test Suite ---");

   -- TEST 1 — Is_Valid_Mapping
   Put_Line ("TEST 1 — Is_Valid_Mapping");
   declare
      Map_Ok  : Virtual_Mapping (1 .. 5) := [1, 2, 3, 2, 1];
      Map_Bad : Virtual_Mapping (1 .. 5) := [1, 2, 99, 2, 1];
   begin
      Check ("1.1 Valid mapping within limits", Is_Valid_Mapping (Map_Ok, 10));
      Check ("1.2 Invalid mapping detected correctly", not Is_Valid_Mapping (Map_Bad, 10));
      Check ("1.3 Edge case exactly at boundary", Is_Valid_Mapping (Map_Ok, 3));
   end;

   -- TEST 2 — Get_Stop_Index
   Put_Line ("TEST 2 — Get_Stop_Index");
   declare
      Map : Virtual_Mapping (1 .. 3) := [10, 20, 30];
   begin
      Check ("2.1 Lower bound RNG mapping", Get_Stop_Index (Map, 1) = 10);
      Check ("2.2 Middle RNG mapping", Get_Stop_Index (Map, 2) = 20);
      Check ("2.3 Upper bound RNG mapping", Get_Stop_Index (Map, 3) = 30);
   end;

   -- TEST 3 — Get_Visible_Window (No wrap-around)
   Put_Line ("TEST 3 — Get_Visible_Window (No Wrap)");
   declare
      R   : Reel_Def;
      Win : Symbol_Array (1 .. 3);
   begin
      R.Length := 5;
      R.Symbols (1 .. 5) := [Cherry, Lemon, Orange, Plum, Bell];
      Win := Get_Visible_Window (R, 2, 3);
      Check ("3.1 First visible symbol", Win (1) = Lemon);
      Check ("3.2 Second visible symbol", Win (2) = Orange);
      Check ("3.3 Third visible symbol", Win (3) = Plum);
   end;

   -- TEST 4 — Get_Visible_Window (Wrap-around at reel end)
   Put_Line ("TEST 4 — Get_Visible_Window (Wrap)");
   declare
      R   : Reel_Def;
      Win : Symbol_Array (1 .. 3);
   begin
      R.Length := 4;
      R.Symbols (1 .. 4) := [Cherry, Lemon, Orange, Plum];
      Win := Get_Visible_Window (R, 3, 3);
      Check ("4.1 Pre-wrap symbol", Win (1) = Orange);
      Check ("4.2 Wrap point symbol", Win (2) = Plum);
      Check ("4.3 Post-wrap symbol", Win (3) = Cherry);
   end;

   -- TEST 5 — Generate_Grid (Multiple Reels)
   Put_Line ("TEST 5 — Generate_Grid");
   declare
      R_Arr : Reel_Def_Array (1 .. 2);
      Stops : Stop_Array (1 .. 2) := [1, 2];
      Grid  : Reel_Grid (1 .. 2, 1 .. 2);
   begin
      R_Arr (1).Length := 3;
      R_Arr (1).Symbols (1 .. 3) := [Cherry, Cherry, Cherry];
      R_Arr (2).Length := 3;
      R_Arr (2).Symbols (1 .. 3) := [Lemon, Lemon, Lemon];
      Grid := Generate_Grid (R_Arr, Stops, 2);
      Check ("5.1 Grid top-left matches reel 1", Grid (1, 1) = Cherry);
      Check ("5.2 Grid top-right matches reel 2", Grid (2, 1) = Lemon);
      Check ("5.3 Grid layout matrix dimension check", Grid'Length (1) = 2 and then Grid'Length (2) = 2);
   end;

   -- TEST 6 — Evaluate_Line_Classic (Wins)
   Put_Line ("TEST 6 — Evaluate_Line_Classic (Wins)");
   begin
      Check ("6.1 Cherry win calculation", Evaluate_Line_Classic ([Cherry, Cherry, Cherry], 10) = 100);
      Check ("6.2 Seven jackpot calculation", Evaluate_Line_Classic ([Seven, Seven, Seven], 5) = 500);
      Check ("6.3 Bar win calculation", Evaluate_Line_Classic ([Bar, Bar, Bar], 2) = 100);
   end;

   -- TEST 7 — Evaluate_Line_Classic (Losses & Non-matches)
   Put_Line ("TEST 7 — Evaluate_Line_Classic (Losses)");
   begin
      Check ("7.1 Mixed symbols returns 0", Evaluate_Line_Classic ([Cherry, Lemon, Cherry], 10) = 0);
      Check ("7.2 Single differing symbol returns 0", Evaluate_Line_Classic ([Seven, Seven, Bar], 10) = 0);
      Check ("7.3 Blank spaces return 0", Evaluate_Line_Classic ([Blank, Blank, Blank], 10) = 0);
   end;

   -- TEST 8 — Evaluate_Line_Wild (Substitutions)
   Put_Line ("TEST 8 — Evaluate_Line_Wild");
   begin
      Check ("8.1 Wild substitutes correctly for Cherry", Evaluate_Line_Wild ([Wild, Cherry, Cherry], 10) = 100);
      Check ("8.2 Line of all Wilds pays special jackpot", Evaluate_Line_Wild ([Wild, Wild, Wild], 10) = 5000);
      Check ("8.3 Wild fails to substitute for mixed symbols", Evaluate_Line_Wild ([Wild, Cherry, Lemon], 10) = 0);
   end;

   -- TEST 9 — Evaluate_Scatter (Global appearance)
   Put_Line ("TEST 9 — Evaluate_Scatter");
   declare
      Grid_None  : Reel_Grid (1 .. 3, 1 .. 3) := [others => [others => Blank]];
      Grid_Three : Reel_Grid (1 .. 3, 1 .. 3) := [others => [others => Blank]];
      Grid_Five  : Reel_Grid (1 .. 3, 1 .. 3) := [others => [others => Scatter]];
   begin
      Grid_Three (1, 1) := Scatter; 
      Grid_Three (2, 2) := Scatter; 
      Grid_Three (3, 3) := Scatter;
      
      Check ("9.1 No scatters yields no payout", Evaluate_Scatter (Grid_None, 10) = 0);
      Check ("9.2 Three scatters triggers standard payout", Evaluate_Scatter (Grid_Three, 10) = 50);
      Check ("9.3 Five scatters triggers maximum payout", Evaluate_Scatter (Grid_Five, 10) = 1000);
   end;

   -- TEST 10 — Calculate_Line_Hit_Odds
   Put_Line ("TEST 10 — Calculate_Line_Hit_Odds");
   declare
      Lens   : constant Length_Array (1 .. 3) := [10, 10, 10];
      Counts : constant Count_Array (1 .. 3) := [1, 1, 1];
      Zero_C : constant Count_Array (1 .. 3) := [1, 0, 1];
   begin
      Check ("10.1 Typical 1 in 1000 probability", abs (Calculate_Line_Hit_Odds (Lens, Counts) - 0.001) < 0.0001);
      Check ("10.2 Zero chance when a symbol is missing", Calculate_Line_Hit_Odds (Lens, Zero_C) = 0.0);
      Check ("10.3 Guaranteed chance when all stops match", Calculate_Line_Hit_Odds (Lens, [10, 10, 10]) = 1.0);
   end;

   -- TEST 11 — Calculate_Expected_Value
   Put_Line ("TEST 11 — Calculate_Expected_Value");
   begin
      Check ("11.1 Normal Expected Value", abs (Calculate_Expected_Value (0.1, 100) - 10.0) < 0.001);
      Check ("11.2 Zero EV on 0.0 probability", Calculate_Expected_Value (0.0, 100) = 0.0);
      Check ("11.3 High EV on frequent jackpot", abs (Calculate_Expected_Value (0.5, 1000) - 500.0) < 0.001);
   end;

   -- TEST 12 — Evaluate_Multi_Line (Video Slots)
   Put_Line ("TEST 12 — Evaluate_Multi_Line");
   declare
      Grid  : Reel_Grid (1 .. 3, 1 .. 3);
      Lines : Payline_Array (1 .. 3, 1 .. 3);
   begin
      -- Setup Video Slot Grid Layout
      Grid (1, 1) := Cherry; Grid (1, 2) := Cherry; Grid (1, 3) := Cherry;
      Grid (2, 1) := Lemon;  Grid (2, 2) := Bar;    Grid (2, 3) := Seven;
      Grid (3, 1) := Orange; Grid (3, 2) := Plum;   Grid (3, 3) := Blank;

      -- Horizontal Paylines
      Lines := [[1, 1, 1],
                [2, 2, 2],
                [3, 3, 3]];

      Check ("12.1 Mixed lines yield 0", Evaluate_Multi_Line (Grid, Lines, 10) = 0);

      -- Modify grid to create wins
      Grid (2, 1) := Cherry; 
      Grid (3, 1) := Cherry;
      -- Line 1 is now (Cherry, Cherry, Cherry) -> 100
      
      Check ("12.2 Single line win on line 1", Evaluate_Multi_Line (Grid, Lines, 10) = 100);
      
      Grid (2, 2) := Cherry;
      Grid (3, 2) := Cherry;
      -- Line 2 is now (Cherry, Cherry, Cherry) -> 100 + 100 = 200 total
      
      Check ("12.3 Multiple active lines compound win amounts", Evaluate_Multi_Line (Grid, Lines, 10) = 200);
   end;

   -- TEST 13 — Exception and Precondition Constraints
   Put_Line ("TEST 13 — Constraints and Error Handling");
   declare
      Map : constant Virtual_Mapping (1 .. 5) := [1, 2, 3, 4, 5];
      Got_Error_1 : Boolean := False;
      Got_Error_2 : Boolean := False;
      Got_Error_3 : Boolean := False;
   begin
      begin
         if Get_Stop_Index (Map, 6) = 1 then -- out of bounds RNG
            Got_Error_1 := False;
         end if;
      exception
         when others => Got_Error_1 := True;
      end;
      Check ("13.1 Invalid RNG mapping lookup triggers exception", Got_Error_1);

      begin
         declare
            Lens   : constant Length_Array (1 .. 3) := [10, 10, 10];
            Counts : constant Count_Array (1 .. 2) := [1, 1];
         begin
            if Calculate_Line_Hit_Odds (Lens, Counts) = 0.0 then -- precondition failure
               Got_Error_2 := False;
            end if;
         end;
      exception
         when others => Got_Error_2 := True;
      end;
      Check ("13.2 Mismatched lengths for RTP triggers exception", Got_Error_2);

      begin
         declare
            R : Reel_Def;
            Bad_Top : constant Reel_Stop_Index := 10; -- Max is default 1
         begin
            if Get_Visible_Window (R, Bad_Top, 1)(1) = Blank then -- precondition failure
               Got_Error_3 := False;
            end if;
         end;
      exception
         when others => Got_Error_3 := True;
      end;
      Check ("13.3 Top Stop beyond reel length triggers exception", Got_Error_3);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");

end Tests;
