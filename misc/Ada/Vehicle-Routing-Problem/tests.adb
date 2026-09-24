--  Standalone test suite for Vehicle_Routing_Problem (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Vehicle_Routing_Problem; use Vehicle_Routing_Problem;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);

   function Sum_Route_Costs (S : Solution) return Cost_Value is
   begin
      return Total_Cost (S);
   end Sum_Route_Costs;

   function Clear_Raises (N : Natural) return Boolean is
      P : Problem;
   begin
      Clear (P, N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Dist_Raises
     (P : in out Problem; From, To : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Set_Distance (P, From, To, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function Demand_Raises
     (P : in out Problem; C : Customer_Id; D : Integer) return Boolean
   is
   begin
      Set_Demand (P, C, D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Demand_Raises;

   function Cap_Raises (P : in out Problem; C : Integer) return Boolean is
   begin
      Set_Capacity (P, C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cap_Raises;

   function Fleet_Raises (P : in out Problem; K : Natural) return Boolean is
   begin
      Set_Max_Vehicles (P, K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Fleet_Raises;

   function CW_Raises (P : Problem) return Boolean is
      S : Solution;
   begin
      Solve_Clarke_Wright (P, S);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end CW_Raises;

   function NN_Raises (P : Problem) return Boolean is
      S : Solution;
   begin
      Solve_Nearest_Neighbor (P, S);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end NN_Raises;

   function Exact_Raises (P : Problem) return Boolean is
      S : Solution;
   begin
      Solve_Exact (P, S);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   function Get_Dist_Raises
     (P : Problem; From, To : Vertex_Id) return Boolean
   is
      D : Cost_Value;
   begin
      D := Distance (P, From, To);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Dist_Raises;

   function Get_Dem_Raises
     (P : Problem; C : Customer_Id) return Boolean
   is
      D : Demand_Value;
   begin
      D := Demand_Of (P, C);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Dem_Raises;

   function Sav_Raises
     (P : Problem; I, J : Customer_Id) return Boolean
   is
      S : Savings_Value;
   begin
      S := Savings (P, I, J);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sav_Raises;

   procedure Fill_Line3 (P : in out Problem) is
   begin
      --  Depot —10— 1 —10— 2 —10— 3  (line metric)
      Clear (P, 3);
      Set_Capacity (P, 2);
      Set_Distance (P, 0, 1, 10);
      Set_Distance (P, 0, 2, 20);
      Set_Distance (P, 0, 3, 30);
      Set_Distance (P, 1, 2, 10);
      Set_Distance (P, 1, 3, 20);
      Set_Distance (P, 2, 3, 10);
      Set_Demand (P, 1, 1);
      Set_Demand (P, 2, 1);
      Set_Demand (P, 3, 1);
   end Fill_Line3;

   procedure Fill_Hand3 (P : in out Problem) is
   begin
      --  Hand-checked: optimal 13 (routes 0-1-2-0 cost 7 + 0-3-0 cost 6).
      Clear (P, 3);
      Set_Capacity (P, 5);
      Set_Distance (P, 0, 1, 2);
      Set_Distance (P, 0, 2, 3);
      Set_Distance (P, 0, 3, 3);
      Set_Distance (P, 1, 2, 2);
      Set_Distance (P, 1, 3, 4);
      Set_Distance (P, 2, 3, 2);
      Set_Demand (P, 1, 2);
      Set_Demand (P, 2, 3);
      Set_Demand (P, 3, 3);
   end Fill_Hand3;

   procedure Fill_Symmetric
     (P : in out Problem; N : Natural; Cap : Integer; Seed : Natural)
   is
      S : constant Natural := Seed;
   begin
      Clear (P, N);
      Set_Capacity (P, Cap);
      for I in 0 .. N loop
         for J in I + 1 .. N loop
            declare
               D : Integer;
            begin
               if I = 0 then
                  D := 4 + Integer ((J * 5 + S) mod 11);
               else
                  D := 2 + Integer (abs (I - J) * 3
                                    + ((I * 7 + J * 3 + S) mod 9));
               end if;
               Set_Distance (P, Vertex_Id (I), Vertex_Id (J), D);
            end;
         end loop;
      end loop;
      for C in 1 .. N loop
         Set_Demand (P, Customer_Id (C), 1 + Integer ((C + S) mod 3));
      end loop;
   end Fill_Symmetric;

   function All_Stops_In_Range (P : Problem; S : Solution) return Boolean is
   begin
      for V in 1 .. S.Vehicle_Count loop
         declare
            R : Route renames S.Routes (Vehicle_Id (V));
         begin
            for K in 1 .. R.Length loop
               if Natural (R.Stops (K)) > Customer_Count (P) then
                  return False;
               end if;
            end loop;
         end;
      end loop;
      return True;
   end All_Stops_In_Range;

   P     : Problem;
   SCW   : Solution;
   SNN   : Solution;
   SEX   : Solution;
   R     : Route;
   Sav   : Savings_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Empty N=0");
   ------------------------------------------------------------------
   Clear (P, 0);
   Check (Customer_Count (P) = Nat (0), "empty N=0");
   Check (Capacity_Of (P) = 0, "empty capacity 0");
   Check (Max_Vehicles_Of (P) = Nat (0), "empty fleet stored 0");
   Check (Effective_Fleet (P) = Nat (0), "empty effective fleet 0");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "empty CW feasible");
   Check (SCW.Vehicle_Count = Nat (0), "empty CW 0 vehicles");
   Check (SCW.Total_Cost = 0, "empty CW cost 0");
   Check (Is_Feasible (P, SCW), "empty CW Is_Feasible");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "empty NN feasible");
   Check (SNN.Vehicle_Count = Nat (0), "empty NN 0 vehicles");
   Check (SNN.Total_Cost = 0, "empty NN cost 0");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "empty Exact feasible");
   Check (SEX.Total_Cost = 0, "empty Exact cost 0");
   Check (Serves_Each_Customer_Once (P, SCW), "empty serves-once");

   ------------------------------------------------------------------
   Section ("2. Single customer");
   ------------------------------------------------------------------
   Clear (P, 1);
   Set_Capacity (P, 10);
   Set_Distance (P, 0, 1, 7);
   Set_Demand (P, 1, 4);
   Check (Customer_Count (P) = 1, "N=1");
   Check (Distance (P, 0, 1) = 7, "dist 0-1");
   Check (Distance (P, 1, 0) = 7, "symmetric 1-0");
   Check (Demand_Of (P, 1) = 4, "demand 1");
   Check (Savings (P, 1, 1) = Savings_Value (7 + 7 - 0), "s_11 radial");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "N=1 CW feasible");
   Check (SCW.Vehicle_Count = 1, "N=1 CW 1 vehicle");
   Check (SCW.Total_Cost = 14, "N=1 CW cost 14");
   Check (SCW.Routes (1).Length = 1, "N=1 CW one stop");
   Check (SCW.Routes (1).Stops (1) = 1, "N=1 CW stop 1");
   Check (SCW.Routes (1).Load = 4, "N=1 CW load 4");
   Check (Is_Feasible (P, SCW), "N=1 CW Is_Feasible");
   Check (Route_Cost (P, SCW.Routes (1)) = 14, "N=1 Route_Cost");
   Check (Route_Load (P, SCW.Routes (1)) = 4, "N=1 Route_Load");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "N=1 NN feasible");
   Check (SNN.Total_Cost = 14, "N=1 NN cost 14");
   Check (SNN.Vehicle_Count = 1, "N=1 NN 1 vehicle");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "N=1 Exact feasible");
   Check (SEX.Total_Cost = 14, "N=1 Exact cost 14");
   Check (Is_Capacity_Feasible (P, SCW.Routes (1)), "N=1 cap ok");

   --  Zero distance to the single customer.
   Set_Distance (P, 0, 1, 0);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Total_Cost = 0, "N=1 zero dist CW");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Total_Cost = 0, "N=1 zero dist NN");
   Solve_Exact (P, SEX);
   Check (SEX.Total_Cost = 0, "N=1 zero dist Exact");

   ------------------------------------------------------------------
   Section ("3. Two customers, one vehicle");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 10);
   Set_Distance (P, 0, 1, 5);
   Set_Distance (P, 0, 2, 6);
   Set_Distance (P, 1, 2, 3);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 3);
   Sav := Savings (P, 1, 2);
   Check (Sav = Savings_Value (5 + 6 - 3), "s_12 = 8");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "2-fit CW feasible");
   Check (SCW.Vehicle_Count = 1, "2-fit CW 1 vehicle");
   Check (Is_Feasible (P, SCW), "2-fit CW Is_Feasible");
   --  Merged tour 0-1-2-0 = 5+3+6 = 14 (or 0-2-1-0 same).
   Check (SCW.Total_Cost = 14, "2-fit CW cost 14");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "2-fit NN feasible");
   Check (SNN.Vehicle_Count = 1, "2-fit NN 1 vehicle");
   Check (SNN.Total_Cost = 14, "2-fit NN cost 14");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "2-fit Exact feasible");
   Check (SEX.Total_Cost = 14, "2-fit Exact 14");
   Check (SEX.Total_Cost <= SCW.Total_Cost, "exact ≤ CW");
   Check (SEX.Total_Cost <= SNN.Total_Cost, "exact ≤ NN");

   ------------------------------------------------------------------
   Section ("4. Two customers, capacity splits");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 5);
   Set_Distance (P, 0, 1, 4);
   Set_Distance (P, 0, 2, 5);
   Set_Distance (P, 1, 2, 1);
   Set_Demand (P, 1, 5);
   Set_Demand (P, 2, 5);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "2-split CW feasible");
   Check (SCW.Vehicle_Count = 2, "2-split CW 2 vehicles");
   Check (SCW.Total_Cost = 18, "2-split CW 4+4+5+5=18");
   Check (Is_Feasible (P, SCW), "2-split CW Is_Feasible");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "2-split NN feasible");
   Check (SNN.Vehicle_Count = 2, "2-split NN 2 vehicles");
   Check (SNN.Total_Cost = 18, "2-split NN 18");
   Solve_Exact (P, SEX);
   Check (SEX.Total_Cost = 18, "2-split Exact 18");
   Check (Serves_Each_Customer_Once (P, SCW), "2-split unique");

   ------------------------------------------------------------------
   Section ("5. Line of 3: CW vs NN differ");
   ------------------------------------------------------------------
   Fill_Line3 (P);
   Check (Savings (P, 2, 3) = 40, "line s_23=40");
   Check (Savings (P, 1, 2) = 20, "line s_12=20");
   Check (Savings (P, 1, 3) = 20, "line s_13=20");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "line CW feasible");
   Check (SCW.Vehicle_Count = 2, "line CW 2 vehicles");
   --  Merge 2-3 (savings 40), leftover 0-1-0: costs 60 + 20 = 80.
   Check (SCW.Total_Cost = 80, "line CW cost 80");
   Check (Is_Feasible (P, SCW), "line CW Is_Feasible");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "line NN feasible");
   Check (SNN.Vehicle_Count = 2, "line NN 2 vehicles");
   --  Seed closest to depot is 1; then 2 fits; 3 alone: 40 + 60 = 100.
   Check (SNN.Total_Cost = 100, "line NN cost 100");
   Check (SCW.Total_Cost /= SNN.Total_Cost, "line CW ≠ NN");
   Check (SCW.Total_Cost < SNN.Total_Cost, "line CW better than NN");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "line Exact feasible");
   Check (SEX.Total_Cost = 80, "line Exact 80 (matches CW)");
   Check (Is_Feasible (P, SEX), "line Exact Is_Feasible");
   Check (Is_Feasible (P, SNN), "line NN Is_Feasible");

   ------------------------------------------------------------------
   Section ("6. Hand-checked 3-customer instance");
   ------------------------------------------------------------------
   Fill_Hand3 (P);
   Check (Savings (P, 1, 2) = 3, "hand s_12=3");
   Check (Savings (P, 1, 3) = 1, "hand s_13=1");
   Check (Savings (P, 2, 3) = 4, "hand s_23=4");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "hand CW feasible");
   Check (SCW.Total_Cost = 13, "hand CW 13");
   Check (SCW.Vehicle_Count = 2, "hand CW 2 veh");
   Check (Is_Feasible (P, SCW), "hand CW Is_Feasible");
   Check (Sum_Route_Costs (SCW) = SCW.Total_Cost, "hand CW Total_Cost helper");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "hand NN feasible");
   Check (SNN.Total_Cost = 13, "hand NN 13");
   Check (Is_Feasible (P, SNN), "hand NN Is_Feasible");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "hand Exact feasible");
   Check (SEX.Total_Cost = 13, "hand Exact 13");
   Check (Serves_Each_Customer_Once (P, SEX), "hand unique");
   --  Route loads.
   declare
      Load_Sum : Demand_Value := 0;
   begin
      for V in 1 .. SCW.Vehicle_Count loop
         Load_Sum := Load_Sum + Route_Load (P, SCW.Routes (Vehicle_Id (V)));
         Check (Is_Capacity_Feasible (P, SCW.Routes (Vehicle_Id (V))),
                "hand route cap");
      end loop;
      Check (Load_Sum = 8, "hand total demand 2+3+3");
   end;

   ------------------------------------------------------------------
   Section ("7. Capacity forces N vehicles");
   ------------------------------------------------------------------
   Clear (P, 3);
   Set_Capacity (P, 5);
   Set_Distance (P, 0, 1, 1);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 0, 3, 1);
   Set_Distance (P, 1, 2, 1);
   Set_Distance (P, 1, 3, 1);
   Set_Distance (P, 2, 3, 1);
   Set_Demand (P, 1, 5);
   Set_Demand (P, 2, 5);
   Set_Demand (P, 3, 5);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "force-3 CW feasible");
   Check (SCW.Vehicle_Count = 3, "force-3 CW 3 veh");
   Check (SCW.Total_Cost = 6, "force-3 CW 6");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Vehicle_Count = 3, "force-3 NN 3 veh");
   Check (SNN.Total_Cost = 6, "force-3 NN 6");
   Solve_Exact (P, SEX);
   Check (SEX.Vehicle_Count = 3, "force-3 Exact 3 veh");
   Check (SEX.Total_Cost = 6, "force-3 Exact 6");
   Check (Is_Feasible (P, SCW) and then Is_Feasible (P, SNN), "force-3 ok");

   ------------------------------------------------------------------
   Section ("8. Infeasible fleet (total demand > fleet cap)");
   ------------------------------------------------------------------
   Clear (P, 3);
   Set_Capacity (P, 5);
   Set_Max_Vehicles (P, 2);
   Set_Distance (P, 0, 1, 1);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 0, 3, 1);
   Set_Distance (P, 1, 2, 1);
   Set_Distance (P, 1, 3, 1);
   Set_Distance (P, 2, 3, 1);
   Set_Demand (P, 1, 5);
   Set_Demand (P, 2, 5);
   Set_Demand (P, 3, 5);
   Check (Effective_Fleet (P) = 2, "fleet 2 effective");
   Solve_Clarke_Wright (P, SCW);
   Check (not SCW.Feasible, "fleet-2 CW infeasible");
   Check (not Is_Feasible (P, SCW), "fleet-2 CW Is_Feasible false");
   Solve_Nearest_Neighbor (P, SNN);
   Check (not SNN.Feasible, "fleet-2 NN infeasible");
   Solve_Exact (P, SEX);
   Check (not SEX.Feasible, "fleet-2 Exact infeasible");

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Max_Customers + 1), "Clear N too large");
   Check (not Clear_Raises (Max_Customers), "Clear N=max ok");
   Check (not Clear_Raises (0), "Clear N=0 ok");

   Clear (P, 2);
   Set_Capacity (P, 10);
   Check (Dist_Raises (P, 0, 1, Int (-1)), "negative distance");
   Check (Dist_Raises (P, 0, 3, 1), "vertex To > N");
   Check (Dist_Raises (P, 3, 0, 1), "vertex From > N");
   Check (not Dist_Raises (P, 0, 1, 0), "zero distance ok");
   Check (Demand_Raises (P, 1, Int (-3)), "negative demand");
   Check (Demand_Raises (P, 3, 1), "customer > N");
   Check (not Demand_Raises (P, 1, 0), "zero demand ok");
   Check (Cap_Raises (P, Int (-1)), "negative capacity");
   Check (not Cap_Raises (P, 0), "capacity 0 ok");
   Check (Fleet_Raises (P, Max_Vehicles + 1), "fleet too large");
   Check (not Fleet_Raises (P, 0), "fleet 0 ok");
   Check (not Fleet_Raises (P, Max_Vehicles), "fleet max ok");
   Check (Get_Dist_Raises (P, 0, 3), "Distance To > N");
   Check (Get_Dist_Raises (P, 4, 0), "Distance From > N");
   Check (Get_Dem_Raises (P, 3), "Demand_Of > N");
   Check (Sav_Raises (P, 1, 3), "Savings J > N");
   Check (Sav_Raises (P, 3, 1), "Savings I > N");

   Clear (P, 1);
   Set_Capacity (P, 3);
   Set_Distance (P, 0, 1, 1);
   Set_Demand (P, 1, 4);
   Check (CW_Raises (P), "demand > cap CW");
   Check (NN_Raises (P), "demand > cap NN");
   Check (Exact_Raises (P), "demand > cap Exact");

   Clear (P, 1);
   Set_Capacity (P, 0);
   Set_Distance (P, 0, 1, 1);
   Set_Demand (P, 1, 1);
   Check (CW_Raises (P), "cap 0 positive demand CW");

   --  Exact N too large.
   Fill_Symmetric (P, 9, 20, 1);
   Check (Exact_Raises (P), "Exact N=9 raises");
   Check (not CW_Raises (P), "CW N=9 ok");
   Check (not NN_Raises (P), "NN N=9 ok");

   --  Empty problem getters.
   Clear (P, 0);
   Check (Get_Dem_Raises (P, 1), "Demand_Of on N=0");
   Check (Sav_Raises (P, 1, 1), "Savings on N=0");
   Check (not Get_Dist_Raises (P, 0, 0), "Distance depot on N=0 ok");

   ------------------------------------------------------------------
   Section ("10. Helpers: Route_Cost, load, empty route");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 10);
   Set_Distance (P, 0, 1, 4);
   Set_Distance (P, 0, 2, 5);
   Set_Distance (P, 1, 2, 6);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 3);
   R.Length := 0;
   Check (Route_Cost (P, R) = 0, "empty Route_Cost 0");
   Check (Route_Load (P, R) = 0, "empty Route_Load 0");
   Check (Is_Capacity_Feasible (P, R), "empty route cap feasible");
   R.Length := 2;
   R.Stops (1) := 1;
   R.Stops (2) := 2;
   Check (Route_Cost (P, R) = 15, "0-1-2-0 = 4+6+5");
   Check (Route_Load (P, R) = 5, "load 2+3");
   R.Length := 1;
   R.Stops (1) := 2;
   Check (Route_Cost (P, R) = 10, "0-2-0 = 10");
   --  Avoid constant True: compare helper on a fresh solve.
   Solve_Clarke_Wright (P, SCW);
   Check (Total_Cost (SCW) = SCW.Total_Cost, "Total_Cost matches field");

   ------------------------------------------------------------------
   Section ("11. Zero-demand customers");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 1);
   Set_Distance (P, 0, 1, 3);
   Set_Distance (P, 0, 2, 4);
   Set_Distance (P, 1, 2, 1);
   Set_Demand (P, 1, 0);
   Set_Demand (P, 2, 1);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "zero-dem CW feasible");
   Check (Is_Feasible (P, SCW), "zero-dem CW Is_Feasible");
   Check (Serves_Each_Customer_Once (P, SCW), "zero-dem unique");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "zero-dem NN feasible");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "zero-dem Exact feasible");
   Check (SEX.Total_Cost <= SCW.Total_Cost, "zero-dem exact ≤ CW");

   ------------------------------------------------------------------
   Section ("12. Zero capacity, zero demands");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 0);
   Set_Distance (P, 0, 1, 2);
   Set_Distance (P, 0, 2, 3);
   Set_Distance (P, 1, 2, 4);
   Set_Demand (P, 1, 0);
   Set_Demand (P, 2, 0);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "cap0 CW feasible");
   Check (Is_Feasible (P, SCW), "cap0 Is_Feasible");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "cap0 NN feasible");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "cap0 Exact feasible");

   ------------------------------------------------------------------
   Section ("13. Max_Vehicles = 1, all fit / do not fit");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 10);
   Set_Max_Vehicles (P, 1);
   Set_Distance (P, 0, 1, 5);
   Set_Distance (P, 0, 2, 6);
   Set_Distance (P, 1, 2, 1);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 2);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "K=1 fit CW");
   Check (SCW.Vehicle_Count = 1, "K=1 fit CW 1 veh");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "K=1 fit NN");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible and then SEX.Vehicle_Count = 1, "K=1 Exact 1");

   Set_Capacity (P, 2);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 2);
   Solve_Clarke_Wright (P, SCW);
   Check (not SCW.Feasible, "K=1 no-fit CW");
   Solve_Nearest_Neighbor (P, SNN);
   Check (not SNN.Feasible, "K=1 no-fit NN");
   Solve_Exact (P, SEX);
   Check (not SEX.Feasible, "K=1 no-fit Exact");

   ------------------------------------------------------------------
   Section ("14. NN greedy seed / append");
   ------------------------------------------------------------------
   Clear (P, 3);
   Set_Capacity (P, 10);
   --  Closest to depot is customer 2.
   Set_Distance (P, 0, 1, 9);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 0, 3, 8);
   Set_Distance (P, 1, 2, 7);
   Set_Distance (P, 1, 3, 2);
   Set_Distance (P, 2, 3, 3);
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Set_Demand (P, 3, 1);
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "NN greedy feasible");
   Check (SNN.Vehicle_Count = 1, "NN greedy one tour");
   Check (SNN.Routes (1).Length = 3, "NN greedy 3 stops");
   Check (SNN.Routes (1).Stops (1) = 2, "NN seeds closest=2");
   --  From 2, closest is 3 (dist 3) vs 1 (dist 7).
   Check (SNN.Routes (1).Stops (2) = 3, "NN second=3");
   Check (SNN.Routes (1).Stops (3) = 1, "NN third=1");
   --  Cost 0-2-3-1-0 = 1+3+2+9 = 15.
   Check (SNN.Total_Cost = 15, "NN greedy cost 15");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "NN-inst Exact feasible");
   Check (SEX.Total_Cost <= 15, "Exact ≤ greedy 15");

   ------------------------------------------------------------------
   Section ("15. Euclidean helper and metric instance");
   ------------------------------------------------------------------
   Check (Rounded_Euclidean (0, 0, 3, 4) = 5, "3-4-5 triangle");
   Check (Rounded_Euclidean (0, 0, 0, 0) = 0, "euclid 0");
   Check (Rounded_Euclidean (0, 0, 1, 0) = 1, "unit x");
   Check (Rounded_Euclidean (0, 0, 0, 2) = 2, "unit y*2");
   Check (Rounded_Euclidean (1, 1, 4, 5) = 5, "shifted 3-4-5");
   --  Square: depot (0,0), customers (2,0), (2,2), (0,2). Cap 2, dem 1.
   Clear (P, 3);
   Set_Capacity (P, 2);
   Set_Distance (P, 0, 1, Integer (Rounded_Euclidean (0, 0, 2, 0)));
   Set_Distance (P, 0, 2, Integer (Rounded_Euclidean (0, 0, 2, 2)));
   Set_Distance (P, 0, 3, Integer (Rounded_Euclidean (0, 0, 0, 2)));
   Set_Distance (P, 1, 2, Integer (Rounded_Euclidean (2, 0, 2, 2)));
   Set_Distance (P, 1, 3, Integer (Rounded_Euclidean (2, 0, 0, 2)));
   Set_Distance (P, 2, 3, Integer (Rounded_Euclidean (2, 2, 0, 2)));
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Set_Demand (P, 3, 1);
   Check (Distance (P, 0, 1) = 2, "square 0-1 = 2");
   Check (Distance (P, 0, 2) = 3, "square 0-2 ≈ 2.828 → 3");
   Check (Distance (P, 0, 3) = 2, "square 0-3 = 2");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "square CW feasible");
   Check (Is_Feasible (P, SCW), "square CW Is_Feasible");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "square NN feasible");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "square Exact feasible");
   Check (SEX.Total_Cost <= SCW.Total_Cost, "square exact ≤ CW");
   Check (SEX.Total_Cost <= SNN.Total_Cost, "square exact ≤ NN");

   ------------------------------------------------------------------
   Section ("16. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (P, 1);
   Set_Capacity (P, 9);
   Set_Distance (P, 0, 1, 2);
   Set_Demand (P, 1, 1);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Total_Cost = 4, "rebuild before");
   Clear (P, 2);
   Check (Customer_Count (P) = 2, "rebuild N=2");
   Check (Distance (P, 0, 1) = 0, "rebuild costs cleared");
   Check (Demand_Of (P, 1) = 0, "rebuild demands cleared");
   Check (Capacity_Of (P) = 0, "rebuild cap cleared");
   Set_Capacity (P, 5);
   Set_Distance (P, 0, 1, 1);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 1, 2, 1);
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "rebuild NN feasible");
   Check (SNN.N = 2, "rebuild solution N");

   ------------------------------------------------------------------
   Section ("17. Exact oracle vs heuristics on tiny N");
   ------------------------------------------------------------------
   for Seed in Natural range 1 .. 8 loop
      Fill_Symmetric (P, 4, 8, Seed);
      Solve_Clarke_Wright (P, SCW);
      Solve_Nearest_Neighbor (P, SNN);
      Solve_Exact (P, SEX);
      Check (SEX.Feasible, "oracle seed feasible");
      Check (Is_Feasible (P, SEX), "oracle seed Is_Feasible");
      if SCW.Feasible then
         Check (SEX.Total_Cost <= SCW.Total_Cost, "oracle ≤ CW seed");
         Check (Is_Feasible (P, SCW), "CW seed Is_Feasible");
      else
         Check (not Is_Feasible (P, SCW), "CW seed infeas match");
      end if;
      if SNN.Feasible then
         Check (SEX.Total_Cost <= SNN.Total_Cost, "oracle ≤ NN seed");
         Check (Is_Feasible (P, SNN), "NN seed Is_Feasible");
      else
         Check (not Is_Feasible (P, SNN), "NN seed infeas match");
      end if;
      Check (Serves_Each_Customer_Once (P, SEX), "oracle unique seed");
   end loop;

   ------------------------------------------------------------------
   Section ("18. Generated N=5 CW/NN structural");
   ------------------------------------------------------------------
   for Seed in Natural range 1 .. 12 loop
      Fill_Symmetric (P, 5, 10, Seed * 3);
      Solve_Clarke_Wright (P, SCW);
      Solve_Nearest_Neighbor (P, SNN);
      Check (SCW.N = 5, "gen5 CW N");
      Check (SNN.N = 5, "gen5 NN N");
      Check (All_Stops_In_Range (P, SCW), "gen5 CW stops");
      Check (All_Stops_In_Range (P, SNN), "gen5 NN stops");
      if SCW.Feasible then
         Check (Is_Feasible (P, SCW), "gen5 CW feasible check");
         Check (Total_Cost (SCW) = SCW.Total_Cost, "gen5 CW total");
         Check (Serves_Each_Customer_Once (P, SCW), "gen5 CW unique");
      else
         Check (SCW.Vehicle_Count <= Effective_Fleet (P)
                  or else not SCW.Feasible,
                "gen5 CW infeas or fleet");
      end if;
      if SNN.Feasible then
         Check (Is_Feasible (P, SNN), "gen5 NN feasible check");
         Check (Serves_Each_Customer_Once (P, SNN), "gen5 NN unique");
      else
         Check (not SNN.Feasible, "gen5 NN infeas flag");
      end if;
   end loop;

   ------------------------------------------------------------------
   Section ("19. N=4 split vs combined");
   ------------------------------------------------------------------
   Clear (P, 4);
   Set_Capacity (P, 3);
   for I in 0 .. 4 loop
      for J in I + 1 .. 4 loop
         Set_Distance (P, Vertex_Id (I), Vertex_Id (J), abs (I - J));
      end loop;
   end loop;
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Set_Demand (P, 3, 1);
   Set_Demand (P, 4, 1);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "N4 CW feasible");
   Check (Is_Feasible (P, SCW), "N4 CW Is_Feasible");
   Check (SCW.Vehicle_Count >= 2, "N4 at least 2 (cap 3, dem 4)");
   Check (SCW.Vehicle_Count <= 4, "N4 at most 4");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "N4 NN feasible");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "N4 Exact feasible");
   Check (SEX.Total_Cost <= SCW.Total_Cost, "N4 exact ≤ CW");
   Check (SEX.Total_Cost <= SNN.Total_Cost, "N4 exact ≤ NN");
   Check (Serves_Each_Customer_Once (P, SCW), "N4 unique CW");
   Check (Serves_Each_Customer_Once (P, SNN), "N4 unique NN");
   Check (Serves_Each_Customer_Once (P, SEX), "N4 unique Exact");

   ------------------------------------------------------------------
   Section ("20. Self distance / symmetry writes");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 9);
   Set_Distance (P, 1, 0, 8);
   Check (Distance (P, 0, 1) = 8, "write (1,0) sets (0,1)");
   Set_Distance (P, 1, 1, 0);
   Check (Distance (P, 1, 1) = 0, "diagonal 0");
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Set_Distance (P, 0, 2, 3);
   Set_Distance (P, 1, 2, 4);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "sym CW feasible");
   Check (Distance (P, 2, 1) = 4, "sym 2-1");

   ------------------------------------------------------------------
   Section ("21. Getters after setters");
   ------------------------------------------------------------------
   Clear (P, 3);
   Set_Capacity (P, 12);
   Set_Max_Vehicles (P, 4);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 3);
   Set_Demand (P, 3, 4);
   Set_Distance (P, 0, 1, 1);
   Set_Distance (P, 0, 2, 2);
   Set_Distance (P, 0, 3, 3);
   Set_Distance (P, 1, 2, 4);
   Set_Distance (P, 1, 3, 5);
   Set_Distance (P, 2, 3, 6);
   Check (Customer_Count (P) = 3, "get N");
   Check (Capacity_Of (P) = 12, "get cap");
   Check (Max_Vehicles_Of (P) = 4, "get fleet stored");
   Check (Effective_Fleet (P) = 3, "effective min(N,4)=3");
   Check (Demand_Of (P, 2) = 3, "get d2");
   Check (Distance (P, 2, 3) = 6, "get c23");
   Check (Savings (P, 1, 2) = Savings_Value (1 + 2 - 4), "get s12=-1");
   --  Negative savings: CW will not merge 1 and 2.
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "neg-savings still feasible");
   Check (Is_Feasible (P, SCW), "neg-savings Is_Feasible");

   ------------------------------------------------------------------
   Section ("22. Larger N=12 CW/NN");
   ------------------------------------------------------------------
   Fill_Symmetric (P, 12, 8, 17);
   Check (Customer_Count (P) = 12, "N=12");
   Solve_Clarke_Wright (P, SCW);
   Solve_Nearest_Neighbor (P, SNN);
   Check (All_Stops_In_Range (P, SCW), "N12 CW stops");
   Check (All_Stops_In_Range (P, SNN), "N12 NN stops");
   if SCW.Feasible then
      Check (Is_Feasible (P, SCW), "N12 CW feasible");
      Check (SCW.Vehicle_Count >= 1, "N12 CW ≥1");
   else
      Check (not SCW.Feasible, "N12 CW infeas");
   end if;
   if SNN.Feasible then
      Check (Is_Feasible (P, SNN), "N12 NN feasible");
   else
      Check (not SNN.Feasible, "N12 NN infeas");
   end if;
   Check (SCW.N = 12 and then SNN.N = 12, "N12 solution N");

   ------------------------------------------------------------------
   Section ("23. Exact N=2 reverse vs forward tour");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 10);
   Set_Distance (P, 0, 1, 10);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 1, 2, 2);
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "rev Exact feasible");
   --  Optimal 0-2-1-0 = 1+2+10 = 13 (not 0-1-2-0 = 10+2+1 = 13 same).
   Check (SEX.Total_Cost = 13, "rev Exact 13");
   Check (SEX.Vehicle_Count = 1, "rev one vehicle");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Total_Cost = 13, "rev CW 13");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Routes (1).Stops (1) = 2, "rev NN seeds 2");
   Check (SNN.Total_Cost = 13, "rev NN 13");

   ------------------------------------------------------------------
   Section ("24. One customer demand = capacity");
   ------------------------------------------------------------------
   Clear (P, 1);
   Set_Capacity (P, 9);
   Set_Distance (P, 0, 1, 11);
   Set_Demand (P, 1, 9);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "dem=cap CW");
   Check (SCW.Routes (1).Load = 9, "dem=cap load");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "dem=cap NN");
   Solve_Exact (P, SEX);
   Check (SEX.Total_Cost = 22, "dem=cap cost 22");

   ------------------------------------------------------------------
   Section ("25. Is_Feasible rejects duplicates / missing");
   ------------------------------------------------------------------
   Fill_Hand3 (P);
   Solve_Clarke_Wright (P, SCW);
   Check (Is_Feasible (P, SCW), "base feasible");
   --  Duplicate a stop.
   SCW.Routes (1).Length := SCW.Routes (1).Length + 1;
   SCW.Routes (1).Stops (SCW.Routes (1).Length) := 1;
   Check (not Serves_Each_Customer_Once (P, SCW), "dup not unique");
   Check (not Is_Feasible (P, SCW), "dup not feasible");
   --  Wrong N.
   Solve_Clarke_Wright (P, SCW);
   SCW.N := 0;
   Check (not Is_Feasible (P, SCW), "wrong N not feasible");

   ------------------------------------------------------------------
   Section ("26. Fleet default vs explicit");
   ------------------------------------------------------------------
   Clear (P, 2);
   Set_Capacity (P, 1);
   Set_Distance (P, 0, 1, 1);
   Set_Distance (P, 0, 2, 1);
   Set_Distance (P, 1, 2, 1);
   Set_Demand (P, 1, 1);
   Set_Demand (P, 2, 1);
   Check (Effective_Fleet (P) = 2, "default fleet min(N,32)=2");
   Set_Max_Vehicles (P, 2);
   Check (Effective_Fleet (P) = 2, "explicit 2");
   Set_Max_Vehicles (P, 1);
   Check (Effective_Fleet (P) = 1, "explicit 1");
   Solve_Clarke_Wright (P, SCW);
   Check (not SCW.Feasible, "explicit 1 cannot split");
   Set_Max_Vehicles (P, 0);
   Check (Effective_Fleet (P) = 2, "reset default");
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "default split feasible");

   ------------------------------------------------------------------
   Section ("27. CW agrees with Exact on several N=3");
   ------------------------------------------------------------------
   for Seed in Natural range 1 .. 6 loop
      Fill_Symmetric (P, 3, 6, Seed + 20);
      Solve_Clarke_Wright (P, SCW);
      Solve_Exact (P, SEX);
      Check (SEX.Feasible, "n3 exact feas");
      if SCW.Feasible then
         Check (Is_Feasible (P, SCW), "n3 CW feas");
      end if;
      Check (SEX.Total_Cost <= (if SCW.Feasible then SCW.Total_Cost
                                else Infinity),
             "n3 exact ≤ CW-or-inf");
   end loop;

   ------------------------------------------------------------------
   Section ("28. NN vs Exact N=3 costs");
   ------------------------------------------------------------------
   for Seed in Natural range 1 .. 6 loop
      Fill_Symmetric (P, 3, 6, Seed + 40);
      Solve_Nearest_Neighbor (P, SNN);
      Solve_Exact (P, SEX);
      Check (SEX.Feasible, "n3nn exact feas");
      if SNN.Feasible then
         Check (SEX.Total_Cost <= SNN.Total_Cost, "n3 exact ≤ NN");
         Check (Is_Feasible (P, SNN), "n3 NN feas");
      else
         Check (not SNN.Feasible, "n3 NN infeas");
      end if;
   end loop;

   ------------------------------------------------------------------
   Section ("29. Identical customers (same dist, same demand)");
   ------------------------------------------------------------------
   Clear (P, 3);
   Set_Capacity (P, 4);
   Set_Distance (P, 0, 1, 5);
   Set_Distance (P, 0, 2, 5);
   Set_Distance (P, 0, 3, 5);
   Set_Distance (P, 1, 2, 5);
   Set_Distance (P, 1, 3, 5);
   Set_Distance (P, 2, 3, 5);
   Set_Demand (P, 1, 2);
   Set_Demand (P, 2, 2);
   Set_Demand (P, 3, 2);
   Solve_Clarke_Wright (P, SCW);
   Check (SCW.Feasible, "ident CW");
   Check (SCW.Vehicle_Count = 2, "ident 2 vehicles (4+2)");
   Solve_Nearest_Neighbor (P, SNN);
   Check (SNN.Feasible, "ident NN");
   Check (SNN.Routes (1).Stops (1) = 1, "ident NN tie → smallest id");
   Solve_Exact (P, SEX);
   Check (SEX.Feasible, "ident Exact");
   Check (SEX.Total_Cost <= SCW.Total_Cost, "ident exact ≤ CW");

   ------------------------------------------------------------------
   Section ("30. Route_Cost independent of stored Cost field");
   ------------------------------------------------------------------
   Fill_Hand3 (P);
   Solve_Clarke_Wright (P, SCW);
   for V in 1 .. SCW.Vehicle_Count loop
      declare
         RR : Route := SCW.Routes (Vehicle_Id (V));
         C1 : constant Cost_Value := Route_Cost (P, RR);
      begin
         RR.Cost := 0;
         Check (Route_Cost (P, RR) = C1, "Route_Cost ignores stored");
         Check (C1 = SCW.Routes (Vehicle_Id (V)).Cost, "matches filled");
      end;
   end loop;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
