-- Fixtures for Corp_Profile, Economy, Research_Alloc, Shield_Octagon.
with Ada.Text_IO;
with Corp_Profile;
with Economy;
with Research_Alloc;
with Shield_Octagon;

procedure Tests is
   use Ada.Text_IO;
   use type Corp_Profile.Multiplier;
   use type Economy.Credits;

   Passed : Natural := 0;
   Failed : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Passed := Passed + 1;
         Put_Line ("PASS: " & Name);
      else
         Failed := Failed + 1;
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   procedure Test_Corp_Profile is
      B : constant Corp_Profile.Profile := Corp_Profile.Balanced;
      F : constant Corp_Profile.Profile := Corp_Profile.Finance_Heavy;
      R : constant Corp_Profile.Profile := Corp_Profile.Research_Heavy;
      M : constant Corp_Profile.Profile := Corp_Profile.Military_Heavy;
   begin
      Check (B.Max_Deploy = 6,
             "Balanced Max_Deploy = 6");
      Check (B.Finance_Mult = 1.0 and then B.Research_Mult = 1.0
             and then B.Military_Mult = 1.0, "Balanced multipliers = 1.0");
      Check (F.Finance_Mult > B.Finance_Mult, "Finance_Heavy finance mult");
      Check (R.Research_Mult > B.Research_Mult, "Research_Heavy research mult");
      Check (M.Military_Mult > B.Military_Mult, "Military_Heavy military mult");
      Check (M.Max_Deploy = 8, "Military_Heavy Max_Deploy = 8");
      Check (Corp_Profile.Can_Deploy (B, 6), "Can_Deploy exactly Max_Deploy");
      Check (not Corp_Profile.Can_Deploy (B, 7), "Cannot deploy above Max_Deploy");
      Check (Corp_Profile.Can_Deploy (M, 8), "Military can deploy 8");
      Check (not Corp_Profile.Can_Deploy (F, 6), "Finance_Heavy Max_Deploy 5");
   end Test_Corp_Profile;

   procedure Test_Economy is
      P : constant Corp_Profile.Profile := Corp_Profile.Balanced;
      S : Economy.State;
   begin
      S.Mines := 3;
      Economy.Recalc_Steady_Income (S, P);
      Check (S.Steady_Income = 300, "3 mines * 100 = 300 steady");

      Economy.Set_Research_Budget (S, 200);
      Check (S.Research_Budget = 200, "research budget set from steady");
      Check (Economy.Research_From_Steady_Only (S), "research <= steady");

      Economy.Add_Mission_Reward (S, 500);
      Check (S.Mission_Rewards = 500, "mission reward recorded");
      Check (S.Treasury = 500, "mission reward in treasury");
      Check (S.Research_Budget = 200, "mission reward does not change research");
      Check (Economy.Research_From_Steady_Only (S),
             "research still from steady only after reward");

      declare
         Heavy : constant Corp_Profile.Profile := Corp_Profile.Finance_Heavy;
         S2    : Economy.State;
      begin
         S2.Mines := 2;
         Economy.Recalc_Steady_Income (S2, Heavy);
         Check (S2.Steady_Income = 350,
                "finance mult 1.75 * 2 * 100 = 350");
      end;
   end Test_Economy;

   procedure Test_Research_Alloc is
      Budget : constant Economy.Credits := 100;
      A      : Research_Alloc.Allocation := Research_Alloc.Empty;
      Ok     : Boolean;
   begin
      Check (Research_Alloc.Total (A) = 0, "empty allocation total 0");
      Check (Research_Alloc.Is_Valid (A, Budget), "empty valid under budget");

      A := Research_Alloc.Even_Split (Budget);
      Check (Research_Alloc.Is_Valid (A, Budget), "even split valid");
      Check (Research_Alloc.Total (A) = Budget, "even split uses full budget");

      A := Research_Alloc.Empty;
      Research_Alloc.Set_Bucket
        (A, Research_Alloc.Weapons, 40, Budget, Ok);
      Check (Ok and then A (Research_Alloc.Weapons) = 40, "set weapons 40");
      Research_Alloc.Set_Bucket
        (A, Research_Alloc.Armor, 40, Budget, Ok);
      Check (Ok, "set armor 40 ok");
      Research_Alloc.Set_Bucket
        (A, Research_Alloc.Shields, 40, Budget, Ok);
      Check (not Ok, "reject over-budget shields");
      Check (A (Research_Alloc.Shields) = 0, "over-budget leaves shields 0");

      Research_Alloc.Set_Bucket
        (A, Research_Alloc.Life_Support, 10, Budget, Ok);
      Check (Ok, "life_support 10 ok");
      Research_Alloc.Set_Bucket
        (A, Research_Alloc.Sensors, 10, Budget, Ok);
      Check (Ok and then Research_Alloc.Total (A) = 100,
             "sensors fills remaining to budget");
   end Test_Research_Alloc;

   procedure Test_Shield_Octagon is
      U : Shield_Octagon.Unit :=
        Shield_Octagon.Full_Shields (Per_Facing => 50, Armor => 100);
      F : constant Shield_Octagon.Facing := 3;
   begin
      Check (U.Shields (1) = 50 and then U.Shields (8) = 50,
             "eight facings initialized");
      Check (U.Armor = 100, "armor initialized");

      Shield_Octagon.Apply_Energy (U, F, 30);
      Check (U.Shields (F) = 20, "energy reduces facing by 30");
      Check (U.Shields (1) = 50, "other facings untouched by energy");
      Check (U.Armor = 100, "energy does not hit armor");

      Shield_Octagon.Apply_Ballistic (U, F, 25, Pierce => False);
      Check (U.Armor = 100, "ballistic blocked while facing > 0");

      Shield_Octagon.Apply_Energy (U, F, 20);
      Check (Shield_Octagon.Facing_Down (U, F), "facing dropped to 0");

      Shield_Octagon.Apply_Ballistic (U, F, 25, Pierce => False);
      Check (U.Armor = 75, "ballistic hits armor when facing 0");

      declare
         V : Shield_Octagon.Unit :=
           Shield_Octagon.Full_Shields (Per_Facing => 40, Armor => 80);
      begin
         Shield_Octagon.Apply_Ballistic (V, 1, 15, Pierce => True);
         Check (V.Armor = 65 and then V.Shields (1) = 40,
                "pierce damages armor through shield");
      end;

      declare
         Kind : constant Shield_Octagon.Chassis_Kind := Shield_Octagon.Mech;
         pragma Unreferenced (Kind);
      begin
         Check (Shield_Octagon.Chassis_Kind'Pos (Shield_Octagon.Tank) = 1
                and then
                Shield_Octagon.Chassis_Kind'Pos (Shield_Octagon.Grav_Tank) = 2,
                "generic chassis kinds Mech/Tank/Grav_Tank");
      end;
   end Test_Shield_Octagon;

begin
   Put_Line ("Ada Corporate Wars Sim — clean-room educational tests");
   Test_Corp_Profile;
   Test_Economy;
   Test_Research_Alloc;
   Test_Shield_Octagon;
   New_Line;
   Put_Line ("Passed:" & Passed'Image & "  Failed:" & Failed'Image);
   if Failed > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
