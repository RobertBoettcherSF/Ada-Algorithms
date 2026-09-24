package body Abstract_Interpretation is

   -- =========================================================================
   -- Sign Abstract Domain Implementation
   -- =========================================================================

   function Sign_Join (A, B : Sign_Domain) return Sign_Domain is
   begin
      return [A (1) or B (1), A (2) or B (2), A (3) or B (3)];
   end Sign_Join;

   function Sign_Meet (A, B : Sign_Domain) return Sign_Domain is
   begin
      return [A (1) and B (1), A (2) and B (2), A (3) and B (3)];
   end Sign_Meet;

   function Sign_Add (A, B : Sign_Domain) return Sign_Domain is
      Result : Sign_Domain := Bottom_Sign;
   begin
      -- Cartesian product over the abstract values
      if A (1) and B (1) then Result (1) := True; end if; -- Neg + Neg = Neg
      if A (1) and B (2) then Result (1) := True; end if; -- Neg + Zero = Neg
      if A (2) and B (1) then Result (1) := True; end if; -- Zero + Neg = Neg
      if A (2) and B (2) then Result (2) := True; end if; -- Zero + Zero = Zero
      if A (3) and B (3) then Result (3) := True; end if; -- Pos + Pos = Pos
      if A (3) and B (2) then Result (3) := True; end if; -- Pos + Zero = Pos
      if A (2) and B (3) then Result (3) := True; end if; -- Zero + Pos = Pos
      
      if A (1) and B (3) then 
         Result := Top_Sign; 
      end if; -- Neg + Pos = Top
      
      if A (3) and B (1) then 
         Result := Top_Sign; 
      end if; -- Pos + Neg = Top
      
      return Result;
   end Sign_Add;

   function Sign_Multiply (A, B : Sign_Domain) return Sign_Domain is
      Result : Sign_Domain := Bottom_Sign;
   begin
      if (A (2) and then (B (1) or B (2) or B (3))) or else 
         (B (2) and then (A (1) or A (2) or A (3))) 
      then
         Result (2) := True; -- Zero * Anything = Zero
      end if;
      
      if A (1) and B (1) then Result (3) := True; end if; -- Neg * Neg = Pos
      if A (1) and B (3) then Result (1) := True; end if; -- Neg * Pos = Neg
      if A (3) and B (1) then Result (1) := True; end if; -- Pos * Neg = Neg
      if A (3) and B (3) then Result (3) := True; end if; -- Pos * Pos = Pos
      
      return Result;
   end Sign_Multiply;

   -- =========================================================================
   -- Bound Arithmetic Helpers
   -- =========================================================================

   function Make_Bound (Val : Integer) return Bound_Value is
   begin
      return (Kind => Finite, Value => Val);
   end Make_Bound;

   function Bound_Less_Or_Equal (A, B : Bound_Value) return Boolean is
   begin
      if A.Kind = Minus_Inf then return True; end if;
      if B.Kind = Plus_Inf then return True; end if;
      if A.Kind = Plus_Inf and then B.Kind /= Plus_Inf then return False; end if;
      if B.Kind = Minus_Inf and then A.Kind /= Minus_Inf then return False; end if;
      
      -- Both must be Finite here
      return A.Value <= B.Value;
   end Bound_Less_Or_Equal;

   function Bound_Min (A, B : Bound_Value) return Bound_Value is
   begin
      if Bound_Less_Or_Equal (A, B) then 
         return A; 
      else 
         return B; 
      end if;
   end Bound_Min;

   function Bound_Max (A, B : Bound_Value) return Bound_Value is
   begin
      if Bound_Less_Or_Equal (A, B) then 
         return B; 
      else 
         return A; 
      end if;
   end Bound_Max;

   function Bound_Add (A, B : Bound_Value) return Bound_Value is
   begin
      if A.Kind = Minus_Inf or else B.Kind = Minus_Inf then 
         return (Kind => Minus_Inf); 
      end if;
      
      if A.Kind = Plus_Inf or else B.Kind = Plus_Inf then 
         return (Kind => Plus_Inf); 
      end if;
      
      return (Kind => Finite, Value => A.Value + B.Value);
   end Bound_Add;

   function Bound_Multiply (A, B : Bound_Value) return Bound_Value is
      function Sign (V : Bound_Value) return Integer is
      begin
         if V.Kind = Minus_Inf then return -1; end if;
         if V.Kind = Plus_Inf then return 1; end if;
         if V.Value < 0 then return -1; end if;
         if V.Value > 0 then return 1; end if;
         return 0;
      end Sign;

      Sign_A : constant Integer := Sign (A);
      Sign_B : constant Integer := Sign (B);
      Res_Sign : constant Integer := Sign_A * Sign_B;
   begin
      if Res_Sign = 0 then 
         return (Kind => Finite, Value => 0); 
      end if;
      
      if A.Kind = Finite and then B.Kind = Finite then
         return (Kind => Finite, Value => A.Value * B.Value);
      end if;
      
      if Res_Sign > 0 then 
         return (Kind => Plus_Inf); 
      end if;
      
      return (Kind => Minus_Inf);
   end Bound_Multiply;

   -- =========================================================================
   -- Interval Abstract Domain Implementation
   -- =========================================================================

   function Make_Interval (Lower, Upper : Bound_Value) return Interval_Domain is
   begin
      if not Bound_Less_Or_Equal (Lower, Upper) then
         raise Invalid_Interval_Error;
      end if;
      return (Is_Empty => False, Lower => Lower, Upper => Upper);
   end Make_Interval;

   function Bottom_Interval return Interval_Domain is
   begin
      return (Is_Empty => True, Lower => (Kind => Minus_Inf), Upper => (Kind => Plus_Inf));
   end Bottom_Interval;

   function Top_Interval return Interval_Domain is
   begin
      return (Is_Empty => False, Lower => (Kind => Minus_Inf), Upper => (Kind => Plus_Inf));
   end Top_Interval;

   function Is_Bottom (I : Interval_Domain) return Boolean is
   begin
      return I.Is_Empty;
   end Is_Bottom;

   function Get_Lower (I : Interval_Domain) return Bound_Value is (I.Lower);
   function Get_Upper (I : Interval_Domain) return Bound_Value is (I.Upper);

   function Interval_Join (A, B : Interval_Domain) return Interval_Domain is
   begin
      if A.Is_Empty then return B; end if;
      if B.Is_Empty then return A; end if;
      return Make_Interval (Bound_Min (A.Lower, B.Lower), Bound_Max (A.Upper, B.Upper));
   end Interval_Join;

   function Interval_Meet (A, B : Interval_Domain) return Interval_Domain is
      Max_Lower, Min_Upper : Bound_Value;
   begin
      if A.Is_Empty or else B.Is_Empty then 
         return Bottom_Interval; 
      end if;
      
      Max_Lower := Bound_Max (A.Lower, B.Lower);
      Min_Upper := Bound_Min (A.Upper, B.Upper);
      
      if Bound_Less_Or_Equal (Max_Lower, Min_Upper) then
         return Make_Interval (Max_Lower, Min_Upper);
      else
         return Bottom_Interval;
      end if;
   end Interval_Meet;

   function Interval_Add (A, B : Interval_Domain) return Interval_Domain is
   begin
      if A.Is_Empty or else B.Is_Empty then 
         return Bottom_Interval; 
      end if;
      
      return Make_Interval (Bound_Add (A.Lower, B.Lower), Bound_Add (A.Upper, B.Upper));
   end Interval_Add;

   function Interval_Multiply (A, B : Interval_Domain) return Interval_Domain is
      P1, P2, P3, P4, Min_P, Max_P : Bound_Value;
   begin
      if A.Is_Empty or else B.Is_Empty then 
         return Bottom_Interval; 
      end if;
      
      P1 := Bound_Multiply (A.Lower, B.Lower);
      P2 := Bound_Multiply (A.Lower, B.Upper);
      P3 := Bound_Multiply (A.Upper, B.Lower);
      P4 := Bound_Multiply (A.Upper, B.Upper);
      
      Min_P := Bound_Min (P1, Bound_Min (P2, Bound_Min (P3, P4)));
      Max_P := Bound_Max (P1, Bound_Max (P2, Bound_Max (P3, P4)));
      
      return Make_Interval (Min_P, Max_P);
   end Interval_Multiply;

   function Interval_Widen (A, B : Interval_Domain) return Interval_Domain is
      L, U : Bound_Value;
   begin
      if A.Is_Empty then return B; end if;
      if B.Is_Empty then return A; end if;
      
      -- If new lower bound is less than old lower bound, drop to minus infinity
      L := (if Bound_Less_Or_Equal (B.Lower, A.Lower) and then not Bound_Less_Or_Equal (A.Lower, B.Lower)
            then (Kind => Minus_Inf) 
            else A.Lower);
            
      -- If new upper bound is greater than old upper bound, go to plus infinity
      U := (if Bound_Less_Or_Equal (A.Upper, B.Upper) and then not Bound_Less_Or_Equal (B.Upper, A.Upper)
            then (Kind => Plus_Inf) 
            else A.Upper);
            
      return Make_Interval (L, U);
   end Interval_Widen;

end Abstract_Interpretation;
