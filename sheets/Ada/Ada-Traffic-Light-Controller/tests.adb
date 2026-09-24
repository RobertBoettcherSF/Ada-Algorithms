--  V&V harness for the clean-room Ada traffic-light controller.
--  Covers: conflict rejection, happy NS/EW cycle, fault→all-red, timer gates.

with Ada.Text_IO;        use Ada.Text_IO;
with Traffic_Phases;     use Traffic_Phases;
with Intersection_FSM;   use Intersection_FSM;
with Phase_Timers;       use Phase_Timers;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   I        : Intersection;
   Accepted : Boolean;
   T        : Timer;
   Cfg      : constant Config :=
     (Min_Green_Ticks => 3, Yellow_Ticks => 2, All_Red_Ticks => 1);
   Gate_OK  : Boolean;

begin
   ----------------------------------------------------------------
   Put_Line ("TEST 1 -- Conflict rejected (never both Green)");
   ----------------------------------------------------------------
   I := Create;
   Check ("1.1 initial all-red", In_All_Red (I) and then Is_Safe (I));
   Grant_Green (I, North_South, Accepted);
   Check ("1.2 NS green granted", Accepted
          and then Color_Of (I, North_South) = Green
          and then Color_Of (I, East_West) = Red);
   Grant_Green (I, East_West, Accepted);
   Check ("1.3 EW green rejected while NS green",
          not Accepted
          and then Color_Of (I, North_South) = Green
          and then Color_Of (I, East_West) = Red
          and then Is_Safe (I));
   Check ("1.4 Conflicts predicate on Green/Green",
          Conflicts (Green, Green));
   Check ("1.5 no Conflicts on Green/Red",
          not Conflicts (Green, Red));

   ----------------------------------------------------------------
   Put_Line ("TEST 2 -- Happy cycle NS then EW with all-red clearance");
   ----------------------------------------------------------------
   I := Create;
   Grant_Green (I, North_South, Accepted);
   Check ("2.1 NS green", Accepted and then Color_Of (I, North_South) = Green);
   Check ("2.2 ped Walk on NS / Dont_Walk on EW",
          Pedestrian_Of (I, North_South) = Walk
          and then Pedestrian_Of (I, East_West) = Dont_Walk);

   Enter_Yellow (I, Accepted);
   Check ("2.3 NS yellow", Accepted
          and then Color_Of (I, North_South) = Yellow
          and then Is_Safe (I));

   --  Cannot grant other axis during yellow (clearance incomplete).
   Grant_Green (I, East_West, Accepted);
   Check ("2.4 EW rejected during NS yellow",
          not Accepted and then Is_Safe (I));

   Enter_All_Red (I, Accepted);
   Check ("2.5 all-red clearance", Accepted and then In_All_Red (I));

   Grant_Green (I, East_West, Accepted);
   Check ("2.6 EW green after clearance", Accepted
          and then Color_Of (I, East_West) = Green
          and then Color_Of (I, North_South) = Red
          and then Is_Safe (I));

   Enter_Yellow (I, Accepted);
   Check ("2.7 EW yellow", Accepted
          and then Color_Of (I, East_West) = Yellow);

   Enter_All_Red (I, Accepted);
   Check ("2.8 return to all-red", Accepted and then In_All_Red (I));

   Grant_Green (I, North_South, Accepted);
   Check ("2.9 NS green again (full cycle)", Accepted
          and then Color_Of (I, North_South) = Green);

   ----------------------------------------------------------------
   Put_Line ("TEST 3 -- Fault forces All_Red");
   ----------------------------------------------------------------
   I := Create;
   Grant_Green (I, North_South, Accepted);
   pragma Assert (Accepted);
   Raise_Fault (I);
   Check ("3.1 faulted flag set", Is_Faulted (I));
   Check ("3.2 both axes Red after fault",
          In_All_Red (I)
          and then Color_Of (I, North_South) = Red
          and then Color_Of (I, East_West) = Red
          and then Is_Safe (I));
   Grant_Green (I, East_West, Accepted);
   Check ("3.3 grant rejected while faulted", not Accepted);
   Clear_Fault (I);
   Check ("3.4 fault cleared, still all-red",
          not Is_Faulted (I) and then In_All_Red (I));
   Grant_Green (I, East_West, Accepted);
   Check ("3.5 grant works after clear", Accepted
          and then Color_Of (I, East_West) = Green);

   ----------------------------------------------------------------
   Put_Line ("TEST 4 -- Phase_Timers gates (min green / yellow / all-red)");
   ----------------------------------------------------------------
   T := Make (Cfg, Min_Green);
   Check ("4.1 start Min_Green elapsed 0",
          Current_Phase (T) = Min_Green and then Elapsed (T) = 0);
   Check ("4.2 cannot advance before min green", not Can_Advance (T));

   Advance (T, Yellow, Gate_OK);
   Check ("4.3 early Advance rejected", not Gate_OK
          and then Current_Phase (T) = Min_Green);

   Tick (T); Tick (T); Tick (T);  -- 3 ticks = Min_Green_Ticks
   Check ("4.4 after 3 ticks Can_Advance", Can_Advance (T)
          and then Elapsed (T) = 3);

   Advance (T, Yellow, Gate_OK);
   Check ("4.5 Advance to Yellow", Gate_OK
          and then Current_Phase (T) = Yellow
          and then Elapsed (T) = 0);

   Advance (T, All_Red, Gate_OK);
   Check ("4.6 early leave Yellow rejected", not Gate_OK);

   Tick (T); Tick (T);  -- Yellow_Ticks = 2
   Advance (T, All_Red, Gate_OK);
   Check ("4.7 Advance to All_Red", Gate_OK
          and then Current_Phase (T) = All_Red);

   Tick (T);  -- All_Red_Ticks = 1
   Advance (T, Min_Green, Gate_OK);
   Check ("4.8 Advance back to Min_Green", Gate_OK
          and then Current_Phase (T) = Min_Green);

   Force_Phase (T, All_Red);
   Check ("4.9 Force_Phase resets elapsed",
          Current_Phase (T) = All_Red and then Elapsed (T) = 0);

   ----------------------------------------------------------------
   Put_Line ("TEST 5 -- Timer-gated happy path (FSM + timers)");
   ----------------------------------------------------------------
   I := Create;
   T := Make (Cfg, Min_Green);
   Grant_Green (I, North_South, Accepted);
   Check ("5.1 NS green under timer", Accepted);

   --  Hold min green
   for K in 1 .. Integer (Cfg.Min_Green_Ticks) loop
      Tick (T);
   end loop;
   Advance (T, Yellow, Gate_OK);
   Enter_Yellow (I, Accepted);
   Check ("5.2 yellow after min-green gate", Gate_OK and then Accepted
          and then Color_Of (I, North_South) = Yellow);

   for K in 1 .. Integer (Cfg.Yellow_Ticks) loop
      Tick (T);
   end loop;
   Advance (T, All_Red, Gate_OK);
   Enter_All_Red (I, Accepted);
   Check ("5.3 all-red after yellow gate", Gate_OK and then Accepted
          and then In_All_Red (I));

   for K in 1 .. Integer (Cfg.All_Red_Ticks) loop
      Tick (T);
   end loop;
   Advance (T, Min_Green, Gate_OK);
   Grant_Green (I, East_West, Accepted);
   Check ("5.4 EW green after all-red gate", Gate_OK and then Accepted
          and then Color_Of (I, East_West) = Green
          and then Is_Safe (I));

   ----------------------------------------------------------------
   Put_Line ("TEST 6 -- Phase helpers");
   ----------------------------------------------------------------
   Check ("6.1 Is_Proceed Green", Is_Proceed (Green));
   Check ("6.2 Is_Stop Red/Yellow", Is_Stop (Red) and then Is_Stop (Yellow));
   Check ("6.3 Pedestrian_For Red is Dont_Walk",
          Pedestrian_For (Red) = Dont_Walk);
   Check ("6.4 Required matches config",
          Required (Make (Cfg, Yellow)) = Cfg.Yellow_Ticks);

   ----------------------------------------------------------------
   New_Line;
   Put_Line ("=== " & Natural'Image (Pass_Count)
             & " passed," & Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
