package Abstract_Interpretation is
   pragma Pure;

   -- =========================================================================
   -- 1. Sign Abstract Domain
   -- Represents abstractions of integer signs as a powerset lattice of {-, 0, +}
   -- =========================================================================
   
   type Sign_Set is array (1 .. 3) of Boolean;
   -- Index 1: Has Negative
   -- Index 2: Has Zero
   -- Index 3: Has Positive
   
   subtype Sign_Domain is Sign_Set;

   Bottom_Sign   : constant Sign_Domain := [False, False, False];
   Neg_Sign      : constant Sign_Domain := [True,  False, False];
   Zero_Sign     : constant Sign_Domain := [False, True,  False];
   Pos_Sign      : constant Sign_Domain := [False, False, True];
   Non_Pos_Sign  : constant Sign_Domain := [True,  True,  False];
   Non_Neg_Sign  : constant Sign_Domain := [False, True,  True];
   Non_Zero_Sign : constant Sign_Domain := [True,  False, True];
   Top_Sign      : constant Sign_Domain := [True,  True,  True];

   function Sign_Join (A, B : Sign_Domain) return Sign_Domain
     with Global => null;
     
   function Sign_Meet (A, B : Sign_Domain) return Sign_Domain
     with Global => null;
     
   function Sign_Add (A, B : Sign_Domain) return Sign_Domain
     with Global => null;
     
   function Sign_Multiply (A, B : Sign_Domain) return Sign_Domain
     with Global => null;

   -- =========================================================================
   -- 2. Interval Abstract Domain
   -- Represents numerical invariants as boundaries [Lower, Upper]
   -- =========================================================================
   
   type Bound_Kind is (Minus_Inf, Finite, Plus_Inf);
   
   type Bound_Value (Kind : Bound_Kind := Finite) is record
      case Kind is
         when Finite =>
            Value : Integer;
         when others =>
            null;
      end case;
   end record;

   Invalid_Interval_Error : exception;

   type Interval_Domain is private;

   function Make_Bound (Val : Integer) return Bound_Value
     with Global => null;
     
   function Bound_Less_Or_Equal (A, B : Bound_Value) return Boolean
     with Global => null;

   function Make_Interval (Lower, Upper : Bound_Value) return Interval_Domain
     with Global => null;
   -- Raises Invalid_Interval_Error if Lower > Upper

   function Bottom_Interval return Interval_Domain
     with Global => null;
     
   function Top_Interval return Interval_Domain
     with Global => null;

   function Is_Bottom (I : Interval_Domain) return Boolean
     with Global => null;

   function Get_Lower (I : Interval_Domain) return Bound_Value
     with Pre => not Is_Bottom (I),
          Global => null;
          
   function Get_Upper (I : Interval_Domain) return Bound_Value
     with Pre => not Is_Bottom (I),
          Global => null;

   function Interval_Join (A, B : Interval_Domain) return Interval_Domain
     with Global => null;
     
   function Interval_Meet (A, B : Interval_Domain) return Interval_Domain
     with Global => null;
     
   function Interval_Add (A, B : Interval_Domain) return Interval_Domain
     with Global => null;
     
   function Interval_Multiply (A, B : Interval_Domain) return Interval_Domain
     with Global => null;
     
   function Interval_Widen (A, B : Interval_Domain) return Interval_Domain
     with Global => null;
     -- Widen is applied during loop iterations to ensure convergence

private

   type Interval_Domain is record
      Is_Empty : Boolean := True;
      Lower    : Bound_Value := (Kind => Minus_Inf);
      Upper    : Bound_Value := (Kind => Plus_Inf);
   end record;

end Abstract_Interpretation;
