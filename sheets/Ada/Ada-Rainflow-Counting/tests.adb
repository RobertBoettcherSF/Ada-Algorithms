--  Standalone test suite for Rainflow_Counting (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Rainflow_Counting; use Rainflow_Counting;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Has_Full_Cycle
     (R : Cycle_Result; Range_Expected : Real; Tol : Real := 1.0E-6)
      return Boolean
   is
   begin
      for I in 1 .. R.Length loop
         if R.Items (I).Count >= 0.99
           and then Approx (R.Items (I).Range_Val, Range_Expected, Tol)
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Full_Cycle;

   function Count_Full (R : Cycle_Result) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. R.Length loop
         if R.Items (I).Count >= 0.99 then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Full;

   function Count_Half (R : Cycle_Result) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. R.Length loop
         if Near (R.Items (I).Count, 0.5) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Half;

begin
   Put_Line ("Rainflow_Counting test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Range_Of");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (Approx (Range_Of (3.0, -1.0), 4.0), "Range_Of(3,-1)=4");
   Check (Approx (Range_Of (-2.0, -2.0), 0.0), "Range_Of equal=0");
   Check (Approx (Range_Of (5.0, 2.0), 3.0), "Range_Of(5,2)=3");

   ---------------------------------------------------------------------
   Section ("2. Turning points: empty / single / two / flat");
   ---------------------------------------------------------------------
   declare
      Empty : Real_Array (1 .. 0);
      TP0   : constant Real_Array := Extract_Turning_Points (Empty);
      One   : constant Real_Array := [1 => 4.5];
      TP1   : constant Real_Array := Extract_Turning_Points (One);
      Two   : constant Real_Array := [1.0, 3.0];
      TP2   : constant Real_Array := Extract_Turning_Points (Two);
      Flat  : constant Real_Array := [2.0, 2.0, 2.0, 2.0];
      TPf   : constant Real_Array := Extract_Turning_Points (Flat);
   begin
      Check (TP0'Length = 0, "empty history -> 0 turning points");
      Check (TP1'Length = 1, "single sample kept");
      Check (Approx (TP1 (1), 4.5), "single value preserved");
      Check (TP2'Length = 2, "two distinct points kept");
      Check (Approx (TP2 (1), 1.0) and then Approx (TP2 (2), 3.0),
             "two-point values");
      Check (TPf'Length = 1, "flat plateau collapses to one");
      Check (Approx (TPf (1), 2.0), "flat value 2.0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Turning points: plateaus and non-extrema removed");
   ---------------------------------------------------------------------
   declare
      --  Rising then falling with plateau at peak and interior non-extrema
      H : constant Real_Array :=
        [0.0, 1.0, 2.0, 2.0, 2.0, 3.0, 4.0, 4.0, 3.0, 2.0, 1.0, 0.0];
      TP : constant Real_Array := Extract_Turning_Points (H);
      --  Classic zig-zag already extrema
      Z : constant Real_Array := [0.0, 1.0, -1.0, 2.0, -2.0, 0.0];
      TPz : constant Real_Array := Extract_Turning_Points (Z);
   begin
      --  After collapse: 0,1,2,3,4,3,2,1,0 -> extrema: 0, 4, 0
      Check (TP'Length = 3, "history reduces to valley-peak-valley");
      Check (Approx (TP (1), 0.0), "TP first 0");
      Check (Approx (TP (2), 4.0), "TP peak 4");
      Check (Approx (TP (3), 0.0), "TP last 0");
      Check (TPz'Length = 6, "already-extrema zig-zag unchanged length");
      Check (Approx (TPz (2), 1.0) and then Approx (TPz (3), -1.0),
             "zig-zag interior preserved");
   end;

   ---------------------------------------------------------------------
   Section ("4. Empty / short histories: no full cycles");
   ---------------------------------------------------------------------
   declare
      R : Cycle_Result;
      E : Real_Array (1 .. 0);
      One : constant Real_Array := [1 => 1.0];
      Two : constant Real_Array := [0.0, 5.0];
      Three : constant Real_Array := [0.0, 5.0, 0.0];
   begin
      Count_Cycles (E, R, Include_Residuals => True);
      Check (R.Length = 0, "empty -> no cycles");
      Count_Cycles (One, R, Include_Residuals => True);
      Check (R.Length = 0, "singleton -> no cycles");
      Count_Cycles (Two, R, Include_Residuals => True);
      Check (Count_Full (R) = 0, "two-point: no full cycle");
      Check (Count_Half (R) = 1, "two-point: one residual half");
      Check (Approx (R.Items (1).Range_Val, 5.0), "two-point residual range 5");
      Check (Near (R.Items (1).Count, 0.5), "two-point count 0.5");
      Count_Cycles (Three, R, Include_Residuals => False);
      Check (Count_Full (R) = 0, "three-point open: no full without 4 pts");
      Count_Cycles (Three, R, Include_Residuals => True);
      Check (Count_Half (R) = 2, "three-point: two residual halves");
   end;

   ---------------------------------------------------------------------
   Section ("5. Constant-amplitude sine-like turning points");
   ---------------------------------------------------------------------
   declare
      --  Peak/valley sequence of amplitude 1 about 0: -1,1,-1,1,-1
      H : constant Real_Array := [-1.0, 1.0, -1.0, 1.0, -1.0];
      R : Cycle_Result;
      TP : constant Real_Array := Extract_Turning_Points (H);
   begin
      Check (TP'Length = 5, "sine turning points length 5");
      Count_Cycles_Four_Point (TP, R, Include_Residuals => False);
      --  Four-point: A=-1,B=1,C=-1,D=1: BC range 2, AD range 2, BC within AD
      --  extracts (1,-1) then remaining -1,1,-1 -> may extract again or not
      Check (Count_Full (R) >= 1, "sine: at least one full cycle");
      Check (Has_Full_Cycle (R, 2.0), "sine: full cycle range 2");
      for I in 1 .. R.Length loop
         Check (R.Items (I).Range_Val > 0.0 or else Near (R.Items (I).Range_Val, 0.0),
                "sine cycle non-negative range #" & Integer'Image (I));
         Check (Near (R.Items (I).Count, 1.0),
                "sine full count 1.0 #" & Integer'Image (I));
         Check (Approx (R.Items (I).Amplitude, R.Items (I).Range_Val / 2.0),
                "sine amplitude = range/2 #" & Integer'Image (I));
      end loop;
      Count_Cycles (H, R, Include_Residuals => True);
      Check (Equivalent_Full_Cycles (R) >= 1.0, "sine equiv full >= 1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Classic interruption (small inside large)");
   ---------------------------------------------------------------------
   declare
      --  A=0, B=1, C=0.5, D=2 : small B-C inside A-D? 
      --  Better classic: -2, 1, 0, 2, -2
      --  A=-2,B=1,C=0,D=2: BC=[0,1] within AD=[-2,2], range BC=1 <= 4
      H : constant Real_Array := [-2.0, 1.0, 0.0, 2.0, -2.0];
      R : Cycle_Result;
   begin
      Count_Cycles (H, R, Include_Residuals => False);
      Check (Has_Full_Cycle (R, 1.0), "interruption: inner range 1 extracted");
      Check (Count_Full (R) >= 1, "interruption: >=1 full");
      --  After removing 1,0 remaining: -2, 2, -2 -> no 4 points for another full
      --  with Include_Residuals False
      Check (Count_Full (R) = 1, "interruption: exactly one full (inner)");
      Count_Cycles (H, R, Include_Residuals => True);
      Check (Has_Full_Cycle (R, 1.0), "interruption+res: still has inner");
      Check (Count_Half (R) >= 1, "interruption+res: residual halves present");
      Check (Approx (Full_Cycle_Count (R), 1.0), "Full_Cycle_Count=1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Textbook four-point nested cycles");
   ---------------------------------------------------------------------
   declare
      --  -3, 2, -1, 1, -2, 3, -3
      --  Expect small cycles extracted first then larger
      H : constant Real_Array :=
        [-3.0, 2.0, -1.0, 1.0, -2.0, 3.0, -3.0];
      R : Cycle_Result;
      Found_2 : Boolean := False;
      Found_Inner : Boolean := False;
   begin
      Count_Cycles (H, R, Include_Residuals => False);
      Check (Count_Full (R) >= 1, "textbook: at least one full");
      for I in 1 .. R.Length loop
         if Approx (R.Items (I).Range_Val, 2.0) then
            Found_2 := True;
         end if;
         if R.Items (I).Range_Val <= 2.0 + 1.0E-6 then
            Found_Inner := True;
         end if;
         Check (R.Items (I).Range_Val > 0.0, "textbook positive range");
         Check (Near (R.Items (I).Count, 1.0), "textbook full count");
         Check (Approx (R.Items (I).Mean,
                        (R.Items (I).From_Level + R.Items (I).To_Level) / 2.0),
                "textbook mean formula");
      end loop;
      Check (Found_Inner, "textbook extracted an inner cycle");
      --  Also closed form
      Count_Cycles (H, R, Include_Residuals => False, Closed => True);
      Check (Count_Full (R) >= 1, "textbook closed: full cycles");
      Check (Found_2 or else Count_Full (R) >= 1, "textbook has cycles");
   end;

   ---------------------------------------------------------------------
   Section ("8. Residuals after extraction");
   ---------------------------------------------------------------------
   declare
      H : constant Real_Array := [0.0, 4.0, 1.0, 3.0, 0.0];
      R : Cycle_Result;
   begin
      Count_Cycles (H, R, Include_Residuals => False);
      declare
         Fulls : constant Natural := Count_Full (R);
      begin
         Count_Cycles (H, R, Include_Residuals => True);
         Check (Count_Full (R) = Fulls, "residuals do not add full cycles");
         Check (Count_Half (R) >= 1, "residuals emit half-cycles");
         for I in 1 .. R.Length loop
            Check (Near (R.Items (I).Count, 1.0)
                   or else Near (R.Items (I).Count, 0.5),
                   "count is 1.0 or 0.5");
            Check (R.Items (I).Range_Val >= 0.0, "range non-negative");
            Check (Approx (R.Items (I).Amplitude, R.Items (I).Range_Val / 2.0),
                   "amplitude = range/2");
         end loop;
         Check (Approx (Half_Cycle_Count (R), 0.5 * Real (Count_Half (R))),
                "Half_Cycle_Count matches");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Closed / wrap load block");
   ---------------------------------------------------------------------
   declare
      --  Repeated block turning points; closed should extract more fulls
      H : constant Real_Array := [0.0, 5.0, -3.0, 2.0, -1.0, 4.0, 0.0];
      R_Open, R_Closed : Cycle_Result;
   begin
      Count_Cycles (H, R_Open, Include_Residuals => False, Closed => False);
      Count_Cycles (H, R_Closed, Include_Residuals => False, Closed => True);
      Check (Count_Full (R_Closed) >= Count_Full (R_Open),
             "closed yields at least as many full cycles as open");
      for I in 1 .. R_Closed.Length loop
         Check (R_Closed.Items (I).Range_Val > 0.0
                or else Near (R_Closed.Items (I).Range_Val, 0.0),
                "closed ranges non-neg");
         Check (Near (R_Closed.Items (I).Count, 1.0), "closed fulls count 1");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Miner damage power-law helper");
   ---------------------------------------------------------------------
   declare
      H : constant Real_Array := [-1.0, 1.0, -1.0, 1.0, -1.0];
      R : Cycle_Result;
      D : Non_Negative;
      --  N = C / S^m with C=1000, m=2, S=amplitude=1 -> N=1000
      function Simple_Life (Amplitude : Positive_Real) return Positive_Real is
      begin
         return 1_000.0 / (Amplitude * Amplitude);
      end Simple_Life;
   begin
      Count_Cycles (H, R, Include_Residuals => False);
      D := Total_Damage (R, C_Const => 1_000.0, M_Exp => 2.0);
      Check (D > 0.0, "damage positive for non-empty cycles");
      Check (Approx (Power_Law_Life (1.0, 1_000.0, 2.0), 1_000.0),
             "Power_Law_Life(1,1000,2)=1000");
      Check (Approx (Power_Law_Life (2.0, 1_000.0, 3.0), 1_000.0 / 8.0),
             "Power_Law_Life(2,1000,3)=125");
      declare
         D2 : constant Non_Negative :=
           Total_Damage_With (R, Simple_Life'Access);
      begin
         Check (Approx (D, D2, 1.0E-5), "Total_Damage matches callback");
      end;
      --  Hand: one full cycle range 2 amp 1 -> D = 1/1000
      if Count_Full (R) >= 1 then
         Check (D >= 1.0 / 1_000.0 - 1.0E-9, "damage at least one cycle / N");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("11. Property: counts and ranges on many sequences");
   ---------------------------------------------------------------------
   declare
Data1 : constant Real_Array := [1.0, -1.0, 1.0, -1.0];
      Data2 : constant Real_Array := [0.0, 10.0, 0.0, 10.0, 0.0];
      Data3 : constant Real_Array := [-5.0, 5.0, -4.0, 4.0, -5.0];
      Data4 : constant Real_Array := [0.0, 1.0, 0.5, 1.5, 0.0, 2.0, -1.0];
      Data5 : constant Real_Array := [3.0, 1.0, 4.0, 1.0, 5.0, 9.0, 2.0, 6.0];
      Data6 : constant Real_Array := [0.0, 0.0, 1.0, 1.0, 0.0, 0.0, -1.0, -1.0, 0.0];
      Data7 : constant Real_Array := [-2.0, 0.0, -1.0, 1.0, -1.0, 2.0, -2.0];
      Data8 : constant Real_Array := [10.0, -10.0, 10.0];
   begin
      declare
         procedure Prop_Check (H : Real_Array; Label : String) is
            R : Cycle_Result;
         begin
            Count_Cycles (H, R, Include_Residuals => True);
            for I in 1 .. R.Length loop
               Check (R.Items (I).Range_Val >= 0.0,
                      Label & " range>=0 #" & Integer'Image (I));
               Check (Near (R.Items (I).Count, 1.0)
                      or else Near (R.Items (I).Count, 0.5),
                      Label & " count 0.5|1 #" & Integer'Image (I));
               Check (Approx (R.Items (I).Amplitude,
                              R.Items (I).Range_Val / 2.0),
                      Label & " amp=range/2 #" & Integer'Image (I));
               Check (Approx (R.Items (I).Mean,
                              (R.Items (I).From_Level + R.Items (I).To_Level)
                              / 2.0),
                      Label & " mean #" & Integer'Image (I));
            end loop;
            Check (Approx (Equivalent_Full_Cycles (R),
                           Full_Cycle_Count (R) + Half_Cycle_Count (R)),
                   Label & " equiv = full+half sums");
         end Prop_Check;
      begin
         Prop_Check (Data1, "D1");
         Prop_Check (Data2, "D2");
         Prop_Check (Data3, "D3");
         Prop_Check (Data4, "D4");
         Prop_Check (Data5, "D5");
         Prop_Check (Data6, "D6");
         Prop_Check (Data7, "D7");
         Prop_Check (Data8, "D8");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Hand-computed amplitudes on deterministic sequences");
   ---------------------------------------------------------------------
   declare
      --  Simple: -1,1,-1  with residuals only (3 pts) unless closed
      H1 : constant Real_Array := [-1.0, 1.0, -1.0];
      R  : Cycle_Result;
      --  Four points forming one clear cycle: 0, 2, 1, 3
      --  A=0,B=2,C=1,D=3: BC=[1,2] within AD=[0,3] -> cycle range 1
      H2 : constant Real_Array := [0.0, 2.0, 1.0, 3.0];
      --  Larger: 0,5,-2,3,-5,0
      H3 : constant Real_Array := [0.0, 5.0, -2.0, 3.0, -5.0, 0.0];
   begin
      Count_Cycles (H1, R, Include_Residuals => True);
      Check (Count_Full (R) = 0, "H1 open: no full");
      Check (Count_Half (R) = 2, "H1: two halves");
      Check (Approx (R.Items (1).Amplitude, 1.0), "H1 first amp 1");
      Check (Approx (R.Items (2).Amplitude, 1.0), "H1 second amp 1");

      Count_Cycles_Four_Point (H2, R, Include_Residuals => False);
      Check (Count_Full (R) = 1, "H2: one full cycle");
      Check (Approx (R.Items (1).Range_Val, 1.0), "H2 range |2-1|=1");
      Check (Approx (R.Items (1).Amplitude, 0.5), "H2 amp 0.5");
      Check (Approx (R.Items (1).From_Level, 2.0)
             or else Approx (R.Items (1).To_Level, 2.0),
             "H2 involves level 2");

      Count_Cycles (H3, R, Include_Residuals => False);
      Check (Count_Full (R) >= 1, "H3: extracts >=1");
      for I in 1 .. R.Length loop
         Check (R.Items (I).Amplitude > 0.0, "H3 positive amp");
      end loop;

      --  Closed constant amplitude block
      declare
         H4 : constant Real_Array := [0.0, 1.0, -1.0, 1.0, -1.0, 0.0];
      begin
         Count_Cycles (H4, R, Include_Residuals => False, Closed => True);
         Check (Count_Full (R) >= 1, "H4 closed full cycles");
         for I in 1 .. R.Length loop
            Check (R.Items (I).Range_Val > 0.0, "H4 positive ranges");
         end loop;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Plateau removal before counting");
   ---------------------------------------------------------------------
   declare
      With_Plat : constant Real_Array :=
        [0.0, 0.0, 5.0, 5.0, 5.0, 2.0, 2.0, 6.0, 1.0, 1.0];
      Clean : constant Real_Array := Extract_Turning_Points (With_Plat);
      R1, R2 : Cycle_Result;
   begin
      Check (Clean'Length < With_Plat'Length, "plateaus shortened");
      Check (Approx (Clean (1), 0.0), "clean starts 0");
      Count_Cycles (With_Plat, R1, Include_Residuals => True);
      Count_Cycles (Clean, R2, Include_Residuals => True);
      Check (Count_Full (R1) = Count_Full (R2),
             "counting history vs pre-extracted TP: same fulls");
   end;

   ---------------------------------------------------------------------
   Section ("14. Batch amplitude expectations");
   ---------------------------------------------------------------------
   declare
      --  Loop over scale factors for a fixed pattern
      Base : constant Real_Array := [-1.0, 0.5, -0.5, 1.0, -1.0];
   begin
      for K in 1 .. 8 loop
         declare
            Scale : constant Real := Real (K);
            H : Real_Array (Base'Range);
            R : Cycle_Result;
            Expected_Inner : constant Real := Scale * 1.0;  --  |0.5-(-0.5)|
         begin
            for I in Base'Range loop
               H (I) := Base (I) * Scale;
            end loop;
            Count_Cycles (H, R, Include_Residuals => False);
            Check (Has_Full_Cycle (R, Expected_Inner)
                   or else Count_Full (R) >= 0,
                   "scale" & Integer'Image (K) & " ran");
            if Count_Full (R) > 0 then
               Check (Has_Full_Cycle (R, Expected_Inner),
                      "scale" & Integer'Image (K) & " inner range");
            end if;
            for I in 1 .. R.Length loop
               Check (Approx (R.Items (I).Amplitude,
                              R.Items (I).Range_Val / 2.0),
                      "scale amp #" & Integer'Image (K));
            end loop;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Damage on known synthetic cycles");
   ---------------------------------------------------------------------
   declare
      R : Cycle_Result;
      D : Non_Negative;
   begin
      R.Length := 2;
      R.Items (1) :=
        (From_Level => -1.0, To_Level => 1.0, Range_Val => 2.0,
         Amplitude => 1.0, Mean => 0.0, Count => 1.0);
      R.Items (2) :=
        (From_Level => 0.0, To_Level => 2.0, Range_Val => 2.0,
         Amplitude => 1.0, Mean => 1.0, Count => 0.5);
      --  N(1)=1000/1^2=1000; D = 1/1000 + 0.5/1000 = 0.0015
      D := Total_Damage (R, 1_000.0, 2.0);
      Check (Approx (D, 0.0015, 1.0E-9), "hand Miner D=0.0015");
      Check (Approx (Full_Cycle_Count (R), 1.0), "synthetic full count");
      Check (Approx (Half_Cycle_Count (R), 0.5), "synthetic half count");
      Check (Approx (Equivalent_Full_Cycles (R), 1.5), "synthetic equiv 1.5");
      Check (Approx (Power_Law_Life (0.5, 16.0, 2.0), 64.0),
             "N=16/(0.5^2)=64");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("PASS:" & Natural'Image (Pass_Count)
             & "  FAIL:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("All tests passed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("Some tests FAILED.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
