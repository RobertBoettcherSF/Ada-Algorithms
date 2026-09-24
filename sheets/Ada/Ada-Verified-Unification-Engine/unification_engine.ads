--  Educational first-order syntactic unification with occurs-check.
--  Bounded term pool (no access types / heap) for SPARK Level 2.

pragma Ada_2022;

package Unification_Engine
  with SPARK_Mode => On,
       Abstract_State => Term_Pool,
       Initializes    => Term_Pool
is
   ---------------------------------------------------------------------------
   -- Capacity and identifiers
   ---------------------------------------------------------------------------

   Max_Terms : constant Positive := 32;
   --  Smallest power-of-two bound that keeps tests and Level-2 prove green.

   subtype Term_Id is Natural range 0 .. Max_Terms;
   Null_Term : constant Term_Id := 0;
   subtype Allocated_Id is Term_Id range 1 .. Max_Terms;

   subtype Var_Name is Character range 'a' .. 'z';

   type Term_Kind is (Is_Variable, Is_Constant, Is_Function);

   ---------------------------------------------------------------------------
   -- Substitution environment: Var_Name -> Term_Id
   ---------------------------------------------------------------------------

   type Substitution_Map is array (Var_Name) of Term_Id;
   type Substitution is record
      Bindings : Substitution_Map := [others => Null_Term];
   end record;

   ---------------------------------------------------------------------------
   -- Pool queries / reset
   ---------------------------------------------------------------------------

   function Term_Count return Term_Id
     with Global => (Input => Term_Pool);

   function Space_Left return Natural
     with Global => (Input => Term_Pool),
          Post   => Space_Left'Result = Natural (Max_Terms - Term_Count);

   function Is_Allocated (Id : Term_Id) return Boolean
     with Global => (Input => Term_Pool),
          Post   => Is_Allocated'Result =
                    (Id in Allocated_Id and then Id <= Term_Count);

   procedure Reset_Pool
     with Global => (Output => Term_Pool),
          Post   => Term_Count = 0;

   procedure Clear (Env : out Substitution)
     with Global => null,
          Post   => (for all V in Var_Name => Env.Bindings (V) = Null_Term);

   ---------------------------------------------------------------------------
   -- Term accessors
   ---------------------------------------------------------------------------

   function Kind_Of (Id : Term_Id) return Term_Kind
     with Global => (Input => Term_Pool),
          Pre    => Id in Allocated_Id and then Is_Allocated (Id);

   function Name_Of (Id : Term_Id) return Character
     with Global => (Input => Term_Pool),
          Pre    => Id in Allocated_Id and then Is_Allocated (Id);

   function Left_Of (Id : Term_Id) return Term_Id
     with Global => (Input => Term_Pool),
          Pre    => Id in Allocated_Id
                    and then Is_Allocated (Id)
                    and then Kind_Of (Id) = Is_Function;

   function Right_Of (Id : Term_Id) return Term_Id
     with Global => (Input => Term_Pool),
          Pre    => Id in Allocated_Id
                    and then Is_Allocated (Id)
                    and then Kind_Of (Id) = Is_Function;

   ---------------------------------------------------------------------------
   -- Constructors (bump-allocate into the pool)
   ---------------------------------------------------------------------------

   procedure Make_Variable (Name : Var_Name; Id : out Allocated_Id)
     with Global => (In_Out => Term_Pool),
          Pre    => Space_Left > 0,
          Post   => Term_Count = Term_Count'Old + 1
                    and then Id = Term_Count
                    and then Kind_Of (Id) = Is_Variable
                    and then Name_Of (Id) = Name;

   procedure Make_Constant (Name : Character; Id : out Allocated_Id)
     with Global => (In_Out => Term_Pool),
          Pre    => Space_Left > 0,
          Post   => Term_Count = Term_Count'Old + 1
                    and then Id = Term_Count
                    and then Kind_Of (Id) = Is_Constant
                    and then Name_Of (Id) = Name;

   procedure Make_Function
     (Name : Character; Left, Right : Term_Id; Id : out Allocated_Id)
     with Global => (In_Out => Term_Pool),
          Pre    => Space_Left > 0
                    and then (Left = Null_Term or else Is_Allocated (Left))
                    and then (Right = Null_Term or else Is_Allocated (Right)),
          Post   => Term_Count = Term_Count'Old + 1
                    and then Id = Term_Count
                    and then Kind_Of (Id) = Is_Function
                    and then Name_Of (Id) = Name
                    and then Left_Of (Id) = Left
                    and then Right_Of (Id) = Right;

   ---------------------------------------------------------------------------
   -- Core engine
   ---------------------------------------------------------------------------

   function Occurs_Check
     (V : Var_Name; T : Term_Id; Env : Substitution) return Boolean
     with Global => (Input => Term_Pool),
          Pre    => T = Null_Term or else Is_Allocated (T);

   procedure Unify
     (T1, T2 : Term_Id; Env : in out Substitution; Success : out Boolean)
     with Global => (Input => Term_Pool),
          Pre    => (T1 = Null_Term or else Is_Allocated (T1))
                    and then (T2 = Null_Term or else Is_Allocated (T2));

   procedure Apply_Substitution
     (T : Term_Id; Env : Substitution;
      Result : out Term_Id; Success : out Boolean)
     with Global => (In_Out => Term_Pool),
          Pre    => T = Null_Term or else Is_Allocated (T),
          Post   => (if not Success then Result = Null_Term
                     elsif Result /= Null_Term then Is_Allocated (Result));

private
   type Term_Slot is record
      Kind  : Term_Kind := Is_Constant;
      Name  : Character := ' ';
      Left  : Term_Id   := Null_Term;
      Right : Term_Id   := Null_Term;
   end record;

   type Pool_Array is array (Allocated_Id) of Term_Slot;

   Pool  : Pool_Array := [others => (Kind => Is_Constant, Name => ' ',
                                     Left => Null_Term, Right => Null_Term)]
     with Part_Of => Term_Pool;
   Count : Term_Id := 0
     with Part_Of => Term_Pool;

end Unification_Engine;
