pragma Ada_2022;

package body Unification_Engine
  with SPARK_Mode => On,
       Refined_State => (Term_Pool => (Pool, Count))
is

   ----------------------------------------------------------------------
   -- Pool queries (expression functions for proof)
   ----------------------------------------------------------------------

   function Term_Count return Term_Id is (Count)
     with Refined_Global => (Input => Count);

   function Space_Left return Natural is (Max_Terms - Natural (Count))
     with Refined_Global => (Input => Count);

   function Is_Allocated (Id : Term_Id) return Boolean is
     (Id in Allocated_Id and then Id <= Count)
     with Refined_Global => (Input => Count);

   procedure Reset_Pool is
   begin
      Pool  := [others => (Kind => Is_Constant, Name => ' ',
                           Left => Null_Term, Right => Null_Term)];
      Count := 0;
   end Reset_Pool;

   procedure Clear (Env : out Substitution) is
   begin
      Env.Bindings := [others => Null_Term];
   end Clear;

   ----------------------------------------------------------------------
   -- Accessors
   ----------------------------------------------------------------------

   function Kind_Of (Id : Term_Id) return Term_Kind is (Pool (Id).Kind)
     with Refined_Global => (Input => Pool, Proof_In => Count);

   function Name_Of (Id : Term_Id) return Character is (Pool (Id).Name)
     with Refined_Global => (Input => Pool, Proof_In => Count);

   function Left_Of (Id : Term_Id) return Term_Id is (Pool (Id).Left)
     with Refined_Global => (Input => Pool, Proof_In => Count);

   function Right_Of (Id : Term_Id) return Term_Id is (Pool (Id).Right)
     with Refined_Global => (Input => Pool, Proof_In => Count);

   ----------------------------------------------------------------------
   -- Allocation
   ----------------------------------------------------------------------

   procedure Alloc (Slot : Term_Slot; Id : out Allocated_Id)
     with Global => (In_Out => (Pool, Count)),
          Pre    => Count < Max_Terms,
          Post   => Count = Count'Old + 1
                    and then Id = Count
                    and then Pool (Id) = Slot
   is
   begin
      Count := Count + 1;
      Pool (Count) := Slot;
      Id := Count;
   end Alloc;

   procedure Make_Variable (Name : Var_Name; Id : out Allocated_Id) is
   begin
      Alloc ((Kind => Is_Variable, Name => Name,
              Left => Null_Term, Right => Null_Term), Id);
   end Make_Variable;

   procedure Make_Constant (Name : Character; Id : out Allocated_Id) is
   begin
      Alloc ((Kind => Is_Constant, Name => Name,
              Left => Null_Term, Right => Null_Term), Id);
   end Make_Constant;

   procedure Make_Function
     (Name : Character; Left, Right : Term_Id; Id : out Allocated_Id)
   is
   begin
      Alloc ((Kind => Is_Function, Name => Name,
              Left => Left, Right => Right), Id);
   end Make_Function;

   ----------------------------------------------------------------------
   -- Occurs check (fuel-bounded)
   ----------------------------------------------------------------------

   function Occurs_Check_Fuel
     (V    : Var_Name;
      T    : Term_Id;
      Env  : Substitution;
      Fuel : Natural) return Boolean
     with Global => (Input => (Pool, Count)),
          Pre    => T = Null_Term or else Is_Allocated (T),
          Subprogram_Variant => (Decreases => Fuel)
   is
      Bound : Term_Id;
      L, R  : Term_Id;
   begin
      if Fuel = 0 then
         return True;  -- conservative: treat as occurs
      end if;
      if T = Null_Term then
         return False;
      end if;

      case Pool (T).Kind is
         when Is_Variable =>
            if Pool (T).Name = Character (V) then
               return True;
            end if;
            if Pool (T).Name in Var_Name then
               Bound := Env.Bindings (Pool (T).Name);
               if Bound /= Null_Term and then Is_Allocated (Bound) then
                  return Occurs_Check_Fuel (V, Bound, Env, Fuel - 1);
               end if;
            end if;
            return False;

         when Is_Constant =>
            return False;

         when Is_Function =>
            L := Pool (T).Left;
            R := Pool (T).Right;
            if L /= Null_Term and then not Is_Allocated (L) then
               return False;
            end if;
            if R /= Null_Term and then not Is_Allocated (R) then
               return False;
            end if;
            return Occurs_Check_Fuel (V, L, Env, Fuel - 1)
              or else Occurs_Check_Fuel (V, R, Env, Fuel - 1);
      end case;
   end Occurs_Check_Fuel;

   function Occurs_Check
     (V : Var_Name; T : Term_Id; Env : Substitution) return Boolean
   is
   begin
      return Occurs_Check_Fuel (V, T, Env, Max_Terms);
   end Occurs_Check;

   ----------------------------------------------------------------------
   -- Unify (fuel-bounded)
   ----------------------------------------------------------------------

   procedure Unify_Fuel
     (T1, T2  : Term_Id;
      Env     : in out Substitution;
      Fuel    : Natural;
      Success : out Boolean)
     with Global => (Input => (Pool, Count)),
          Pre    => (T1 = Null_Term or else Is_Allocated (T1))
                    and then (T2 = Null_Term or else Is_Allocated (T2)),
          Subprogram_Variant => (Decreases => Fuel)
   is
      Bound : Term_Id;
      L1, R1, L2, R2 : Term_Id;
      Left_OK, Right_OK : Boolean;
   begin
      Success := False;

      if Fuel = 0 then
         return;
      end if;

      if T1 = Null_Term and then T2 = Null_Term then
         Success := True;
         return;
      elsif T1 = Null_Term or else T2 = Null_Term then
         return;
      end if;

      --  Dereference bound variables
      if Pool (T1).Kind = Is_Variable and then Pool (T1).Name in Var_Name then
         Bound := Env.Bindings (Pool (T1).Name);
         if Bound /= Null_Term and then Is_Allocated (Bound) then
            Unify_Fuel (Bound, T2, Env, Fuel - 1, Success);
            return;
         end if;
      end if;

      if Pool (T2).Kind = Is_Variable and then Pool (T2).Name in Var_Name then
         Bound := Env.Bindings (Pool (T2).Name);
         if Bound /= Null_Term and then Is_Allocated (Bound) then
            Unify_Fuel (T1, Bound, Env, Fuel - 1, Success);
            return;
         end if;
      end if;

      --  Both dereferenced
      if Pool (T1).Kind = Is_Variable and then Pool (T1).Name in Var_Name then
         if Pool (T2).Kind = Is_Variable
           and then Pool (T1).Name = Pool (T2).Name
         then
            Success := True;
            return;
         end if;
         if Occurs_Check (Pool (T1).Name, T2, Env) then
            return;
         end if;
         Env.Bindings (Pool (T1).Name) := T2;
         Success := True;
         return;

      elsif Pool (T2).Kind = Is_Variable and then Pool (T2).Name in Var_Name then
         if Occurs_Check (Pool (T2).Name, T1, Env) then
            return;
         end if;
         Env.Bindings (Pool (T2).Name) := T1;
         Success := True;
         return;

      elsif Pool (T1).Kind = Is_Constant
        and then Pool (T2).Kind = Is_Constant
      then
         Success := Pool (T1).Name = Pool (T2).Name;
         return;

      elsif Pool (T1).Kind = Is_Function
        and then Pool (T2).Kind = Is_Function
      then
         if Pool (T1).Name /= Pool (T2).Name then
            return;
         end if;
         L1 := Pool (T1).Left;
         R1 := Pool (T1).Right;
         L2 := Pool (T2).Left;
         R2 := Pool (T2).Right;
         if (L1 /= Null_Term and then not Is_Allocated (L1))
           or else (R1 /= Null_Term and then not Is_Allocated (R1))
           or else (L2 /= Null_Term and then not Is_Allocated (L2))
           or else (R2 /= Null_Term and then not Is_Allocated (R2))
         then
            return;
         end if;
         Unify_Fuel (L1, L2, Env, Fuel - 1, Left_OK);
         if Left_OK then
            Unify_Fuel (R1, R2, Env, Fuel - 1, Right_OK);
            Success := Right_OK;
         end if;
         return;

      else
         return;
      end if;
   end Unify_Fuel;

   procedure Unify
     (T1, T2 : Term_Id; Env : in out Substitution; Success : out Boolean)
   is
   begin
      Unify_Fuel (T1, T2, Env, Max_Terms, Success);
   end Unify;

   ----------------------------------------------------------------------
   -- Apply substitution (fuel-bounded; may allocate)
   ----------------------------------------------------------------------

   procedure Apply_Fuel
     (T       : Term_Id;
      Env     : Substitution;
      Fuel    : Natural;
      Result  : out Term_Id;
      Success : out Boolean)
     with Global => (In_Out => (Pool, Count)),
          Pre    => T = Null_Term or else Is_Allocated (T),
          Post   => (if not Success then Result = Null_Term
                     elsif Result /= Null_Term then Is_Allocated (Result)),
          Subprogram_Variant => (Decreases => Fuel)
   is
      Bound      : Term_Id;
      L_OK, R_OK : Boolean;
      New_Id     : Allocated_Id;
      Saved_Name : Character;
      Child_L, Child_R : Term_Id;
      Res_L, Res_R     : Term_Id;
   begin
      Success := False;
      Result  := Null_Term;

      if Fuel = 0 then
         return;
      end if;

      if T = Null_Term then
         Success := True;
         Result  := Null_Term;
         return;
      end if;

      case Pool (T).Kind is
         when Is_Variable =>
            if Pool (T).Name in Var_Name then
               Bound := Env.Bindings (Pool (T).Name);
               if Bound /= Null_Term and then Is_Allocated (Bound) then
                  Apply_Fuel (Bound, Env, Fuel - 1, Result, Success);
                  return;
               end if;
            end if;
            Success := True;
            Result  := T;

         when Is_Constant =>
            Success := True;
            Result  := T;

         when Is_Function =>
            Saved_Name := Pool (T).Name;
            Child_L := Pool (T).Left;
            Child_R := Pool (T).Right;
            if Child_L /= Null_Term and then not Is_Allocated (Child_L) then
               return;
            end if;
            if Child_R /= Null_Term and then not Is_Allocated (Child_R) then
               return;
            end if;

            Apply_Fuel (Child_L, Env, Fuel - 1, Res_L, L_OK);
            if not L_OK then
               return;
            end if;

            --  Child_R still valid: Apply_Fuel only appends; never shrinks.
            if Child_R /= Null_Term and then not Is_Allocated (Child_R) then
               return;
            end if;

            Apply_Fuel (Child_R, Env, Fuel - 1, Res_R, R_OK);
            if not R_OK then
               return;
            end if;

            if Space_Left = 0 then
               return;
            end if;
            if (Res_L /= Null_Term and then not Is_Allocated (Res_L))
              or else (Res_R /= Null_Term and then not Is_Allocated (Res_R))
            then
               return;
            end if;

            Make_Function (Saved_Name, Res_L, Res_R, New_Id);
            Success := True;
            Result  := New_Id;
      end case;
   end Apply_Fuel;

   procedure Apply_Substitution
     (T : Term_Id; Env : Substitution;
      Result : out Term_Id; Success : out Boolean)
   is
   begin
      Apply_Fuel (T, Env, Max_Terms, Result, Success);
   end Apply_Substitution;

end Unification_Engine;
