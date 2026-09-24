with Ada.Text_IO; use Ada.Text_IO;
with Locomotion_Interlock; use Locomotion_Interlock;

procedure Test_Locomotion_Interlock is
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

   I : Interlock;
   St : Status;
begin
   -- Illegal mode mix rejected: Legs while Wheels_Armed without transition
   Init (I);
   Set_Wheels_Armed (I, True);
   Request_Mode (I, Wheels, St);
   Check (St = Ok and then Current_Mode (I) = Wheels, "enter Wheels");
   Request_Mode (I, Legs, St);
   Check (St = Rejected and then Current_Mode (I) = Wheels,
          "illegal mode mix rejected (Legs while Wheels_Armed)");

   -- Legal path via Hybrid
   Request_Mode (I, Hybrid_Transition, St);
   Check (St = Ok, "enter Hybrid_Transition");
   Request_Mode (I, Legs, St);
   Check (St = Ok and then Current_Mode (I) = Legs, "Legs via Hybrid ok");

   -- Stairs + wheels-only rejected
   Init (I);
   Request_Mode (I, Wheels, St);
   Request_Stairs (I, St);
   Check (St = Rejected, "stairs+wheels-only rejected");

   -- Stairs allowed in Legs / Hybrid
   Init (I);
   Set_Wheels_Armed (I, False);
   Request_Mode (I, Hybrid_Transition, St);
   Request_Mode (I, Legs, St);
   Request_Stairs (I, St);
   Check (St = Ok, "stairs with Legs ok");

   Init (I);
   Request_Mode (I, Hybrid_Transition, St);
   Request_Stairs (I, St);
   Check (St = Ok, "stairs with Hybrid ok");

   -- Safe_Stop always allowed
   Init (I);
   Request_Mode (I, Wheels, St);
   Request_Mode (I, Safe_Stop, St);
   Check (St = Ok and then Current_Mode (I) = Safe_Stop, "Safe_Stop from Wheels");
   Request_Mode (I, Hybrid_Transition, St);
   Request_Mode (I, Legs, St);
   Request_Mode (I, Safe_Stop, St);
   Check (St = Ok and then Current_Mode (I) = Safe_Stop, "Safe_Stop from Legs");

   -- Speed limits per mode
   Check (Speed_Limit (Wheels) = Max_Wheels, "wheels speed limit");
   Check (Speed_Limit (Legs) = Max_Legs, "legs speed limit");
   Check (Speed_Limit (Hybrid_Transition) = Max_Hybrid, "hybrid speed limit");
   Check (Speed_Limit (Safe_Stop) = Max_Stop, "stop speed limit");

   New_Line;
   Put_Line ("Result:" & Pass'Image & " PASS," & Fail'Image & " FAIL");
   if Fail > 0 then
      raise Program_Error with "tests failed";
   end if;
end Test_Locomotion_Interlock;
