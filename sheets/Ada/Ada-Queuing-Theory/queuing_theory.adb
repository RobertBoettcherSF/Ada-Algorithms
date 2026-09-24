--  Queuing_Theory body — classic single-node queueing formulas.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
with Ada.Strings.Unbounded;

package body Queuing_Theory
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;
   package U renames Ada.Strings.Unbounded;

   -----------------------------------------------------------------------
   -- Validation
   -----------------------------------------------------------------------

   procedure Require_Positive_Rates (Lambda, Mu : Real) is
   begin
      if Lambda < 0.0 then
         raise Invalid_Argument with "Lambda must be non-negative";
      end if;
      if Mu <= 0.0 then
         raise Invalid_Argument with "Mu must be strictly positive";
      end if;
   end Require_Positive_Rates;

   procedure Require_Strict_Positive_Arrival (Lambda : Real) is
   begin
      if Lambda <= 0.0 then
         raise Invalid_Argument with "Lambda must be strictly positive";
      end if;
   end Require_Strict_Positive_Arrival;

   procedure Require_Stable_MM1 (Lambda, Mu : Real) is
   begin
      Require_Positive_Rates (Lambda, Mu);
      Require_Strict_Positive_Arrival (Lambda);
      if Lambda >= Mu then
         raise Degenerate_Geometry
           with "M/M/1 unstable: Rho = Lambda/Mu >= 1";
      end if;
   end Require_Stable_MM1;

   procedure Require_Stable_MMc
     (Lambda : Real; Mu : Real; C : Server_Count)
   is
      Cap : constant Real := Real (C) * Mu;
   begin
      Require_Positive_Rates (Lambda, Mu);
      Require_Strict_Positive_Arrival (Lambda);
      if Lambda >= Cap then
         raise Degenerate_Geometry
           with "M/M/c unstable: Rho = Lambda/(c*Mu) >= 1";
      end if;
   end Require_Stable_MMc;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Power (Base : Real; Exp : Natural) return Real is
      R : Real := 1.0;
   begin
      for I in 1 .. Exp loop
         R := R * Base;
      end loop;
      return R;
   end Power;

   function Factorial_Real (N : Natural) return Real is
      R : Real := 1.0;
   begin
      if N > Max_Servers + 8 then
         raise Capacity_Exceeded with "Factorial_Real: N too large";
      end if;
      for I in 2 .. N loop
         R := R * Real (I);
      end loop;
      return R;
   end Factorial_Real;

   function Is_Stable_MM1 (Lambda, Mu : Real) return Boolean is
   begin
      return Lambda > 0.0 and then Mu > 0.0 and then Lambda < Mu;
   end Is_Stable_MM1;

   function Is_Stable_MMc
     (Lambda : Real; Mu : Real; C : Server_Count) return Boolean
   is
   begin
      return Lambda > 0.0
        and then Mu > 0.0
        and then Lambda < Real (C) * Mu;
   end Is_Stable_MMc;

   -----------------------------------------------------------------------
   -- Little's law
   -----------------------------------------------------------------------

   function Littles_L (Lambda, W : Real) return Real is
   begin
      if Lambda <= 0.0 then
         raise Invalid_Argument with "Littles_L: Lambda must be > 0";
      end if;
      if W < 0.0 then
         raise Invalid_Argument with "Littles_L: W must be >= 0";
      end if;
      return Lambda * W;
   end Littles_L;

   function Littles_W (L, Lambda : Real) return Real is
   begin
      if L < 0.0 then
         raise Invalid_Argument with "Littles_W: L must be >= 0";
      end if;
      if Lambda <= 0.0 then
         raise Invalid_Argument with "Littles_W: Lambda must be > 0";
      end if;
      return L / Lambda;
   end Littles_W;

   function Littles_Lambda (L, W : Real) return Real is
   begin
      if L < 0.0 then
         raise Invalid_Argument with "Littles_Lambda: L must be >= 0";
      end if;
      if W <= 0.0 then
         raise Invalid_Argument with "Littles_Lambda: W must be > 0";
      end if;
      return L / W;
   end Littles_Lambda;

   -----------------------------------------------------------------------
   -- Kendall notation
   -----------------------------------------------------------------------

   function Kind_Image (K : Arrival_Kind) return String is
   begin
      case K is
         when M  => return "M";
         when D  => return "D";
         when G  => return "G";
         when Ek => return "Ek";
      end case;
   end Kind_Image;

   function Kind_Image (K : Service_Kind) return String is
   begin
      case K is
         when M  => return "M";
         when D  => return "D";
         when G  => return "G";
         when Ek => return "Ek";
      end case;
   end Kind_Image;

   function Trim_Nat (N : Natural) return String is
      S : constant String := Natural'Image (N);
   begin
      --  Natural'Image has a leading space
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Trim_Nat;

   function Format_Kendall
     (A : String;
      S : String;
      C : Positive;
      K : Natural := 0;
      N : Natural := 0;
      D : String  := "") return String
   is
      use U;
      Buf : Unbounded_String;
   begin
      if A'Length = 0 or else S'Length = 0 then
         raise Invalid_Argument with "Format_Kendall: empty A or S";
      end if;
      Buf := To_Unbounded_String (A & "/" & S & "/" & Trim_Nat (C));
      if K > 0 then
         Append (Buf, "/" & Trim_Nat (K));
         if N > 0 then
            Append (Buf, "/" & Trim_Nat (N));
            if D'Length > 0 then
               Append (Buf, "/" & D);
            end if;
         elsif D'Length > 0 then
            --  Skip empty population but still allow discipline after K:
            --  educational: A/S/c/K//D is unusual; require N if D given
            --  after K without N — append D only when N was given above.
            null;
         end if;
      end if;
      return To_String (Buf);
   end Format_Kendall;

   function Format_Kendall
     (Arr : Arrival_Kind;
      Srv : Service_Kind;
      C   : Positive;
      K   : Natural := 0;
      N   : Natural := 0) return String
   is
   begin
      return Format_Kendall
        (Kind_Image (Arr), Kind_Image (Srv), C, K, N, "");
   end Format_Kendall;

   function Parse_Kendall_Servers (Notation : String) return Natural is
      Slash_Count : Natural := 0;
      Field_Start : Natural := Notation'First;
   begin
      if Notation'Length = 0 then
         return 0;
      end if;
      for I in Notation'Range loop
         if Notation (I) = '/' then
            Slash_Count := Slash_Count + 1;
            if Slash_Count = 2 then
               Field_Start := I + 1;
            elsif Slash_Count = 3 then
               --  Field between 2nd and 3rd slash is c
               declare
                  F : constant String :=
                    Notation (Field_Start .. I - 1);
                  V : Natural;
               begin
                  begin
                     V := Natural'Value (F);
                     return V;
                  exception
                     when Constraint_Error =>
                        return 0;
                  end;
               end;
            end if;
         end if;
      end loop;
      --  No third slash: c is the trailing field after second slash
      if Slash_Count = 2 and then Field_Start <= Notation'Last then
         declare
            F : constant String := Notation (Field_Start .. Notation'Last);
            V : Natural;
         begin
            begin
               V := Natural'Value (F);
               return V;
            exception
               when Constraint_Error =>
                  return 0;
            end;
         end;
      end if;
      return 0;
   end Parse_Kendall_Servers;

   -----------------------------------------------------------------------
   -- Traffic intensity
   -----------------------------------------------------------------------

   function Rho
     (Lambda : Real;
      Mu     : Real;
      C      : Server_Count := 1) return Real
   is
   begin
      if Lambda < 0.0 then
         raise Invalid_Argument with "Rho: Lambda must be >= 0";
      end if;
      if Mu <= 0.0 then
         raise Invalid_Argument with "Rho: Mu must be > 0";
      end if;
      return Lambda / (Real (C) * Mu);
   end Rho;

   -----------------------------------------------------------------------
   -- M/M/1
   -----------------------------------------------------------------------

   function MM1_P0 (Lambda, Mu : Real) return Real is
      R : Real;
   begin
      Require_Stable_MM1 (Lambda, Mu);
      R := Lambda / Mu;
      return 1.0 - R;
   end MM1_P0;

   function MM1_Pn (Lambda, Mu : Real; N : Natural) return Real is
      R : Real;
   begin
      Require_Stable_MM1 (Lambda, Mu);
      R := Lambda / Mu;
      return (1.0 - R) * Power (R, N);
   end MM1_Pn;

   function MM1_L (Lambda, Mu : Real) return Real is
      R : Real;
   begin
      Require_Stable_MM1 (Lambda, Mu);
      R := Lambda / Mu;
      return R / (1.0 - R);
   end MM1_L;

   function MM1_Lq (Lambda, Mu : Real) return Real is
      R : Real;
   begin
      Require_Stable_MM1 (Lambda, Mu);
      R := Lambda / Mu;
      return (R * R) / (1.0 - R);
   end MM1_Lq;

   function MM1_W (Lambda, Mu : Real) return Real is
   begin
      Require_Stable_MM1 (Lambda, Mu);
      return 1.0 / (Mu - Lambda);
   end MM1_W;

   function MM1_Wq (Lambda, Mu : Real) return Real is
   begin
      Require_Stable_MM1 (Lambda, Mu);
      return Lambda / (Mu * (Mu - Lambda));
   end MM1_Wq;

   function MM1_Utilization (Lambda, Mu : Real) return Real is
   begin
      Require_Stable_MM1 (Lambda, Mu);
      return Lambda / Mu;
   end MM1_Utilization;

   function Analyze_MM1 (Lambda, Mu : Real) return MM1_Result is
      R : MM1_Result;
   begin
      Require_Stable_MM1 (Lambda, Mu);
      R.Rho         := Lambda / Mu;
      R.P0          := 1.0 - R.Rho;
      R.L           := R.Rho / (1.0 - R.Rho);
      R.Lq          := (R.Rho * R.Rho) / (1.0 - R.Rho);
      R.W           := 1.0 / (Mu - Lambda);
      R.Wq          := Lambda / (Mu * (Mu - Lambda));
      R.Utilization := R.Rho;
      return R;
   end Analyze_MM1;

   -----------------------------------------------------------------------
   -- M/M/c  (Erlang-C)
   -----------------------------------------------------------------------

   --  Compute P0 and Erlang-C together using iterative products a^k/k!.
   procedure MMc_Core
     (Lambda : Real;
      Mu     : Real;
      C      : Server_Count;
      P0     : out Real;
      EC     : out Real;
      A      : out Real;
      R      : out Real)
   is
      Sum   : Real := 0.0;
      Term  : Real := 1.0;  -- a^0 / 0!
      Last  : Real;
      Denom : Real;
   begin
      Require_Stable_MMc (Lambda, Mu, C);
      A := Lambda / Mu;
      R := Lambda / (Real (C) * Mu);
      --  Sum_{k=0}^{c-1} a^k / k!
      Sum := 1.0;
      Term := 1.0;
      for K in 1 .. C - 1 loop
         Term := Term * A / Real (K);
         Sum := Sum + Term;
      end loop;
      --  Last term for k = c: a^c / c!
      if C = 1 then
         Last := A;  -- a^1 / 1!
      else
         Last := Term * A / Real (C);
      end if;
      Denom := Sum + Last / (1.0 - R);
      if Denom <= 0.0 then
         raise Degenerate_Geometry with "M/M/c: non-positive normalizing denom";
      end if;
      P0 := 1.0 / Denom;
      EC := (Last / (1.0 - R)) * P0;
   end MMc_Core;

   function MMc_P0 (Lambda, Mu : Real; C : Server_Count) return Real is
      P0, EC, A, R : Real;
   begin
      MMc_Core (Lambda, Mu, C, P0, EC, A, R);
      return P0;
   end MMc_P0;

   function MMc_Erlang_C (Lambda, Mu : Real; C : Server_Count) return Real is
      P0, EC, A, R : Real;
   begin
      MMc_Core (Lambda, Mu, C, P0, EC, A, R);
      return EC;
   end MMc_Erlang_C;

   function MMc_Lq (Lambda, Mu : Real; C : Server_Count) return Real is
      P0, EC, A, R : Real;
   begin
      MMc_Core (Lambda, Mu, C, P0, EC, A, R);
      return EC * R / (1.0 - R);
   end MMc_Lq;

   function MMc_Wq (Lambda, Mu : Real; C : Server_Count) return Real is
      Lq : constant Real := MMc_Lq (Lambda, Mu, C);
   begin
      return Lq / Lambda;
   end MMc_Wq;

   function MMc_L (Lambda, Mu : Real; C : Server_Count) return Real is
      Lq : constant Real := MMc_Lq (Lambda, Mu, C);
      A  : constant Real := Lambda / Mu;
   begin
      return Lq + A;
   end MMc_L;

   function MMc_W (Lambda, Mu : Real; C : Server_Count) return Real is
      L : constant Real := MMc_L (Lambda, Mu, C);
   begin
      return L / Lambda;
   end MMc_W;

   function Analyze_MMc
     (Lambda : Real; Mu : Real; C : Server_Count) return MMc_Result
   is
      Res          : MMc_Result;
      P0, EC, A, R : Real;
   begin
      MMc_Core (Lambda, Mu, C, P0, EC, A, R);
      Res.Rho         := R;
      Res.A           := A;
      Res.P0          := P0;
      Res.Erlang_C    := EC;
      Res.Lq          := EC * R / (1.0 - R);
      Res.Wq          := Res.Lq / Lambda;
      Res.L           := Res.Lq + A;
      Res.W           := Res.L / Lambda;
      Res.Utilization := R;
      Res.Servers     := C;
      return Res;
   end Analyze_MMc;

   -----------------------------------------------------------------------
   -- M/M/1/K
   -----------------------------------------------------------------------

   procedure Require_MM1K_Rates (Lambda, Mu : Real) is
   begin
      Require_Positive_Rates (Lambda, Mu);
      if Lambda = 0.0 then
         raise Invalid_Argument with "MM1K: Lambda must be > 0";
      end if;
   end Require_MM1K_Rates;

   function MM1K_Pn
     (Lambda : Real; Mu : Real; K : Capacity_Count; N : Natural) return Real
   is
      R : Real;
   begin
      Require_MM1K_Rates (Lambda, Mu);
      if N > Natural (K) then
         raise Invalid_Argument with "MM1K_Pn: N exceeds capacity K";
      end if;
      R := Lambda / Mu;
      if Near (R, 1.0, 1.0E-12) then
         return 1.0 / Real (K + 1);
      else
         return (1.0 - R) * Power (R, N) / (1.0 - Power (R, K + 1));
      end if;
   end MM1K_Pn;

   function MM1K_P_Block
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
   begin
      return MM1K_Pn (Lambda, Mu, K, Natural (K));
   end MM1K_P_Block;

   function MM1K_Lambda_Eff
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
      PB : constant Real := MM1K_P_Block (Lambda, Mu, K);
   begin
      return Lambda * (1.0 - PB);
   end MM1K_Lambda_Eff;

   function MM1K_L
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
      R   : Real;
      Num : Real;
   begin
      Require_MM1K_Rates (Lambda, Mu);
      R := Lambda / Mu;
      if Near (R, 1.0, 1.0E-12) then
         return Real (K) / 2.0;
      end if;
      --  L = ρ/(1-ρ) − (K+1) ρ^{K+1} / (1 − ρ^{K+1})
      Num := R / (1.0 - R)
        - Real (K + 1) * Power (R, K + 1) / (1.0 - Power (R, K + 1));
      return Num;
   end MM1K_L;

   function MM1K_Lq
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
      L  : constant Real := MM1K_L (Lambda, Mu, K);
      P0 : constant Real := MM1K_Pn (Lambda, Mu, K, 0);
   begin
      --  Lq = L − (1 − P0)
      return L - (1.0 - P0);
   end MM1K_Lq;

   function MM1K_W
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
      L   : constant Real := MM1K_L (Lambda, Mu, K);
      Eff : constant Real := MM1K_Lambda_Eff (Lambda, Mu, K);
   begin
      if Eff <= 0.0 then
         raise Degenerate_Geometry with "MM1K_W: effective arrival rate is 0";
      end if;
      return L / Eff;
   end MM1K_W;

   function MM1K_Wq
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
   is
      Lq  : constant Real := MM1K_Lq (Lambda, Mu, K);
      Eff : constant Real := MM1K_Lambda_Eff (Lambda, Mu, K);
   begin
      if Eff <= 0.0 then
         raise Degenerate_Geometry with "MM1K_Wq: effective arrival rate is 0";
      end if;
      return Lq / Eff;
   end MM1K_Wq;

   function Analyze_MM1K
     (Lambda : Real; Mu : Real; K : Capacity_Count) return MM1K_Result
   is
      Res : MM1K_Result;
   begin
      Require_MM1K_Rates (Lambda, Mu);
      Res.Rho         := Lambda / Mu;
      Res.P0          := MM1K_Pn (Lambda, Mu, K, 0);
      Res.P_Block     := MM1K_Pn (Lambda, Mu, K, Natural (K));
      Res.Lambda_Eff  := Lambda * (1.0 - Res.P_Block);
      Res.L           := MM1K_L (Lambda, Mu, K);
      Res.Lq          := Res.L - (1.0 - Res.P0);
      if Res.Lambda_Eff > 0.0 then
         Res.W  := Res.L / Res.Lambda_Eff;
         Res.Wq := Res.Lq / Res.Lambda_Eff;
      else
         Res.W  := 0.0;
         Res.Wq := 0.0;
      end if;
      Res.Utilization := 1.0 - Res.P0;
      Res.Capacity    := K;
      return Res;
   end Analyze_MM1K;

   -----------------------------------------------------------------------
   -- M/M/∞
   -----------------------------------------------------------------------

   function MM_Inf_L (Lambda, Mu : Real) return Real is
   begin
      Require_Positive_Rates (Lambda, Mu);
      return Lambda / Mu;
   end MM_Inf_L;

   function MM_Inf_Pn (Lambda, Mu : Real; N : Natural) return Real is
      R   : Real;
      Exp : Real;
      Fac : Real := 1.0;
   begin
      Require_Positive_Rates (Lambda, Mu);
      if N > Max_State_N then
         raise Capacity_Exceeded with "MM_Inf_Pn: N too large";
      end if;
      R := Lambda / Mu;
      --  e^{-ρ} via Elementary_Functions (Float); cast carefully
      Exp := Real (EF.Exp (Float (-R)));
      for I in 1 .. N loop
         Fac := Fac * Real (I);
      end loop;
      return Exp * Power (R, N) / Fac;
   end MM_Inf_Pn;

   function MM_Inf_W (Lambda, Mu : Real) return Real is
   begin
      Require_Positive_Rates (Lambda, Mu);
      return 1.0 / Mu;
   end MM_Inf_W;

   function Analyze_MM_Inf (Lambda, Mu : Real) return MM_Inf_Result is
      Res : MM_Inf_Result;
   begin
      Require_Positive_Rates (Lambda, Mu);
      Res.Rho := Lambda / Mu;
      Res.L   := Res.Rho;
      Res.W   := 1.0 / Mu;
      return Res;
   end Analyze_MM_Inf;

   -----------------------------------------------------------------------
   -- Birth–death / local balance
   -----------------------------------------------------------------------

   function MM1_Local_Balance_Holds
     (Lambda, Mu : Real;
      N          : Positive;
      Tol        : Real := Epsilon_Tol) return Boolean
   is
      Pn, Pn1 : Real;
   begin
      if not Is_Stable_MM1 (Lambda, Mu) then
         return False;
      end if;
      Pn  := MM1_Pn (Lambda, Mu, N);
      Pn1 := MM1_Pn (Lambda, Mu, N - 1);
      return Near (Mu * Pn, Lambda * Pn1, Tol);
   end MM1_Local_Balance_Holds;

   function Birth_Death_Pn_Product
     (Lambda, Mu : Real; N : Natural) return Real
   is
   begin
      Require_Positive_Rates (Lambda, Mu);
      if Mu <= 0.0 then
         raise Invalid_Argument with "Birth_Death: Mu must be > 0";
      end if;
      return Power (Lambda / Mu, N);
   end Birth_Death_Pn_Product;

end Queuing_Theory;
