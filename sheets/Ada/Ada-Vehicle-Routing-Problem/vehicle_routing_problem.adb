--  Vehicle_Routing_Problem body — CVRP Clarke–Wright, nearest neighbour,
--  and a small-N exact subset DP.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
with Interfaces;

package body Vehicle_Routing_Problem
  with SPARK_Mode => Off
is

   use Interfaces;

   -------------------------------------------------------------------------
   -- Shared arithmetic / validation
   -------------------------------------------------------------------------

   procedure Validate_Vertex (P : Problem; V : Vertex_Id) is
   begin
      if Natural (V) > P.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Customer (P : Problem; C : Customer_Id) is
   begin
      if P.N = 0 or else Natural (C) > P.N then
         raise Invalid_Argument;
      end if;
   end Validate_Customer;

   procedure Validate_Demands (P : Problem) is
   begin
      for K in 1 .. P.N loop
         if P.Demand (Customer_Id (K)) > Demand_Value (P.Capacity) then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Demands;

   function Add_Cost (A, B : Cost_Value) return Cost_Value is
   begin
      if A >= Infinity or else B >= Infinity then
         return Infinity;
      elsif B > Cost_Value'Last - A then
         return Infinity;
      else
         return A + B;
      end if;
   end Add_Cost;

   function Fleet_Limit (P : Problem) return Natural is
      Cap : Natural;
   begin
      if P.N = 0 then
         return 0;
      end if;
      if P.Fleet = 0 then
         Cap := Max_Vehicles;
      else
         Cap := P.Fleet;
      end if;
      if Cap > P.N then
         return P.N;
      else
         return Cap;
      end if;
   end Fleet_Limit;

   procedure Empty_Solution (P : Problem; Result : out Solution) is
   begin
      Result.N := P.N;
      Result.Vehicle_Count := 0;
      Result.Total_Cost := 0;
      Result.Feasible := P.N = 0;
      Result.Routes := [others => <>];
   end Empty_Solution;

   procedure Fill_Route_Metrics (P : Problem; R : in out Route) is
      Acc_Cost : Cost_Value := 0;
      Acc_Load : Demand_Value := 0;
      Prev     : Vertex_Id := 0;
   begin
      if R.Length = 0 then
         R.Cost := 0;
         R.Load := 0;
         return;
      end if;
      for K in 1 .. R.Length loop
         declare
            C : constant Customer_Id := R.Stops (K);
         begin
            Validate_Customer (P, C);
            Acc_Cost := Add_Cost (Acc_Cost, P.Cost (Prev, Vertex_Id (C)));
            Acc_Load := Acc_Load + P.Demand (C);
            Prev := Vertex_Id (C);
         end;
      end loop;
      Acc_Cost := Add_Cost (Acc_Cost, P.Cost (Prev, 0));
      R.Cost := Acc_Cost;
      R.Load := Acc_Load;
   end Fill_Route_Metrics;

   procedure Finalise_Solution (P : Problem; Result : in out Solution) is
      Used : Natural := 0;
      Acc  : Cost_Value := 0;
      Seen : array (Customer_Id) of Boolean := [others => False];
      Dup  : Boolean := False;
      Miss : Boolean := False;
      Over : Boolean := False;
   begin
      Result.N := P.N;
      for V in Vehicle_Id loop
         if Result.Routes (V).Length > 0 then
            Used := Used + 1;
            Fill_Route_Metrics (P, Result.Routes (V));
            Acc := Add_Cost (Acc, Result.Routes (V).Cost);
            if Result.Routes (V).Load > Demand_Value (P.Capacity) then
               Over := True;
            end if;
            for K in 1 .. Result.Routes (V).Length loop
               declare
                  C : constant Customer_Id := Result.Routes (V).Stops (K);
               begin
                  if Natural (C) > P.N then
                     Dup := True;
                  elsif Seen (C) then
                     Dup := True;
                  else
                     Seen (C) := True;
                  end if;
               end;
            end loop;
         end if;
      end loop;
      Result.Vehicle_Count := Used;
      Result.Total_Cost := Acc;
      for K in 1 .. P.N loop
         if not Seen (Customer_Id (K)) then
            Miss := True;
         end if;
      end loop;
      Result.Feasible :=
        (not Dup)
        and then (not Miss)
        and then (not Over)
        and then Used <= Fleet_Limit (P)
        and then (P.N = 0 or else Used > 0);
      if P.N = 0 then
         Result.Feasible := True;
         Result.Vehicle_Count := 0;
         Result.Total_Cost := 0;
      end if;
   end Finalise_Solution;

   -------------------------------------------------------------------------
   -- Construction
   -------------------------------------------------------------------------

   procedure Clear (P : in out Problem; Customer_Count : Natural) is
   begin
      if Customer_Count > Max_Customers then
         raise Invalid_Argument;
      end if;
      P.N := Customer_Count;
      P.Capacity := 0;
      P.Fleet := 0;
      P.Cost := [others => [others => 0]];
      P.Demand := [others => 0];
   end Clear;

   procedure Set_Distance
     (P : in out Problem; From, To : Vertex_Id; Cost : Integer)
   is
   begin
      if Cost < 0 then
         raise Invalid_Argument;
      end if;
      Validate_Vertex (P, From);
      Validate_Vertex (P, To);
      P.Cost (From, To) := Cost_Value (Cost);
      P.Cost (To, From) := Cost_Value (Cost);
   end Set_Distance;

   procedure Set_Demand
     (P : in out Problem; Customer : Customer_Id; Demand : Integer)
   is
   begin
      if Demand < 0 then
         raise Invalid_Argument;
      end if;
      Validate_Customer (P, Customer);
      P.Demand (Customer) := Demand_Value (Demand);
   end Set_Demand;

   procedure Set_Capacity (P : in out Problem; Capacity : Integer) is
   begin
      if Capacity < 0 then
         raise Invalid_Argument;
      end if;
      P.Capacity := Capacity_Value (Capacity);
   end Set_Capacity;

   procedure Set_Max_Vehicles (P : in out Problem; Count : Natural) is
   begin
      if Count > Max_Vehicles then
         raise Invalid_Argument;
      end if;
      P.Fleet := Count;
   end Set_Max_Vehicles;

   function Customer_Count (P : Problem) return Natural is
   begin
      return P.N;
   end Customer_Count;

   function Capacity_Of (P : Problem) return Capacity_Value is
   begin
      return P.Capacity;
   end Capacity_Of;

   function Max_Vehicles_Of (P : Problem) return Natural is
   begin
      return P.Fleet;
   end Max_Vehicles_Of;

   function Effective_Fleet (P : Problem) return Natural is
   begin
      return Fleet_Limit (P);
   end Effective_Fleet;

   function Distance
     (P : Problem; From, To : Vertex_Id) return Cost_Value
   is
   begin
      Validate_Vertex (P, From);
      Validate_Vertex (P, To);
      return P.Cost (From, To);
   end Distance;

   function Demand_Of
     (P : Problem; Customer : Customer_Id) return Demand_Value
   is
   begin
      Validate_Customer (P, Customer);
      return P.Demand (Customer);
   end Demand_Of;

   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Natural
   is
      use Ada.Numerics.Elementary_Functions;
      DX : constant Float := Float (X2 - X1);
      DY : constant Float := Float (Y2 - Y1);
      R  : constant Float := Sqrt (DX * DX + DY * DY);
   begin
      if R >= Float (Natural'Last) then
         raise Invalid_Argument;
      end if;
      return Natural (Float'Rounding (R));
   end Rounded_Euclidean;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Savings
     (P : Problem; I, J : Customer_Id) return Savings_Value
   is
      CI0, C0J, CIJ : Cost_Value;
   begin
      Validate_Customer (P, I);
      Validate_Customer (P, J);
      CI0 := P.Cost (Vertex_Id (I), 0);
      C0J := P.Cost (0, Vertex_Id (J));
      CIJ := P.Cost (Vertex_Id (I), Vertex_Id (J));
      return Savings_Value (CI0) + Savings_Value (C0J) - Savings_Value (CIJ);
   end Savings;

   function Route_Cost (P : Problem; R : Route) return Cost_Value is
      Tmp : Route := R;
   begin
      Fill_Route_Metrics (P, Tmp);
      return Tmp.Cost;
   end Route_Cost;

   function Route_Load (P : Problem; R : Route) return Demand_Value is
      Tmp : Route := R;
   begin
      Fill_Route_Metrics (P, Tmp);
      return Tmp.Load;
   end Route_Load;

   function Total_Cost (S : Solution) return Cost_Value is
      Acc : Cost_Value := 0;
      Last : Natural;
   begin
      Last := S.Vehicle_Count;
      if Last > Max_Vehicles then
         Last := Max_Vehicles;
      end if;
      for V in 1 .. Last loop
         Acc := Add_Cost (Acc, S.Routes (Vehicle_Id (V)).Cost);
      end loop;
      return Acc;
   end Total_Cost;

   function Is_Capacity_Feasible
     (P : Problem; R : Route) return Boolean
   is
   begin
      return Route_Load (P, R) <= Demand_Value (P.Capacity);
   end Is_Capacity_Feasible;

   function Serves_Each_Customer_Once
     (P : Problem; S : Solution) return Boolean
   is
      Seen  : array (Customer_Id) of Natural := [others => 0];
      Last  : Natural;
      Count : Natural;
   begin
      Last := S.Vehicle_Count;
      if Last > Max_Vehicles then
         return False;
      end if;
      for V in 1 .. Last loop
         declare
            R : Route renames S.Routes (Vehicle_Id (V));
         begin
            for K in 1 .. R.Length loop
               declare
                  C : constant Customer_Id := R.Stops (K);
               begin
                  if P.N = 0 or else Natural (C) > P.N then
                     return False;
                  end if;
                  Seen (C) := Seen (C) + 1;
               end;
            end loop;
         end;
      end loop;
      for K in 1 .. P.N loop
         Count := Seen (Customer_Id (K));
         if Count /= 1 then
            return False;
         end if;
      end loop;
      return True;
   end Serves_Each_Customer_Once;

   function Is_Feasible (P : Problem; S : Solution) return Boolean is
      Last : Natural;
      Used : Natural := 0;
   begin
      if S.N /= P.N then
         return False;
      end if;
      if P.N = 0 then
         return S.Vehicle_Count = 0;
      end if;
      Last := S.Vehicle_Count;
      if Last > Max_Vehicles then
         return False;
      end if;
      for V in 1 .. Last loop
         declare
            R : Route renames S.Routes (Vehicle_Id (V));
         begin
            if R.Length > 0 then
               Used := Used + 1;
               if not Is_Capacity_Feasible (P, R) then
                  return False;
               end if;
            end if;
         end;
      end loop;
      if Used /= Last then
         return False;
      end if;
      if Last > Fleet_Limit (P) then
         return False;
      end if;
      return Serves_Each_Customer_Once (P, S);
   end Is_Feasible;

   -------------------------------------------------------------------------
   -- Clarke–Wright (parallel savings)
   -------------------------------------------------------------------------

   procedure Solve_Clarke_Wright (P : Problem; Result : out Solution) is
      Max_Pairs : constant Natural :=
        Max_Customers * (Max_Customers - 1) / 2;

      type Pair_Rec is record
         I, J : Customer_Id := 1;
         S    : Savings_Value := 0;
      end record;
      type Pair_Arr is array (1 .. Max_Pairs) of Pair_Rec;

      type CW_Route is record
         Used   : Boolean := False;
         Length : Natural := 0;
         Stops  : Customer_Seq := [others => Customer_Id'First];
         Load   : Demand_Value := 0;
      end record;
      type CW_Arr is array (1 .. Max_Customers) of CW_Route;

      Routes   : CW_Arr;
      Route_Of : array (Customer_Id) of Natural := [others => 0];
      Pairs    : Pair_Arr;
      NP       : Natural := 0;
      Limit    : Natural;
   begin
      Empty_Solution (P, Result);
      Validate_Demands (P);
      if P.N = 0 then
         return;
      end if;

      --  One radial route per customer: 0–i–0.
      for K in 1 .. P.N loop
         declare
            C : constant Customer_Id := Customer_Id (K);
         begin
            Routes (K).Used := True;
            Routes (K).Length := 1;
            Routes (K).Stops (1) := C;
            Routes (K).Load := P.Demand (C);
            Route_Of (C) := K;
         end;
      end loop;

      for A in 1 .. P.N loop
         for B in A + 1 .. P.N loop
            declare
               I : constant Customer_Id := Customer_Id (A);
               J : constant Customer_Id := Customer_Id (B);
               Sav : constant Savings_Value := Savings (P, I, J);
            begin
               if Sav > 0 then
                  NP := NP + 1;
                  Pairs (NP).I := I;
                  Pairs (NP).J := J;
                  Pairs (NP).S := Sav;
               end if;
            end;
         end loop;
      end loop;

      --  Insertion sort, decreasing savings; tie: smaller I, then J.
      for K in 2 .. NP loop
         declare
            Key : constant Pair_Rec := Pairs (K);
            J   : Integer := K - 1;
         begin
            while J >= 1 loop
               declare
                  Cur : Pair_Rec renames Pairs (J);
                  Better : Boolean;
               begin
                  Better :=
                    Cur.S < Key.S
                    or else (Cur.S = Key.S
                             and then (Cur.I > Key.I
                                       or else (Cur.I = Key.I
                                                and then Cur.J > Key.J)));
                  exit when not Better;
                  Pairs (J + 1) := Cur;
                  J := J - 1;
               end;
            end loop;
            Pairs (J + 1) := Key;
         end;
      end loop;

      for T in 1 .. NP loop
         declare
            I  : constant Customer_Id := Pairs (T).I;
            J  : constant Customer_Id := Pairs (T).J;
            RI : constant Natural := Route_Of (I);
            RJ : constant Natural := Route_Of (J);
            LI : Natural;
            LJ : Natural;
         begin
            if RI /= 0 and then RJ /= 0 and then RI /= RJ
              and then Routes (RI).Used and then Routes (RJ).Used
            then
               LI := Routes (RI).Length;
               LJ := Routes (RJ).Length;
               if LI > 0 and then LJ > 0 then
                  declare
                     I_End : constant Boolean :=
                       Routes (RI).Stops (1) = I
                       or else Routes (RI).Stops (LI) = I;
                     J_End : constant Boolean :=
                       Routes (RJ).Stops (1) = J
                       or else Routes (RJ).Stops (LJ) = J;
                     Combined : Demand_Value;
                  begin
                     Combined := Routes (RI).Load + Routes (RJ).Load;
                     if I_End and then J_End
                       and then Combined <= Demand_Value (P.Capacity)
                     then
                        --  Reverse so I is at the end of RI, J at start of RJ.
                        if Routes (RI).Stops (1) = I
                          and then (LI = 1
                                    or else Routes (RI).Stops (LI) /= I)
                        then
                           declare
                              Tmp : Customer_Id;
                           begin
                              for K in 1 .. LI / 2 loop
                                 Tmp := Routes (RI).Stops (K);
                                 Routes (RI).Stops (K) :=
                                   Routes (RI).Stops (LI - K + 1);
                                 Routes (RI).Stops (LI - K + 1) := Tmp;
                              end loop;
                           end;
                        end if;
                        if Routes (RJ).Stops (LJ) = J
                          and then (LJ = 1
                                    or else Routes (RJ).Stops (1) /= J)
                        then
                           declare
                              Tmp : Customer_Id;
                           begin
                              for K in 1 .. LJ / 2 loop
                                 Tmp := Routes (RJ).Stops (K);
                                 Routes (RJ).Stops (K) :=
                                   Routes (RJ).Stops (LJ - K + 1);
                                 Routes (RJ).Stops (LJ - K + 1) := Tmp;
                              end loop;
                           end;
                        end if;
                        if Routes (RI).Stops (Routes (RI).Length) = I
                          and then Routes (RJ).Stops (1) = J
                        then
                           for K in 1 .. Routes (RJ).Length loop
                              Routes (RI).Length := Routes (RI).Length + 1;
                              Routes (RI).Stops (Routes (RI).Length) :=
                                Routes (RJ).Stops (K);
                              Route_Of (Routes (RJ).Stops (K)) := RI;
                           end loop;
                           Routes (RI).Load := Combined;
                           Routes (RJ).Used := False;
                           Routes (RJ).Length := 0;
                           Routes (RJ).Load := 0;
                        end if;
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;

      --  Pack used CW routes into the solution (first Max_Vehicles).
      Limit := Fleet_Limit (P);
      declare
         Slot : Natural := 0;
         Leftover : Boolean := False;
      begin
         for K in 1 .. P.N loop
            if Routes (K).Used and then Routes (K).Length > 0 then
               if Slot < Limit then
                  Slot := Slot + 1;
                  Result.Routes (Vehicle_Id (Slot)).Length :=
                    Routes (K).Length;
                  Result.Routes (Vehicle_Id (Slot)).Stops :=
                    Routes (K).Stops;
                  Result.Routes (Vehicle_Id (Slot)).Load :=
                    Routes (K).Load;
               else
                  Leftover := True;
               end if;
            end if;
         end loop;
         pragma Unreferenced (Leftover);
      end;

      Finalise_Solution (P, Result);
   end Solve_Clarke_Wright;

   -------------------------------------------------------------------------
   -- Nearest-neighbour multi-route construction
   -------------------------------------------------------------------------

   procedure Solve_Nearest_Neighbor (P : Problem; Result : out Solution) is
      Unserved : array (Customer_Id) of Boolean := [others => False];
      Left     : Natural := 0;
      Limit    : Natural;
      Slot     : Natural := 0;
   begin
      Empty_Solution (P, Result);
      Validate_Demands (P);
      if P.N = 0 then
         return;
      end if;

      for K in 1 .. P.N loop
         Unserved (Customer_Id (K)) := True;
         Left := Left + 1;
      end loop;

      Limit := Fleet_Limit (P);

      while Left > 0 and then Slot < Limit loop
         --  Seed: unserved customer closest to the depot (tie: smaller id).
         declare
            Best   : Customer_Id := 1;
            Found  : Boolean := False;
            Best_D : Cost_Value := Infinity;
            R      : Route;
            Remain : Demand_Value;
            Cur    : Vertex_Id;
         begin
            for K in 1 .. P.N loop
               declare
                  C : constant Customer_Id := Customer_Id (K);
                  D : Cost_Value;
               begin
                  if Unserved (C) then
                     D := P.Cost (0, Vertex_Id (C));
                     if (not Found) or else D < Best_D then
                        Best := C;
                        Best_D := D;
                        Found := True;
                     end if;
                  end if;
               end;
            end loop;
            if not Found then
               exit;
            end if;

            R.Length := 1;
            R.Stops (1) := Best;
            Remain := Demand_Value (P.Capacity) - P.Demand (Best);
            Unserved (Best) := False;
            Left := Left - 1;
            Cur := Vertex_Id (Best);

            loop
               declare
                  Pick     : Customer_Id := 1;
                  Have     : Boolean := False;
                  Best_Nxt : Cost_Value := Infinity;
               begin
                  for K in 1 .. P.N loop
                     declare
                        C : constant Customer_Id := Customer_Id (K);
                        D : Cost_Value;
                     begin
                        if Unserved (C)
                          and then P.Demand (C) <= Remain
                        then
                           D := P.Cost (Cur, Vertex_Id (C));
                           if (not Have) or else D < Best_Nxt then
                              Pick := C;
                              Best_Nxt := D;
                              Have := True;
                           end if;
                        end if;
                     end;
                  end loop;
                  exit when not Have;
                  R.Length := R.Length + 1;
                  R.Stops (R.Length) := Pick;
                  Remain := Remain - P.Demand (Pick);
                  Unserved (Pick) := False;
                  Left := Left - 1;
                  Cur := Vertex_Id (Pick);
               end;
            end loop;

            Slot := Slot + 1;
            Result.Routes (Vehicle_Id (Slot)) := R;
         end;
      end loop;

      Finalise_Solution (P, Result);
   end Solve_Nearest_Neighbor;

   -------------------------------------------------------------------------
   -- Exact subset DP (N ≤ 8)
   -------------------------------------------------------------------------

   function Bit_Of (C : Customer_Id) return Unsigned_16 is
   begin
      return Shift_Left (1, Natural (C) - 1);
   end Bit_Of;

   function Has_Customer (M : Unsigned_16; C : Customer_Id) return Boolean is
   begin
      return (M and Bit_Of (C)) /= 0;
   end Has_Customer;

   procedure Solve_Exact (P : Problem; Result : out Solution) is
      Max_Mask : constant Natural := 2 ** Max_Exact_Customers;

      type Path_Tab is array (0 .. Max_Mask - 1, Customer_Id) of Cost_Value;
      type Pred_Tab is array (0 .. Max_Mask - 1, Customer_Id) of Natural;
      type Tour_Tab is array (0 .. Max_Mask - 1) of Cost_Value;
      type Dem_Tab  is array (0 .. Max_Mask - 1) of Demand_Value;

      type DP_Rec is record
         Cost     : Cost_Value := Infinity;
         Vehicles : Natural := 0;
         Last     : Natural := 0;
      end record;
      type DP_Tab is array (0 .. Max_Mask - 1) of DP_Rec;

      N        : constant Natural := P.N;
      Full     : Unsigned_16;
      Path     : Path_Tab;
      Pred     : Pred_Tab;
      Tour     : Tour_Tab;
      Dem      : Dem_Tab;
      DP       : DP_Tab;
      Limit    : Natural;
      Full_N   : Natural;
   begin
      Empty_Solution (P, Result);
      Validate_Demands (P);
      if N > Max_Exact_Customers then
         raise Invalid_Argument;
      end if;
      if N = 0 then
         return;
      end if;

      Full := Shift_Left (1, N) - 1;
      Full_N := Natural (Full);
      Limit := Fleet_Limit (P);

      Path := [others => [others => Infinity]];
      Pred := [others => [others => 0]];
      Tour := [others => Infinity];
      Dem  := [others => 0];
      DP   := [others => <>];

      --  Subset demands.
      for M in 0 .. Full_N loop
         declare
            U : constant Unsigned_16 := Unsigned_16 (M);
            Acc : Demand_Value := 0;
         begin
            for K in 1 .. N loop
               if Has_Customer (U, Customer_Id (K)) then
                  Acc := Acc + P.Demand (Customer_Id (K));
               end if;
            end loop;
            Dem (M) := Acc;
         end;
      end loop;

      --  Held–Karp: Path(S, i) = min cost depot ↝ S ending at i.
      for K in 1 .. N loop
         declare
            C : constant Customer_Id := Customer_Id (K);
            B : constant Natural := Natural (Bit_Of (C));
         begin
            Path (B, C) := P.Cost (0, Vertex_Id (C));
            Pred (B, C) := 0;
         end;
      end loop;

      for M in 1 .. Full_N loop
         declare
            U : constant Unsigned_16 := Unsigned_16 (M);
         begin
            for K in 1 .. N loop
               declare
                  I : constant Customer_Id := Customer_Id (K);
               begin
                  if Has_Customer (U, I) then
                     declare
                        Rest : constant Unsigned_16 := U and not Bit_Of (I);
                     begin
                        if Rest /= 0 then
                           for Jk in 1 .. N loop
                              declare
                                 J : constant Customer_Id := Customer_Id (Jk);
                              begin
                                 if Has_Customer (Rest, J) then
                                    declare
                                       Alt : constant Cost_Value :=
                                         Add_Cost
                                           (Path (Natural (Rest), J),
                                            P.Cost (Vertex_Id (J),
                                                    Vertex_Id (I)));
                                    begin
                                       if Alt < Path (M, I) then
                                          Path (M, I) := Alt;
                                          Pred (M, I) := Natural (J);
                                       elsif Alt = Path (M, I)
                                         and then
                                           (Pred (M, I) = 0
                                            or else Natural (J) < Pred (M, I))
                                       then
                                          Pred (M, I) := Natural (J);
                                       end if;
                                    end;
                                 end if;
                              end;
                           end loop;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end;
      end loop;

      --  Tour cost of subset T: min_i Path(T,i) + c(i,0), if demand fits.
      Tour (0) := Infinity;
      for M in 1 .. Full_N loop
         if Dem (M) <= Demand_Value (P.Capacity) then
            declare
               Best : Cost_Value := Infinity;
               U    : constant Unsigned_16 := Unsigned_16 (M);
            begin
               for K in 1 .. N loop
                  declare
                     I : constant Customer_Id := Customer_Id (K);
                  begin
                     if Has_Customer (U, I) then
                        declare
                           Alt : constant Cost_Value :=
                             Add_Cost (Path (M, I),
                                       P.Cost (Vertex_Id (I), 0));
                        begin
                           if Alt < Best then
                              Best := Alt;
                           end if;
                        end;
                     end if;
                  end;
               end loop;
               Tour (M) := Best;
            end;
         else
            Tour (M) := Infinity;
         end if;
      end loop;

      --  Set-partition DP: serve mask S with ≤ Limit vehicles.
      DP (0).Cost := 0;
      DP (0).Vehicles := 0;
      DP (0).Last := 0;

      for S in 1 .. Full_N loop
         declare
            SU : constant Unsigned_16 := Unsigned_16 (S);
            T  : Unsigned_16 := SU;
         begin
            while T /= 0 loop
               declare
                  TN : constant Natural := Natural (T);
                  Prev : constant Natural :=
                    Natural (SU and not T);
               begin
                  if Tour (TN) < Infinity
                    and then DP (Prev).Cost < Infinity
                  then
                     declare
                        NV : constant Natural := DP (Prev).Vehicles + 1;
                        NC : constant Cost_Value :=
                          Add_Cost (DP (Prev).Cost, Tour (TN));
                     begin
                        if NV <= Limit and then NC < DP (S).Cost then
                           DP (S).Cost := NC;
                           DP (S).Vehicles := NV;
                           DP (S).Last := TN;
                        end if;
                     end;
                  end if;
               end;
               T := Unsigned_16 (Natural (T) - 1) and SU;
            end loop;
         end;
      end loop;

      if DP (Full_N).Cost >= Infinity then
         --  Infeasible: leave empty-ish result marked not feasible.
         Result.N := P.N;
         Result.Feasible := False;
         Result.Vehicle_Count := 0;
         Result.Total_Cost := Infinity;
         return;
      end if;

      --  Reconstruct routes by peeling Last masks; reverse into slots.
      declare
         Masks : array (1 .. Max_Vehicles) of Natural := [others => 0];
         Count : Natural := 0;
         Cur   : Natural := Full_N;
      begin
         while Cur /= 0 and then Count < Max_Vehicles loop
            declare
               T : constant Natural := DP (Cur).Last;
            begin
               if T = 0 then
                  exit;
               end if;
               Count := Count + 1;
               Masks (Count) := T;
               Cur := Natural (Unsigned_16 (Cur) and not Unsigned_16 (T));
            end;
         end loop;

         for Idx in 1 .. Count loop
            declare
               --  Peel order is last-route-first; reverse for stability.
               T : constant Natural := Masks (Count - Idx + 1);
               U : constant Unsigned_16 := Unsigned_16 (T);
               Best_I : Customer_Id := 1;
               Best_C : Cost_Value := Infinity;
               Have   : Boolean := False;
               R      : Route;
            begin
               for K in 1 .. N loop
                  declare
                     I : constant Customer_Id := Customer_Id (K);
                  begin
                     if Has_Customer (U, I) then
                        declare
                           Alt : constant Cost_Value :=
                             Add_Cost (Path (T, I),
                                       P.Cost (Vertex_Id (I), 0));
                        begin
                           if (not Have) or else Alt < Best_C
                             or else (Alt = Best_C and then I < Best_I)
                           then
                              Best_I := I;
                              Best_C := Alt;
                              Have := True;
                           end if;
                        end;
                     end if;
                  end;
               end loop;
               if Have then
                  declare
                     Tmp  : array (1 .. Max_Exact_Customers) of Customer_Id :=
                       [others => 1];
                     L    : Natural := 0;
                     Now  : Natural := T;
                     Curb : Customer_Id := Best_I;
                     Guard : Natural := 0;
                  begin
                     loop
                        L := L + 1;
                        Tmp (L) := Curb;
                        exit when Pred (Now, Curb) = 0;
                        declare
                           Pr : constant Natural := Pred (Now, Curb);
                        begin
                           Now := Natural
                             (Unsigned_16 (Now) and not Bit_Of (Curb));
                           Curb := Customer_Id (Pr);
                        end;
                        Guard := Guard + 1;
                        exit when Guard > Max_Exact_Customers;
                     end loop;
                     R.Length := L;
                     for K in 1 .. L loop
                        R.Stops (K) := Tmp (L - K + 1);
                     end loop;
                  end;
               end if;
               Result.Routes (Vehicle_Id (Idx)) := R;
            end;
         end loop;
      end;

      Finalise_Solution (P, Result);
      --  Prefer DP cost if reconstruction drifted (should match).
      if Result.Feasible then
         Result.Total_Cost := DP (Full_N).Cost;
      end if;
   end Solve_Exact;

end Vehicle_Routing_Problem;
