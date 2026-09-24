--  General_Problem_Solver body — means–ends analysis on bitset states.

pragma Ada_2022;

package body General_Problem_Solver
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Bit / state helpers
   -------------------------------------------------------------------------

   function Bit (C : Condition_Index) return State is
   begin
      return State (2**(Natural (C) - 1));
   end Bit;

   function Has (S : State; C : Condition_Index) return Boolean is
   begin
      return (S and Bit (C)) /= 0;
   end Has;

   function Set_Bit (S : State; C : Condition_Index) return State is
   begin
      return S or Bit (C);
   end Set_Bit;

   function Clear_Bit (S : State; C : Condition_Index) return State is
   begin
      return S and (not Bit (C));
   end Clear_Bit;

   function Make_State (Conditions : Condition_Index_Array) return State is
      Acc : State := 0;
   begin
      for C of Conditions loop
         Acc := Acc or Bit (C);
      end loop;
      return Acc;
   end Make_State;

   function Count_Bits (S : State) return Natural is
      N : Natural := 0;
      X : State := S;
   begin
      while X /= 0 loop
         if (X and 1) /= 0 then
            N := N + 1;
         end if;
         X := X / 2;
      end loop;
      return N;
   end Count_Bits;

   function Goal_Satisfied (Current, Goal : State) return Boolean is
   begin
      return (Current and Goal) = Goal;
   end Goal_Satisfied;

   function Difference_Mask (Current, Goal : State) return State is
   begin
      return Goal and (not Current);
   end Difference_Mask;

   function Is_Subset (Sub, Super : State) return Boolean is
   begin
      return (Super and Sub) = Sub;
   end Is_Subset;

   -------------------------------------------------------------------------
   -- Operators
   -------------------------------------------------------------------------

   function Applicable (Current : State; Op : Operator) return Boolean is
   begin
      return Is_Subset (Op.Preconditions, Current);
   end Applicable;

   function Apply (Current : State; Op : Operator) return State is
   begin
      return (Current and (not Op.Delete_List)) or Op.Add_List;
   end Apply;

   function Reduces_Difference
     (Op   : Operator;
      Diff : Condition_Index) return Boolean
   is
   begin
      if Op.Reduces = Natural (Diff) then
         return True;
      end if;
      return Has (Op.Add_List, Diff);
   end Reduces_Difference;

   function Operator_Valid (Op : Operator) return Boolean is
   begin
      return Op.Reduces <= Max_Conditions;
   end Operator_Valid;

   -------------------------------------------------------------------------
   -- Difference ranking
   -------------------------------------------------------------------------

   function Ranked_Differences
     (Current, Goal : State;
      Order         : Difference_Order := Empty_Order)
      return Condition_Index_Array
   is
      Missing : constant State := Difference_Mask (Current, Goal);
      Buf     : Condition_Index_Array (1 .. Max_Conditions);
      N       : Natural := 0;
      Seen    : array (Condition_Index) of Boolean := [others => False];
   begin
      if Missing = 0 then
         declare
            Empty : Condition_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      --  First: differences listed in Order (most important first)
      for C of Order loop
         if Has (Missing, C) and then not Seen (C) then
            N := N + 1;
            Buf (N) := C;
            Seen (C) := True;
         end if;
      end loop;

      --  Then: any remaining missing conditions by ascending index
      for C in Condition_Index loop
         if Has (Missing, C) and then not Seen (C) then
            N := N + 1;
            Buf (N) := C;
            Seen (C) := True;
         end if;
      end loop;

      return Buf (1 .. N);
   end Ranked_Differences;

   -------------------------------------------------------------------------
   -- Validation helpers
   -------------------------------------------------------------------------

   procedure Validate_Ops (Ops : Operator_List) is
   begin
      for Op of Ops loop
         if not Operator_Valid (Op) then
            raise Invalid_Argument with "Operator.Reduces out of range";
         end if;
      end loop;
   end Validate_Ops;

   -------------------------------------------------------------------------
   -- Recursive means–ends analysis
   -------------------------------------------------------------------------

   function Achieve
     (Current   : in out State;
      Goals     : State;
      Ops       : Operator_List;
      Plan      : in out Plan_Array;
      Length    : in out Natural;
      Depth     : Natural;
      Max_Depth : Natural;
      Order     : Difference_Order) return Boolean
   is
      Diffs : Condition_Index_Array (1 .. Max_Conditions);
      ND    : Natural;
   begin
      if Depth > Max_Depth then
         return False;
      end if;

      loop
         declare
            Ranked : constant Condition_Index_Array :=
              Ranked_Differences (Current, Goals, Order);
         begin
            ND := Ranked'Length;
            if ND = 0 then
               return True;
            end if;
            Diffs (1 .. ND) := Ranked;
         end;

         declare
            Progress : Boolean := False;
         begin
            Diff_Loop :
            for D in 1 .. ND loop
               declare
                  Diff : constant Condition_Index := Diffs (D);
               begin
                  Op_Loop :
                  for Oi in Ops'Range loop
                     declare
                        Op : Operator renames Ops (Oi);
                     begin
                        if Reduces_Difference (Op, Diff) then
                           declare
                              Saved_State  : constant State := Current;
                              Saved_Length : constant Natural := Length;
                              Ok           : Boolean;
                           begin
                              --  Recursively satisfy preconditions
                              Ok := Achieve
                                (Current, Op.Preconditions, Ops, Plan, Length,
                                 Depth + 1, Max_Depth, Order);

                              if Ok and then Applicable (Current, Op) then
                                 if Length >= Plan'Length then
                                    Current := Saved_State;
                                    Length  := Saved_Length;
                                    raise Invalid_Argument
                                      with "Plan_Array too short for GPS plan";
                                 end if;
                                 Length := Length + 1;
                                 --  1-based index relative to Ops'First
                                 Plan (Plan'First + Length - 1) :=
                                   Natural (Oi - Ops'First + 1);
                                 Current := Apply (Current, Op);
                                 Progress := True;
                                 exit Diff_Loop;
                              end if;

                              --  Backtrack
                              Current := Saved_State;
                              Length  := Saved_Length;
                           end;
                        end if;
                     end;
                  end loop Op_Loop;
               end;
            end loop Diff_Loop;

            if not Progress then
               return False;
            end if;
         end;
      end loop;
   end Achieve;

   function Solve
     (Start     : State;
      Goal      : State;
      Ops       : Operator_List;
      Plan      : out Plan_Array;
      Length    : out Natural;
      Max_Depth : Natural := Default_Max_Depth;
      Order     : Difference_Order := Empty_Order) return Boolean
   is
      Current : State := Start;
   begin
      Validate_Ops (Ops);
      Length := 0;
      for I in Plan'Range loop
         Plan (I) := 0;
      end loop;

      if Goal_Satisfied (Current, Goal) then
         return True;
      end if;

      if Ops'Length = 0 then
         return False;
      end if;

      return Achieve
        (Current, Goal, Ops, Plan, Length, 0, Max_Depth, Order);
   end Solve;

   function Execute_Plan
     (Start  : State;
      Ops    : Operator_List;
      Plan   : Plan_Array;
      Length : Natural) return State
   is
      Current : State := Start;
   begin
      if Length > Plan'Length then
         raise Invalid_Argument with "Length exceeds Plan'Length";
      end if;

      for K in 1 .. Length loop
         declare
            Idx : constant Natural := Plan (Plan'First + K - 1);
         begin
            if Idx = 0 or else Idx > Ops'Length then
               raise Invalid_Argument with "Plan entry out of range";
            end if;
            Current := Apply (Current, Ops (Ops'First + Idx - 1));
         end;
      end loop;
      return Current;
   end Execute_Plan;

   function Plan_Reaches_Goal
     (Start  : State;
      Goal   : State;
      Ops    : Operator_List;
      Plan   : Plan_Array;
      Length : Natural) return Boolean
   is
      Current : State := Start;
   begin
      if Length > Plan'Length then
         return False;
      end if;

      for K in 1 .. Length loop
         declare
            Idx : constant Natural := Plan (Plan'First + K - 1);
         begin
            if Idx = 0 or else Idx > Ops'Length then
               return False;
            end if;
            declare
               Op : Operator renames Ops (Ops'First + Idx - 1);
            begin
               if not Applicable (Current, Op) then
                  return False;
               end if;
               Current := Apply (Current, Op);
            end;
         end;
      end loop;
      return Goal_Satisfied (Current, Goal);
   end Plan_Reaches_Goal;

   -------------------------------------------------------------------------
   -- School domain
   -------------------------------------------------------------------------

   function School_Start return State is
   begin
      return Make_State
        ([Son_At_Home, Car_Needs_Battery, Have_Money, Have_Phone_Book]);
   end School_Start;

   function School_Goal return State is
   begin
      return Bit (Son_At_School);
   end School_Goal;

   function School_Operators return Operator_List is
   begin
      return
        [Drive_Son_To_School_Op =>
           (Preconditions => Bit (Son_At_Home) or Bit (Car_Works),
            Add_List      => Bit (Son_At_School),
            Delete_List   => Bit (Son_At_Home),
            Reduces       => Natural (Son_At_School)),

         Shop_Installs_Battery_Op =>
           (Preconditions =>
              Bit (Car_Needs_Battery) or Bit (Shop_Knows_Problem)
              or Bit (Shop_Has_Money),
            Add_List    => Bit (Car_Works),
            Delete_List => Bit (Car_Needs_Battery),
            Reduces     => Natural (Car_Works)),

         Tell_Shop_Problem_Op =>
           (Preconditions => Bit (In_Communication_With_Shop),
            Add_List      => Bit (Shop_Knows_Problem),
            Delete_List   => 0,
            Reduces       => Natural (Shop_Knows_Problem)),

         Telephone_Shop_Op =>
           (Preconditions => Bit (Know_Phone_Number),
            Add_List      => Bit (In_Communication_With_Shop),
            Delete_List   => 0,
            Reduces       => Natural (In_Communication_With_Shop)),

         Look_Up_Number_Op =>
           (Preconditions => Bit (Have_Phone_Book),
            Add_List      => Bit (Know_Phone_Number),
            Delete_List   => 0,
            Reduces       => Natural (Know_Phone_Number)),

         Give_Shop_Money_Op =>
           (Preconditions => Bit (Have_Money),
            Add_List      => Bit (Shop_Has_Money),
            Delete_List   => Bit (Have_Money),
            Reduces       => Natural (Shop_Has_Money))];
   end School_Operators;

   function School_Difference_Order return Difference_Order is
   begin
      return
        [Son_At_School, Car_Works, Shop_Has_Money, Shop_Knows_Problem,
         In_Communication_With_Shop, Know_Phone_Number];
   end School_Difference_Order;

   -------------------------------------------------------------------------
   -- Blocks-world lite
   -------------------------------------------------------------------------

   function Blocks_Start return State is
   begin
      return Bit (Block_On_Table);
   end Blocks_Start;

   function Blocks_Goal return State is
   begin
      return Bit (Block_On_Target);
   end Blocks_Goal;

   function Blocks_Operators return Operator_List is
   begin
      return
        [Pickup_Op =>
           (Preconditions => Bit (Block_On_Table),
            Add_List      => Bit (Block_Held),
            Delete_List   => Bit (Block_On_Table),
            Reduces       => Natural (Block_Held)),

         Putdown_Op =>
           (Preconditions => Bit (Block_Held),
            Add_List      => Bit (Block_On_Table),
            Delete_List   => Bit (Block_Held),
            Reduces       => Natural (Block_On_Table)),

         Stack_Op =>
           (Preconditions => Bit (Block_Held),
            Add_List      => Bit (Block_On_Target),
            Delete_List   => Bit (Block_Held),
            Reduces       => Natural (Block_On_Target))];
   end Blocks_Operators;

end General_Problem_Solver;
