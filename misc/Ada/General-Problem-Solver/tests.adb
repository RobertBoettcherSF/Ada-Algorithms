--  Standalone test suite for General_Problem_Solver (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with General_Problem_Solver; use General_Problem_Solver;

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

begin
   Put_Line ("General_Problem_Solver test suite");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Bit / state helpers");
   ---------------------------------------------------------------------
   declare
      S : State;
   begin
      Check (Bit (1) = 1, "Bit(1) = 1");
      Check (Bit (2) = 2, "Bit(2) = 2");
      Check (Bit (3) = 4, "Bit(3) = 4");
      Check (Bit (32) = State (2**31), "Bit(32) high bit");
      Check (Has (Bit (5), 5), "Has singleton");
      Check (not Has (Bit (5), 4), "Has rejects other");
      Check (not Has (0, 1), "Has empty");
      S := Set_Bit (0, 7);
      Check (Has (S, 7), "Set_Bit sets");
      Check (not Has (Clear_Bit (S, 7), 7), "Clear_Bit clears");
      Check (Set_Bit (S, 7) = S, "Set_Bit idempotent");
      Check (Clear_Bit (0, 1) = 0, "Clear_Bit on empty");
      Check (Make_State ([1, 3, 5]) = (Bit (1) or Bit (3) or Bit (5)),
             "Make_State union");
      Check (Make_State (Condition_Index_Array'(1 .. 0 => <>)) = 0,
             "Make_State empty");
      Check (Count_Bits (0) = 0, "Count_Bits 0");
      Check (Count_Bits (Bit (1)) = 1, "Count_Bits 1");
      Check (Count_Bits (Make_State ([1, 2, 3, 4])) = 4, "Count_Bits 4");
      Check (Count_Bits (State'Last) = Max_Conditions, "Count_Bits all");
      Check (Is_Subset (0, 0), "Is_Subset empty/empty");
      Check (Is_Subset (0, Bit (1)), "Is_Subset empty/any");
      Check (Is_Subset (Bit (1), Bit (1) or Bit (2)), "Is_Subset proper");
      Check (not Is_Subset (Bit (2), Bit (1)), "Is_Subset reject");
      Check (Goal_Satisfied (Bit (1) or Bit (2), Bit (1)),
             "Goal_Satisfied subset ok");
      Check (not Goal_Satisfied (Bit (1), Bit (1) or Bit (2)),
             "Goal_Satisfied missing");
      Check (Goal_Satisfied (0, 0), "Goal_Satisfied vacuously");
      Check (Difference_Mask (0, Bit (3)) = Bit (3), "Diff mask from empty");
      Check (Difference_Mask (Bit (3), Bit (3)) = 0, "Diff mask none");
      Check (Difference_Mask (Bit (1), Bit (1) or Bit (2)) = Bit (2),
             "Diff mask partial");
   end;

   ---------------------------------------------------------------------
   Section ("2. Operator Applicable / Apply / Reduces");
   ---------------------------------------------------------------------
   declare
      Op : constant Operator :=
        (Preconditions => Bit (1) or Bit (2),
         Add_List      => Bit (3),
         Delete_List   => Bit (1),
         Reduces       => 3);
      S0 : constant State := Bit (1) or Bit (2);
      S1 : State;
   begin
      Check (Applicable (S0, Op), "Applicable when preconds hold");
      Check (not Applicable (Bit (1), Op), "Applicable rejects missing");
      Check (not Applicable (0, Op), "Applicable rejects empty");
      Check (Applicable (S0 or Bit (9), Op), "Applicable ignores extras");
      S1 := Apply (S0, Op);
      Check (Has (S1, 3), "Apply adds");
      Check (not Has (S1, 1), "Apply deletes");
      Check (Has (S1, 2), "Apply keeps others");
      Check (Reduces_Difference (Op, 3), "Reduces via Reduces field");
      Check (Reduces_Difference (Op, 3), "Reduces via Add_List too");
      declare
         Op2 : constant Operator :=
           (Preconditions => 0, Add_List => Bit (4), Delete_List => 0,
            Reduces => 0);
      begin
         Check (Reduces_Difference (Op2, 4), "Reduces via Add_List only");
         Check (not Reduces_Difference (Op2, 5), "Reduces rejects other");
         Check (Operator_Valid (Op2), "Operator_Valid Reduces=0");
      end;
      Check (Operator_Valid (Op), "Operator_Valid Reduces=3");
      declare
         Bad : constant Operator :=
           (0, 0, 0, Reduces => Max_Conditions + 1);
      begin
         Check (not Operator_Valid (Bad), "Operator_Valid rejects high");
      end;
      Check (Apply (0, (0, Bit (1), 0, 0)) = Bit (1),
             "Apply from empty with add");
      Check (Apply (Bit (1) or Bit (2), (0, 0, Bit (1), 0)) = Bit (2),
             "Apply delete only");
   end;

   ---------------------------------------------------------------------
   Section ("3. Ranked_Differences ordering");
   ---------------------------------------------------------------------
   declare
      Cur  : constant State := 0;
      Goal : constant State := Make_State ([1, 2, 5]);
      R0   : constant Condition_Index_Array :=
        Ranked_Differences (Cur, Goal);
      R1   : constant Condition_Index_Array :=
        Ranked_Differences (Cur, Goal, [5, 1]);
      R2   : constant Condition_Index_Array :=
        Ranked_Differences (Bit (1) or Bit (2) or Bit (5), Goal);
   begin
      Check (R0'Length = 3, "default ranked length 3");
      Check (R0 (1) = 1 and R0 (2) = 2 and R0 (3) = 5,
             "default ascending");
      Check (R1'Length = 3, "custom ranked length 3");
      Check (R1 (1) = 5 and R1 (2) = 1 and R1 (3) = 2,
             "custom order then rest");
      Check (R2'Length = 0, "no differences when satisfied");
      Check (Ranked_Differences (0, 0)'Length = 0, "empty goal ranked");
      declare
         R3 : constant Condition_Index_Array :=
           Ranked_Differences (0, Bit (4), [4, 4, 1]);
      begin
         Check (R3'Length = 1 and R3 (1) = 4, "dedupe order entries");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Trivial Solve: already at goal");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 16);
      Len  : Natural;
      Ok   : Boolean;
      Ops  : constant Operator_List := School_Operators;
   begin
      Ok := Solve (School_Goal, School_Goal, Ops, Plan, Len);
      Check (Ok, "Solve already satisfied");
      Check (Len = 0, "already satisfied empty plan");
      Ok := Solve (0, 0, Ops, Plan, Len);
      Check (Ok and Len = 0, "Solve empty/empty");
      Ok := Solve (Make_State ([1, 2, 3]), Bit (2), Ops, Plan, Len);
      Check (Ok and Len = 0, "Solve extras already cover goal");
   end;

   ---------------------------------------------------------------------
   Section ("5. Blocks-world lite");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 16);
      Len  : Natural;
      Ok   : Boolean;
      Ops  : constant Operator_List := Blocks_Operators;
   begin
      Ok := Solve (Blocks_Start, Blocks_Goal, Ops, Plan, Len);
      Check (Ok, "blocks Solve finds plan");
      Check (Len = 2, "blocks plan length 2 (pickup, stack)");
      Check (Plan (1) = Natural (Pickup_Op), "blocks step1 pickup");
      Check (Plan (2) = Natural (Stack_Op), "blocks step2 stack");
      Check (Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, Plan, Len),
             "blocks plan reaches goal");
      Check (Execute_Plan (Blocks_Start, Ops, Plan, Len) =
               Bit (Block_On_Target),
             "blocks execute final state");

      --  Already holding: only stack
      Ok := Solve (Bit (Block_Held), Blocks_Goal, Ops, Plan, Len);
      Check (Ok and Len = 1 and Plan (1) = Natural (Stack_Op),
             "blocks from held");

      --  Impossible: no ops that add goal
      declare
         Bad_Ops : constant Operator_List :=
           [1 => (Bit (Block_On_Table), Bit (Block_Held),
                  Bit (Block_On_Table), Natural (Block_Held))];
      begin
         Ok := Solve (Blocks_Start, Blocks_Goal, Bad_Ops, Plan, Len,
                      Max_Depth => 8);
         Check (not Ok, "blocks impossible returns False");
      end;

      --  Depth 0 cannot expand
      Ok := Solve (Blocks_Start, Blocks_Goal, Ops, Plan, Len,
                   Max_Depth => 0);
      Check (not Ok, "blocks Max_Depth 0 fails");
   end;

   ---------------------------------------------------------------------
   Section ("6. Classic school domain (drive son to school)");
   ---------------------------------------------------------------------
   declare
      Plan  : Plan_Array (1 .. 32);
      Len   : Natural;
      Ok    : Boolean;
      Ops   : constant Operator_List := School_Operators;
      Order : constant Difference_Order := School_Difference_Order;
      Final : State;
   begin
      Check (Has (School_Start, Son_At_Home), "school start son home");
      Check (Has (School_Start, Car_Needs_Battery), "school start needs bat");
      Check (Has (School_Start, Have_Money), "school start money");
      Check (Has (School_Start, Have_Phone_Book), "school start phone book");
      Check (not Has (School_Start, Car_Works), "school start car broken");
      Check (School_Goal = Bit (Son_At_School), "school goal");
      Check (Ops'Length = 6, "school six operators");

      Ok := Solve
        (School_Start, School_Goal, Ops, Plan, Len,
         Max_Depth => 24, Order => Order);
      Check (Ok, "school Solve finds plan");
      Check (Len > 0, "school plan non-empty");
      Check (Len <= 8, "school plan reasonably short");
      Check (Plan_Reaches_Goal
               (School_Start, School_Goal, Ops, Plan, Len),
             "school plan reaches goal");
      Final := Execute_Plan (School_Start, Ops, Plan, Len);
      Check (Goal_Satisfied (Final, School_Goal),
             "school execute satisfies goal");
      Check (Has (Final, Son_At_School), "school final son at school");
      Check (not Has (Final, Son_At_Home), "school final not at home");

      --  Last operator should be drive-son-to-school
      Check (Plan (Len) = Natural (Drive_Son_To_School_Op),
             "school last op is drive");

      --  Without phone book cannot look up / call / fix car / drive
      declare
         Bad_Start : constant State :=
           Make_State ([Son_At_Home, Car_Needs_Battery, Have_Money]);
      begin
         Ok := Solve
           (Bad_Start, School_Goal, Ops, Plan, Len, Max_Depth => 16,
            Order => Order);
         Check (not Ok, "school without phone book fails");
      end;

      --  Car already works: only drive
      declare
         Easy : constant State :=
           Make_State ([Son_At_Home, Car_Works]);
      begin
         Ok := Solve (Easy, School_Goal, Ops, Plan, Len);
         Check (Ok and Len = 1, "school car works -> one step");
         Check (Plan (1) = Natural (Drive_Son_To_School_Op),
                "school easy is drive");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. School plan step structure");
   ---------------------------------------------------------------------
   declare
      Plan  : Plan_Array (1 .. 32);
      Len   : Natural;
      Ok    : Boolean;
      Ops   : constant Operator_List := School_Operators;
      Order : constant Difference_Order := School_Difference_Order;
      Seen_Look, Seen_Tel, Seen_Tell, Seen_Pay, Seen_Fix, Seen_Drive :
        Boolean := False;
   begin
      Ok := Solve
        (School_Start, School_Goal, Ops, Plan, Len,
         Max_Depth => 24, Order => Order);
      Check (Ok, "school structure solve");
      for K in 1 .. Len loop
         case Plan (K) is
            when Natural (Look_Up_Number_Op) => Seen_Look := True;
            when Natural (Telephone_Shop_Op) => Seen_Tel := True;
            when Natural (Tell_Shop_Problem_Op) => Seen_Tell := True;
            when Natural (Give_Shop_Money_Op) => Seen_Pay := True;
            when Natural (Shop_Installs_Battery_Op) => Seen_Fix := True;
            when Natural (Drive_Son_To_School_Op) => Seen_Drive := True;
            when others => null;
         end case;
      end loop;
      Check (Seen_Look, "school uses look-up-number");
      Check (Seen_Tel, "school uses telephone-shop");
      Check (Seen_Tell, "school uses tell-shop-problem");
      Check (Seen_Pay, "school uses give-shop-money");
      Check (Seen_Fix, "school uses shop-installs-battery");
      Check (Seen_Drive, "school uses drive-son-to-school");
   end;

   ---------------------------------------------------------------------
   Section ("8. Depth bound and empty operators");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 16);
      Len  : Natural;
      Ok   : Boolean;
      Ops  : constant Operator_List := Blocks_Operators;
   begin
      Ok := Solve (Blocks_Start, Blocks_Goal, Ops, Plan, Len,
                   Max_Depth => 1);
      --  Need depth for precondition recursion + apply; depth 1 may still
      --  work if preconds already hold for first op. Pickup preconds hold
      --  at start, then stack needs another level — Max_Depth 1 should fail
      --  for full goal if Achieve checks depth before expanding further.
      Check (not Ok or else Len <= 2, "shallow depth bounded");

      Ok := Solve (Blocks_Start, Blocks_Goal, Ops, Plan, Len,
                   Max_Depth => 0);
      Check (not Ok, "Max_Depth 0 fails when work remains");

      declare
         No_Ops : Operator_List (1 .. 0);
      begin
         Ok := Solve (0, Bit (1), No_Ops, Plan, Len);
         Check (not Ok, "empty ops cannot achieve goal");
         Ok := Solve (Bit (1), Bit (1), No_Ops, Plan, Len);
         Check (Ok and Len = 0, "empty ops ok if already goal");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 8);
      Len  : Natural;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Bad : constant Operator_List :=
              [1 => (0, Bit (1), 0, Reduces => 99)];
            Unused : Boolean;
         begin
            Unused := Solve (0, Bit (1), Bad, Plan, Len);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Solve raises on bad Reduces");

      Raised := False;
      begin
         declare
            Tiny : Plan_Array (1 .. 0);
            Ops  : constant Operator_List := Blocks_Operators;
            Unused : Boolean;
         begin
            Unused := Solve (Blocks_Start, Blocks_Goal, Ops, Tiny, Len);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Solve raises when Plan_Array too short");

      Raised := False;
      begin
         declare
            Ops : constant Operator_List := Blocks_Operators;
            P   : constant Plan_Array := [1, 3];
            Unused : State;
         begin
            Unused := Execute_Plan (Blocks_Start, Ops, P, 5);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Execute_Plan raises Length > Plan'Length");

      Raised := False;
      begin
         declare
            Ops : constant Operator_List := Blocks_Operators;
            P   : constant Plan_Array := [99];
            Unused : State;
         begin
            Unused := Execute_Plan (Blocks_Start, Ops, P, 1);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Execute_Plan raises bad index");
   end;

   ---------------------------------------------------------------------
   Section ("10. Plan_Reaches_Goal negative cases");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List := Blocks_Operators;
   begin
      Check (not Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, [3], 1),
             "stack alone not applicable from table");
      Check (not Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, [1], 1),
             "pickup alone does not reach target");
      Check (Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, [1, 3], 2),
             "pickup+stack reaches");
      Check (not Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, [1, 3], 5),
             "Length > Plan'Length false");
      Check (not Plan_Reaches_Goal
               (Blocks_Start, Blocks_Goal, Ops, [0, 3], 2),
             "zero index false");
      Check (Plan_Reaches_Goal
               (Bit (Block_On_Target), Blocks_Goal, Ops, [1], 0),
             "empty plan at goal true");
   end;

   ---------------------------------------------------------------------
   Section ("11. Single-op chain domains");
   ---------------------------------------------------------------------
   declare
      --  A -> B -> C chain
      Ops : constant Operator_List :=
        [1 => (Preconditions => Bit (1), Add_List => Bit (2),
               Delete_List => 0, Reduces => 2),
         2 => (Preconditions => Bit (2), Add_List => Bit (3),
               Delete_List => 0, Reduces => 3)];
      Plan : Plan_Array (1 .. 8);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (Bit (1), Bit (3), Ops, Plan, Len);
      Check (Ok, "chain Solve");
      Check (Len = 2, "chain length 2");
      Check (Plan (1) = 1 and Plan (2) = 2, "chain order");
      Check (Plan_Reaches_Goal (Bit (1), Bit (3), Ops, Plan, Len),
             "chain reaches");
      Ok := Solve (Bit (1), Bit (2), Ops, Plan, Len);
      Check (Ok and Len = 1 and Plan (1) = 1, "chain partial");
      Ok := Solve (Bit (1), Make_State ([2, 3]), Ops, Plan, Len);
      Check (Ok, "chain multi-bit goal");
      Check (Goal_Satisfied
               (Execute_Plan (Bit (1), Ops, Plan, Len),
                Make_State ([2, 3])),
             "chain multi-bit final");
   end;

   ---------------------------------------------------------------------
   Section ("12. Competing operators / difference order");
   ---------------------------------------------------------------------
   declare
      --  Two ops both add condition 3; only Op2's preconds are free
      Ops : constant Operator_List :=
        [1 => (Preconditions => Bit (9), Add_List => Bit (3),
               Delete_List => 0, Reduces => 3),
         2 => (Preconditions => 0, Add_List => Bit (3),
               Delete_List => 0, Reduces => 3)];
      Plan : Plan_Array (1 .. 4);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (0, Bit (3), Ops, Plan, Len);
      Check (Ok, "competing Solve");
      Check (Len = 1 and Plan (1) = 2, "picks applicable op");
   end;

   declare
      --  Prefer high-priority difference first
      Ops : constant Operator_List :=
        [1 => (0, Bit (1), 0, 1),
         2 => (0, Bit (2), 0, 2)];
      Plan : Plan_Array (1 .. 4);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (0, Make_State ([1, 2]), Ops, Plan, Len,
                   Order => [2, 1]);
      Check (Ok and Len = 2, "order both achieved");
      Check (Plan (1) = 2, "higher-priority diff first");
      Check (Plan (2) = 1, "then remaining diff");
   end;

   ---------------------------------------------------------------------
   Section ("13. Delete-list interactions");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List :=
        [1 => (Preconditions => Bit (1),
               Add_List => Bit (2),
               Delete_List => Bit (1),
               Reduces => 2),
         2 => (Preconditions => Bit (2),
               Add_List => Bit (3),
               Delete_List => Bit (2),
               Reduces => 3)];
      Plan : Plan_Array (1 .. 8);
      Len  : Natural;
      Ok   : Boolean;
      Fin  : State;
   begin
      Ok := Solve (Bit (1), Bit (3), Ops, Plan, Len);
      Check (Ok, "delete-chain Solve");
      Fin := Execute_Plan (Bit (1), Ops, Plan, Len);
      Check (Has (Fin, 3), "delete-chain has goal");
      Check (not Has (Fin, 1), "delete-chain consumed start");
      Check (not Has (Fin, 2), "delete-chain consumed mid");
   end;

   ---------------------------------------------------------------------
   Section ("14. Idempotent / no-op resilience");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List :=
        [1 => (0, Bit (1), 0, 1),
         2 => (0, 0, 0, 0)];  -- no-op never reduces via Add
      Plan : Plan_Array (1 .. 4);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (0, Bit (1), Ops, Plan, Len);
      Check (Ok and Plan (1) = 1, "ignores no-op op");
      Check (Operator_Valid (Ops (2)), "no-op still valid");
   end;

   ---------------------------------------------------------------------
   Section ("15. Fixture constants sanity");
   ---------------------------------------------------------------------
   declare
      function Opaque (N : Natural) return Natural is
      begin
         return N;
      end Opaque;

      Ops_S : constant Operator_List := School_Operators;
      Ops_B : constant Operator_List := Blocks_Operators;
      Ord   : constant Difference_Order := School_Difference_Order;
   begin
      Check (Opaque (Natural (Son_At_Home)) = 1, "Son_At_Home id");
      Check (Opaque (Natural (Son_At_School)) = 2, "Son_At_School id");
      Check (Opaque (Natural (Car_Works)) = 3, "Car_Works id");
      Check (Opaque (Natural (Drive_Son_To_School_Op)) = 1, "Drive op id");
      Check (Opaque (Natural (Give_Shop_Money_Op)) = 6, "Give money op id");
      Check (Opaque (Natural (Block_On_Table)) = 1, "Block_On_Table id");
      Check (Opaque (Natural (Stack_Op)) = 3, "Stack_Op id");
      Check (Opaque (Max_Conditions) = 32, "Max_Conditions");
      Check (Opaque (Default_Max_Depth) = 32, "Default_Max_Depth");
      Check (Opaque (Empty_Order'Length) = 0, "Empty_Order length");
      Check (Opaque (Ops_S'Length) = 6, "School_Operators len");
      Check (Opaque (Ops_B'Length) = 3, "Blocks_Operators len");
      Check (Opaque (Ord'Length) >= 4, "School_Difference_Order non-trivial");
      Check (Reduces_Difference (Ops_S (Drive_Son_To_School_Op), Son_At_School),
             "drive reduces son-at-school");
      Check (Reduces_Difference (Ops_B (Stack_Op), Block_On_Target),
             "stack reduces on-target");
   end;

   ---------------------------------------------------------------------
   Section ("16. School operator preconditions spot checks");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List := School_Operators;
   begin
      Check (Applicable
               (Make_State ([Son_At_Home, Car_Works]),
                Ops (Drive_Son_To_School_Op)),
             "drive applicable");
      Check (not Applicable
               (Make_State ([Son_At_Home]),
                Ops (Drive_Son_To_School_Op)),
             "drive needs car");
      Check (Applicable
               (Bit (Have_Phone_Book), Ops (Look_Up_Number_Op)),
             "lookup applicable");
      Check (Has
               (Apply (Bit (Have_Phone_Book), Ops (Look_Up_Number_Op)),
                Know_Phone_Number),
             "lookup adds number");
      Check (not Has
               (Apply
                  (Make_State ([Have_Money, Car_Needs_Battery]),
                   Ops (Give_Shop_Money_Op)),
                Have_Money),
             "pay deletes money");
      Check (Has
               (Apply
                  (Make_State
                     ([Car_Needs_Battery, Shop_Knows_Problem, Shop_Has_Money]),
                   Ops (Shop_Installs_Battery_Op)),
                Car_Works),
             "install adds car-works");
   end;

   ---------------------------------------------------------------------
   Section ("17. Multi-goal simultaneous");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List :=
        [1 => (0, Bit (1), 0, 1),
         2 => (0, Bit (2), 0, 2),
         3 => (0, Bit (3), 0, 3)];
      Plan : Plan_Array (1 .. 8);
      Len  : Natural;
      Ok   : Boolean;
      G    : constant State := Make_State ([1, 2, 3]);
   begin
      Ok := Solve (0, G, Ops, Plan, Len);
      Check (Ok, "multi-goal Solve");
      Check (Len = 3, "multi-goal three steps");
      Check (Plan_Reaches_Goal (0, G, Ops, Plan, Len),
             "multi-goal reaches");
      Check (Count_Bits (Execute_Plan (0, Ops, Plan, Len)) = 3,
             "multi-goal all bits");
   end;

   ---------------------------------------------------------------------
   Section ("18. Backtracking when first op leads nowhere");
   ---------------------------------------------------------------------
   declare
      --  Op1 reduces Diff 2 but its add is useless for goal 3;
      --  Op2 reduces Diff 3 directly. Goal is bit 3.
      --  Also Op3 claims to reduce 3 but needs impossible precond 31.
      Ops : constant Operator_List :=
        [1 => (0, Bit (2), 0, 2),
         2 => (Bit (31), Bit (3), 0, 3),
         3 => (0, Bit (3), 0, 3)];
      Plan : Plan_Array (1 .. 8);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (0, Bit (3), Ops, Plan, Len, Max_Depth => 6);
      Check (Ok, "backtrack Solve");
      Check (Plan (Len) = 3 or Plan (1) = 3, "uses viable op 3");
      Check (Plan_Reaches_Goal (0, Bit (3), Ops, Plan, Len),
             "backtrack reaches");
   end;

   ---------------------------------------------------------------------
   Section ("19. Large condition indices");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List :=
        [1 => (Bit (32), Bit (31), 0, 31),
         2 => (0, Bit (32), 0, 32)];
      Plan : Plan_Array (1 .. 4);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Solve (0, Bit (31), Ops, Plan, Len);
      Check (Ok and Len = 2, "high-bit chain");
      Check (Plan (1) = 2 and Plan (2) = 1, "high-bit order");
      Check (Has (Execute_Plan (0, Ops, Plan, Len), 31),
             "high-bit final");
   end;

   ---------------------------------------------------------------------
   Section ("20. Putdown detour still optional");
   ---------------------------------------------------------------------
   declare
      Ops  : constant Operator_List := Blocks_Operators;
      Plan : Plan_Array (1 .. 16);
      Len  : Natural;
      Ok   : Boolean;
   begin
      --  From table, GPS should not need putdown to reach target
      Ok := Solve (Blocks_Start, Blocks_Goal, Ops, Plan, Len);
      Check (Ok, "no detour solve");
      declare
         Used_Putdown : Boolean := False;
      begin
         for K in 1 .. Len loop
            if Plan (K) = Natural (Putdown_Op) then
               Used_Putdown := True;
            end if;
         end loop;
         Check (not Used_Putdown, "optimal path skips putdown");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("21. Difference_Mask / Goal_Satisfied matrix");
   ---------------------------------------------------------------------
   declare
      A : constant State := Make_State ([1, 2, 3]);
      B : constant State := Make_State ([2, 4]);
   begin
      Check (Difference_Mask (A, B) = Bit (4), "matrix diff");
      Check (not Goal_Satisfied (A, B), "matrix not satisfied");
      Check (Goal_Satisfied (A or Bit (4), B), "matrix satisfied with 4");
      Check (Is_Subset (B and A, A), "matrix subset intersection");
      Check (Count_Bits (A or B) = 4, "matrix union count");
      Check (Count_Bits (A and B) = 1, "matrix intersect count");
   end;

   ---------------------------------------------------------------------
   Section ("22. Solve clears plan slots");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 8) := [others => 42];
      Len  : Natural;
      Ok   : Boolean;
      Ops  : constant Operator_List := Blocks_Operators;
   begin
      Ok := Solve (Blocks_Goal, Blocks_Goal, Ops, Plan, Len);
      Check (Ok and Len = 0, "clear-path trivial");
      Check (Plan (1) = 0 and Plan (8) = 0, "plan slots zeroed");
   end;

   ---------------------------------------------------------------------
   Section ("23. School without difference order still works");
   ---------------------------------------------------------------------
   declare
      Plan : Plan_Array (1 .. 32);
      Len  : Natural;
      Ok   : Boolean;
      Ops  : constant Operator_List := School_Operators;
   begin
      Ok := Solve
        (School_Start, School_Goal, Ops, Plan, Len, Max_Depth => 24);
      Check (Ok, "school default order Solve");
      Check (Plan_Reaches_Goal
               (School_Start, School_Goal, Ops, Plan, Len),
             "school default order reaches");
   end;

   ---------------------------------------------------------------------
   Section ("24. Execute_Plan identity / single step");
   ---------------------------------------------------------------------
   declare
      Ops : constant Operator_List := Blocks_Operators;
      P0  : constant Plan_Array (1 .. 4) := [others => 0];
   begin
      Check (Execute_Plan (Blocks_Start, Ops, P0, 0) = Blocks_Start,
             "execute empty identity");
      Check (Execute_Plan (Blocks_Start, Ops, [1], 1) = Bit (Block_Held),
             "execute pickup");
      Check (Execute_Plan (Bit (Block_Held), Ops, [3], 1) =
               Bit (Block_On_Target),
             "execute stack");
      Check (Execute_Plan (Bit (Block_Held), Ops, [2], 1) =
               Bit (Block_On_Table),
             "execute putdown");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;

end Tests;
