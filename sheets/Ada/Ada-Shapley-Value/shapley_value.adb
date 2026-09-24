--  Shapley_Value body — coalition-sum and permutation implementations.

pragma Ada_2022;

package body Shapley_Value
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Near
   ---------------------------------------------------------------------------

   function Near
     (A, B : Worth; Tol : Worth := Default_Tol) return Boolean
   is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
      return abs (A - B) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Bitmask helpers
   ---------------------------------------------------------------------------

   function Player_Bit (I : Player_Id) return Natural is
   begin
      return 2 ** (Natural (I) - 1);
   end Player_Bit;

   function Bit_Count (Mask : Natural) return Natural is
      M : Natural := Mask;
      C : Natural := 0;
   begin
      while M > 0 loop
         C := C + (M mod 2);
         M := M / 2;
      end loop;
      return C;
   end Bit_Count;

   function Has_Player (Mask : Natural; I : Player_Id) return Boolean is
   begin
      return (Mask / Player_Bit (I)) mod 2 = 1;
   end Has_Player;

   function Power2 (N : Natural) return Natural is
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      return 2 ** N;
   end Power2;

   ---------------------------------------------------------------------------
   -- Factorial / binomial / Shapley weight
   ---------------------------------------------------------------------------

   function Factorial (K : Natural) return Worth is
      R : Worth := 1.0;
   begin
      if K > 20 then
         raise Invalid_Argument;
      end if;
      for I in 2 .. K loop
         R := R * Worth (I);
      end loop;
      return R;
   end Factorial;

   function Binomial (N, K : Natural) return Worth is
      KK : Natural;
      R  : Worth := 1.0;
   begin
      if K > N then
         return 0.0;
      end if;
      KK := K;
      if KK > N - KK then
         KK := N - KK;
      end if;
      for I in 1 .. KK loop
         R := R * Worth (N - KK + I) / Worth (I);
      end loop;
      return R;
   end Binomial;

   function Shapley_Weight
     (Coalition_Size : Natural; N : Natural) return Worth
   is
   begin
      if N = 0 or else N > Max_N or else Coalition_Size >= N then
         raise Invalid_Argument;
      end if;
      return Factorial (Coalition_Size)
        * Factorial (N - Coalition_Size - 1)
        / Factorial (N);
   end Shapley_Weight;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Table (N : Natural; V : Characteristic) is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if V'First /= 0 or else V'Length /= Power2 (N) then
         raise Invalid_Argument;
      end if;
   end Require_Table;

   procedure Require_Player (N : Natural; I : Player_Id) is
   begin
      if N = 0 or else Natural (I) > N then
         raise Invalid_Argument;
      end if;
   end Require_Player;

   ---------------------------------------------------------------------------
   -- Marginal
   ---------------------------------------------------------------------------

   function Marginal
     (V      : Characteristic;
      S_Mask : Natural;
      I      : Player_Id) return Worth
   is
      Bit : constant Natural := Player_Bit (I);
      S_I : Natural;
   begin
      if V'First /= 0 then
         raise Invalid_Argument;
      end if;
      if S_Mask > V'Last or else (S_Mask / Bit) mod 2 = 1 then
         raise Invalid_Argument;
      end if;
      S_I := S_Mask + Bit;
      if S_I > V'Last then
         raise Invalid_Argument;
      end if;
      return V (S_I) - V (S_Mask);
   end Marginal;

   function Marginal
     (V      : access function (Mask : Natural) return Worth;
      S_Mask : Natural;
      I      : Player_Id) return Worth
   is
      Bit : constant Natural := Player_Bit (I);
   begin
      if V = null then
         raise Invalid_Argument;
      end if;
      if (S_Mask / Bit) mod 2 = 1 then
         raise Invalid_Argument;
      end if;
      return V (S_Mask + Bit) - V (S_Mask);
   end Marginal;

   ---------------------------------------------------------------------------
   -- Coalition-sum Compute
   ---------------------------------------------------------------------------

   function Compute
     (N : Natural; V : Characteristic) return Value_Vector
   is
   begin
      Require_Table (N, V);
      declare
         Phi   : Value_Vector (1 .. Player_Id (N)) := [others => 0.0];
         All_M : constant Natural := Power2 (N) - 1;
         Bit   : Natural;
         S     : Natural;
         W     : Worth;
      begin
         for I in 1 .. Player_Id (N) loop
            Bit := Player_Bit (I);
            for Raw in 0 .. All_M loop
               if (Raw / Bit) mod 2 = 0 then
                  S := Raw;
                  W := Shapley_Weight (Bit_Count (S), N);
                  Phi (I) := Phi (I) + W * (V (S + Bit) - V (S));
               end if;
            end loop;
         end loop;
         return Phi;
      end;
   end Compute;

   function Compute
     (N : Natural;
      V : access function (Mask : Natural) return Worth) return Value_Vector
   is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if V = null then
         raise Invalid_Argument;
      end if;
      declare
         Phi   : Value_Vector (1 .. Player_Id (N)) := [others => 0.0];
         All_M : constant Natural := Power2 (N) - 1;
         Bit   : Natural;
         S     : Natural;
         W     : Worth;
      begin
         for I in 1 .. Player_Id (N) loop
            Bit := Player_Bit (I);
            for Raw in 0 .. All_M loop
               if (Raw / Bit) mod 2 = 0 then
                  S := Raw;
                  W := Shapley_Weight (Bit_Count (S), N);
                  Phi (I) := Phi (I) + W * (V (S + Bit) - V (S));
               end if;
            end loop;
         end loop;
         return Phi;
      end;
   end Compute;

   ---------------------------------------------------------------------------
   -- Permutation enumeration (Heap's algorithm)
   ---------------------------------------------------------------------------

   procedure Accumulate_Permutations
     (N    : Natural;
      Acc  : in out Value_Vector;
      Eval : access function (Mask : Natural) return Worth)
   is
      Order : array (1 .. Max_Perm_N) of Player_Id;
      Mask  : Natural;
      Prev  : Natural;
      Bit   : Natural;
      Tmp   : Player_Id;

      procedure Recurse (K : Natural) is
      begin
         if K = 1 then
            Mask := 0;
            for Pos in 1 .. N loop
               Bit  := Player_Bit (Order (Pos));
               Prev := Mask;
               Mask := Mask + Bit;
               Acc (Order (Pos)) :=
                 Acc (Order (Pos)) + (Eval (Mask) - Eval (Prev));
            end loop;
            return;
         end if;
         Recurse (K - 1);
         for I in 1 .. K - 1 loop
            if K mod 2 = 0 then
               Tmp       := Order (I);
               Order (I) := Order (K);
               Order (K) := Tmp;
            else
               Tmp       := Order (1);
               Order (1) := Order (K);
               Order (K) := Tmp;
            end if;
            Recurse (K - 1);
         end loop;
      end Recurse;

   begin
      for I in 1 .. Player_Id (N) loop
         Order (Natural (I)) := I;
      end loop;
      Recurse (N);
   end Accumulate_Permutations;

   function Compute_By_Permutations
     (N : Natural; V : Characteristic) return Value_Vector
   is
      function Eval (Mask : Natural) return Worth is
      begin
         return V (Mask);
      end Eval;
   begin
      if N = 0 or else N > Max_Perm_N then
         raise Invalid_Argument;
      end if;
      Require_Table (N, V);
      declare
         Acc : Value_Vector (1 .. Player_Id (N)) := [others => 0.0];
         Fac : constant Worth := Factorial (N);
      begin
         Accumulate_Permutations (N, Acc, Eval'Access);
         for I in Acc'Range loop
            Acc (I) := Acc (I) / Fac;
         end loop;
         return Acc;
      end;
   end Compute_By_Permutations;

   function Compute_By_Permutations
     (N : Natural;
      V : access function (Mask : Natural) return Worth) return Value_Vector
   is
   begin
      if N = 0 or else N > Max_Perm_N then
         raise Invalid_Argument;
      end if;
      if V = null then
         raise Invalid_Argument;
      end if;
      declare
         Acc : Value_Vector (1 .. Player_Id (N)) := [others => 0.0];
         Fac : constant Worth := Factorial (N);
      begin
         Accumulate_Permutations (N, Acc, V);
         for I in Acc'Range loop
            Acc (I) := Acc (I) / Fac;
         end loop;
         return Acc;
      end;
   end Compute_By_Permutations;

   ---------------------------------------------------------------------------
   -- Efficiency / axiom helpers
   ---------------------------------------------------------------------------

   function Sum_Values (Phi : Value_Vector) return Worth is
      S : Worth := 0.0;
   begin
      for I in Phi'Range loop
         S := S + Phi (I);
      end loop;
      return S;
   end Sum_Values;

   function Is_Efficient
     (Phi   : Value_Vector;
      Grand : Worth;
      Tol   : Worth := Default_Tol) return Boolean
   is
   begin
      return Near (Sum_Values (Phi), Grand, Tol);
   end Is_Efficient;

   function Is_Dummy
     (N : Natural;
      V : Characteristic;
      I : Player_Id;
      Tol : Worth := Default_Tol) return Boolean
   is
      Bit   : Natural;
      All_M : Natural;
      S     : Natural;
   begin
      Require_Table (N, V);
      Require_Player (N, I);
      Bit   := Player_Bit (I);
      All_M := Power2 (N) - 1;
      for Raw in 0 .. All_M loop
         if (Raw / Bit) mod 2 = 0 then
            S := Raw;
            if not Near (V (S + Bit) - V (S), 0.0, Tol) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Dummy;

   function Are_Symmetric
     (N : Natural;
      V : Characteristic;
      I, J : Player_Id;
      Tol : Worth := Default_Tol) return Boolean
   is
      Bi, Bj : Natural;
      All_M  : Natural;
      S      : Natural;
   begin
      Require_Table (N, V);
      Require_Player (N, I);
      Require_Player (N, J);
      if I = J then
         return True;
      end if;
      Bi    := Player_Bit (I);
      Bj    := Player_Bit (J);
      All_M := Power2 (N) - 1;
      for Raw in 0 .. All_M loop
         if (Raw / Bi) mod 2 = 0 and then (Raw / Bj) mod 2 = 0 then
            S := Raw;
            if not Near (V (S + Bi) - V (S), V (S + Bj) - V (S), Tol) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Are_Symmetric;

   ---------------------------------------------------------------------------
   -- Instance
   ---------------------------------------------------------------------------

   procedure Clear (Inst : in out Instance; Size : Natural) is
   begin
      if Size > Max_N then
         raise Invalid_Argument;
      end if;
      Inst.N := Player_Count (Size);
      Inst.V := [others => 0.0];
   end Clear;

   function Size (Inst : Instance) return Player_Count is
   begin
      return Inst.N;
   end Size;

   procedure Set_Worth
     (Inst : in out Instance; Mask : Natural; W : Worth)
   is
   begin
      if Inst.N = 0 or else Mask >= Power2 (Natural (Inst.N)) then
         raise Invalid_Argument;
      end if;
      Inst.V (Mask) := W;
   end Set_Worth;

   function Get_Worth (Inst : Instance; Mask : Natural) return Worth is
   begin
      if Inst.N = 0 or else Mask >= Power2 (Natural (Inst.N)) then
         raise Invalid_Argument;
      end if;
      return Inst.V (Mask);
   end Get_Worth;

   procedure Load (Inst : in out Instance; V : Characteristic) is
      Len : constant Natural := V'Length;
      N   : Natural := 0;
      P   : Natural := 1;
   begin
      if V'First /= 0 or else Len = 0 then
         raise Invalid_Argument;
      end if;
      while P < Len loop
         N := N + 1;
         if N > Max_N then
            raise Invalid_Argument;
         end if;
         P := P * 2;
      end loop;
      if P /= Len then
         raise Invalid_Argument;
      end if;
      Clear (Inst, N);
      for M in 0 .. Len - 1 loop
         Inst.V (M) := V (M);
      end loop;
   end Load;

   function Compute (Inst : Instance) return Value_Vector is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Compute
        (Natural (Inst.N), Inst.V (0 .. Power2 (Natural (Inst.N)) - 1));
   end Compute;

   function Compute_By_Permutations (Inst : Instance) return Value_Vector is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Compute_By_Permutations
        (Natural (Inst.N), Inst.V (0 .. Power2 (Natural (Inst.N)) - 1));
   end Compute_By_Permutations;

   function Grand_Worth (Inst : Instance) return Worth is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Inst.V (Power2 (Natural (Inst.N)) - 1);
   end Grand_Worth;

end Shapley_Value;
