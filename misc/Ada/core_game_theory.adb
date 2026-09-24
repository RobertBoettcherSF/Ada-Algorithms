--  Core_Game_Theory body — membership tests, excesses, special games.

pragma Ada_2022;

package body Core_Game_Theory
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

   procedure Require_Allocation (N : Natural; X : Allocation) is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if X'First /= 1 or else Natural (X'Last) /= N then
         raise Invalid_Argument;
      end if;
   end Require_Allocation;

   procedure Require_Tol (Tol : Worth) is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
   end Require_Tol;

   ---------------------------------------------------------------------------
   -- Sums
   ---------------------------------------------------------------------------

   function Sum_Allocation (X : Allocation) return Worth is
      S : Worth := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I);
      end loop;
      return S;
   end Sum_Allocation;

   function Coalition_Payoff
     (X : Allocation; Mask : Natural) return Worth
   is
      S   : Worth := 0.0;
      M   : Natural := Mask;
      Bit : Natural := 1;
      I   : Natural := 1;
   begin
      if X'First /= 1 then
         raise Invalid_Argument;
      end if;
      while M > 0 loop
         if M mod 2 = 1 then
            if I < Natural (X'First) or else I > Natural (X'Last) then
               raise Invalid_Argument;
            end if;
            S := S + X (Player_Id (I));
         end if;
         M := M / 2;
         Bit := Bit * 2;
         I := I + 1;
      end loop;
      pragma Unreferenced (Bit);
      return S;
   end Coalition_Payoff;

   ---------------------------------------------------------------------------
   -- Efficiency / IR / imputation
   ---------------------------------------------------------------------------

   function Is_Efficient
     (X     : Allocation;
      Grand : Worth;
      Tol   : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Tol (Tol);
      return Near (Sum_Allocation (X), Grand, Tol);
   end Is_Efficient;

   function Is_Individually_Rational
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      Require_Tol (Tol);
      for I in 1 .. Player_Id (N) loop
         if X (I) + Tol < V (Player_Bit (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Individually_Rational;

   function Is_Imputation
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      Require_Tol (Tol);
      if not Near (Sum_Allocation (X), V (Power2 (N) - 1), Tol) then
         return False;
      end if;
      for I in 1 .. Player_Id (N) loop
         if X (I) + Tol < V (Player_Bit (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Imputation;

   ---------------------------------------------------------------------------
   -- Excess / blocks / core
   ---------------------------------------------------------------------------

   function Coalition_Excess
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural) return Worth
   is
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      if Mask > Power2 (N) - 1 then
         raise Invalid_Argument;
      end if;
      return V (Mask) - Coalition_Payoff (X, Mask);
   end Coalition_Excess;

   function Blocks
     (N    : Natural;
      V    : Characteristic;
      X    : Allocation;
      Mask : Natural;
      Tol  : Worth := Default_Tol) return Boolean
   is
   begin
      Require_Tol (Tol);
      --  Empty coalition never blocks under v(∅)=0 convention.
      if Mask = 0 then
         return False;
      end if;
      --  Grand coalition cannot "leave" itself.
      if Mask = Power2 (N) - 1 then
         return False;
      end if;
      return Coalition_Excess (N, V, X, Mask) > Tol;
   end Blocks;

   function Is_In_Core
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Boolean
   is
      All_M : Natural;
   begin
      if not Is_Imputation (N, V, X, Tol) then
         return False;
      end if;
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         if Coalition_Excess (N, V, X, Mask) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_In_Core;

   function Max_Excess
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation) return Worth
   is
      All_M : Natural;
      Best  : Worth;
      E     : Worth;
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      All_M := Power2 (N) - 1;
      Best  := Coalition_Excess (N, V, X, 0);
      for Mask in 1 .. All_M loop
         E := Coalition_Excess (N, V, X, Mask);
         if E > Best then
            Best := E;
         end if;
      end loop;
      return Best;
   end Max_Excess;

   function Worst_Coalition
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation) return Natural
   is
      All_M : Natural;
      Best  : Worth;
      E     : Worth;
      Worst : Natural := 0;
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      All_M := Power2 (N) - 1;
      Best  := Coalition_Excess (N, V, X, 0);
      for Mask in 1 .. All_M loop
         E := Coalition_Excess (N, V, X, Mask);
         if E > Best then
            Best  := E;
            Worst := Mask;
         end if;
      end loop;
      return Worst;
   end Worst_Coalition;

   function Count_Blocking
     (N   : Natural;
      V   : Characteristic;
      X   : Allocation;
      Tol : Worth := Default_Tol) return Natural
   is
      All_M : Natural;
      C     : Natural := 0;
   begin
      Require_Table (N, V);
      Require_Allocation (N, X);
      Require_Tol (Tol);
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         if Blocks (N, V, X, Mask, Tol) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_Blocking;

   ---------------------------------------------------------------------------
   -- Special-game constructors
   ---------------------------------------------------------------------------

   function Make_Additive (Singleton : Allocation) return Characteristic is
      N    : constant Natural := Natural (Singleton'Length);
      All_M : Natural;
      V    : Characteristic (0 .. Power2 (N) - 1);
      S    : Worth;
   begin
      if Singleton'First /= 1 or else N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         S := 0.0;
         for I in 1 .. Player_Id (N) loop
            if Has_Player (Mask, I) then
               S := S + Singleton (I);
            end if;
         end loop;
         V (Mask) := S;
      end loop;
      return V;
   end Make_Additive;

   function Make_Gloves return Characteristic is
      V : Characteristic (0 .. 7) := [others => 0.0];
   begin
      --  masks: 1={1}, 2={2}, 4={3}, 5={1,3}, 6={2,3}, 7={1,2,3}
      V (5) := 1.0;
      V (6) := 1.0;
      V (7) := 1.0;
      return V;
   end Make_Gloves;

   function Make_Pair_Gloves return Characteristic is
      V : Characteristic (0 .. 3) := [others => 0.0];
   begin
      V (1) := 5.0;
      V (2) := 5.0;
      V (3) := 15.0;
      return V;
   end Make_Pair_Gloves;

   function Make_Miners (N : Natural) return Characteristic is
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
      Sz    : Natural;
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      for Mask in 0 .. All_M loop
         Sz := Bit_Count (Mask);
         V (Mask) := Worth (Sz / 2);  --  floor via integer division
      end loop;
      return V;
   end Make_Miners;

   function Make_Majority (N : Natural) return Characteristic is
      All_M : Natural;
      Need  : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1);
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      Need  := N / 2 + 1;  --  strict majority
      for Mask in 0 .. All_M loop
         if Bit_Count (Mask) >= Need then
            V (Mask) := 1.0;
         else
            V (Mask) := 0.0;
         end if;
      end loop;
      return V;
   end Make_Majority;

   function Make_Unanimity (N : Natural) return Characteristic is
      All_M : Natural;
      V     : Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      All_M := Power2 (N) - 1;
      V (All_M) := 1.0;
      return V;
   end Make_Unanimity;

   function Make_Zero (N : Natural) return Characteristic is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      declare
         V : constant Characteristic (0 .. Power2 (N) - 1) := [others => 0.0];
      begin
         return V;
      end;
   end Make_Zero;

   ---------------------------------------------------------------------------
   -- LP-free core points
   ---------------------------------------------------------------------------

   function Additive_Core_Point (Singleton : Allocation) return Allocation is
   begin
      if Singleton'First /= 1
        or else Singleton'Length = 0
        or else Singleton'Length > Max_N
      then
         raise Invalid_Argument;
      end if;
      return Singleton;
   end Additive_Core_Point;

   function Gloves_Core_Point return Allocation is
   begin
      return Allocation'[1 => 0.0, 2 => 0.0, 3 => 1.0];
   end Gloves_Core_Point;

   function Pair_Gloves_Core_Point
     (Share_1 : Worth := 7.5) return Allocation
   is
   begin
      if Share_1 < 5.0 or else Share_1 > 10.0 then
         raise Invalid_Argument;
      end if;
      return Allocation'[1 => Share_1, 2 => 15.0 - Share_1];
   end Pair_Gloves_Core_Point;

   function Miners_Core_Point (N : Natural) return Allocation is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      if N mod 2 = 1 then
         raise Invalid_Argument;  --  empty core
      end if;
      declare
         X : constant Allocation (1 .. Player_Id (N)) := [others => 0.5];
      begin
         return X;
      end;
   end Miners_Core_Point;

   function Unanimity_Equal_Point (N : Natural) return Allocation is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      declare
         S : constant Worth := 1.0 / Worth (N);
         X : constant Allocation (1 .. Player_Id (N)) := [others => S];
      begin
         return X;
      end;
   end Unanimity_Equal_Point;

   function Equal_Surplus_Allocation
     (N : Natural; V : Characteristic) return Allocation
   is
   begin
      Require_Table (N, V);
      declare
         X       : Allocation (1 .. Player_Id (N));
         Solo    : Worth := 0.0;
         Surplus : Worth;
      begin
         for I in 1 .. Player_Id (N) loop
            X (I) := V (Player_Bit (I));
            Solo := Solo + X (I);
         end loop;
         Surplus := V (Power2 (N) - 1) - Solo;
         for I in X'Range loop
            X (I) := X (I) + Surplus / Worth (N);
         end loop;
         return X;
      end;
   end Equal_Surplus_Allocation;

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

   function Grand_Worth (Inst : Instance) return Worth is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Inst.V (Power2 (Natural (Inst.N)) - 1);
   end Grand_Worth;

   function Is_Imputation
     (Inst : Instance;
      X    : Allocation;
      Tol  : Worth := Default_Tol) return Boolean
   is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Is_Imputation
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         X,
         Tol);
   end Is_Imputation;

   function Is_In_Core
     (Inst : Instance;
      X    : Allocation;
      Tol  : Worth := Default_Tol) return Boolean
   is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Is_In_Core
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         X,
         Tol);
   end Is_In_Core;

   function Coalition_Excess
     (Inst : Instance;
      X    : Allocation;
      Mask : Natural) return Worth
   is
   begin
      if Inst.N = 0 then
         raise Invalid_Argument;
      end if;
      return Coalition_Excess
        (Natural (Inst.N),
         Inst.V (0 .. Power2 (Natural (Inst.N)) - 1),
         X,
         Mask);
   end Coalition_Excess;

end Core_Game_Theory;
