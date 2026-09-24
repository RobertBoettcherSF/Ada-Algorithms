with Ada.Text_IO; use Ada.Text_IO;
with Mission_FSM; use Mission_FSM;

procedure Test_Mission_FSM is
   Pass : Natural := 0;
   Fail : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Put_Line ("PASS: " & Name);
         Pass := Pass + 1;
      else
         Put_Line ("FAIL: " & Name);
         Fail := Fail + 1;
      end if;
   end Check;

   M : Machine;
   St : Status;
   Saved : State;
begin
   -- Happy path Idle→…→Return→Idle
   Init (M);
   Check (Current (M) = Idle, "start Idle");
   Request (M, Pickup, St);       Check (St = Ok and then Current (M) = Pickup, "→Pickup");
   Request (M, Transit, St);      Check (St = Ok and then Current (M) = Transit, "→Transit");
   Request (M, Last_Yards, St);   Check (St = Ok and then Current (M) = Last_Yards, "→Last_Yards");
   Request (M, Doorstep, St);     Check (St = Ok and then Current (M) = Doorstep, "→Doorstep");
   Request (M, Unlock, St);       Check (St = Ok and then Current (M) = Unlock, "→Unlock");
   Request (M, Return_Home, St);  Check (St = Ok and then Current (M) = Return_Home, "→Return");
   Request (M, Idle, St);         Check (St = Ok and then Current (M) = Idle, "→Idle");

   -- Fault from Transit
   Init (M);
   Request (M, Pickup, St);
   Request (M, Transit, St);
   Request (M, Fault, St);
   Check (St = Faulted and then Current (M) = Fault, "Fault from Transit");
   Request (M, Idle, St);
   Check (St = Ok and then Current (M) = Idle, "Fault→Idle");

   -- Remote then resume
   Init (M);
   Request (M, Pickup, St);
   Request (M, Transit, St);
   Saved := Current (M);
   Request (M, Remote, St);
   Check (St = Ok and then Current (M) = Remote, "enter Remote");
   Request (M, Saved, St);
   Check (St = Ok and then Current (M) = Saved, "resume from Remote");

   -- Reject Pickup→Unlock
   Init (M);
   Request (M, Pickup, St);
   Request (M, Unlock, St);
   Check (St = Rejected and then Current (M) = Pickup, "reject Pickup→Unlock");

   New_Line;
   Put_Line ("Result:" & Pass'Image & " PASS," & Fail'Image & " FAIL");
   if Fail > 0 then
      raise Program_Error with "tests failed";
   end if;
end Test_Mission_FSM;
