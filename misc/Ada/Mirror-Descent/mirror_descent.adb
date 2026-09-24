--  Mirror_Descent body.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Mirror_Descent is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   Entropy_Floor : constant Real := 1.0E-15;

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Is_Finite (X : Real) return Boolean is
     (X'Valid and then X > Real'First and then X < Real'Last);

   procedure Require_Initialized (S : State) is
   begin
      if not S.Initialized then
         raise Invalid_Argument with "state is not initialized";
      end if;
   end Require_Initialized;

   procedure Validate_Eta (Eta : Real) is
   begin
      if not Is_Finite (Eta) or else Eta <= 0.0 then
         raise Invalid_Argument
           with "learning rate η must be positive and finite";
      end if;
   end Validate_Eta;

   procedure Require_Length (X : Vector; D : Dimension; What : String) is
   begin
      if X'Length /= D then
         raise Invalid_Argument with What & " length must equal dimension";
      end if;
      if X'First /= 1 then
         raise Invalid_Argument with What & " must be 1-based";
      end if;
   end Require_Length;

   procedure Require_Finite_Vector (X : Vector; What : String) is
   begin
      if X'Length = 0 then
         raise Invalid_Argument with What & " must be non-empty";
      end if;
      for I in X'Range loop
         if not Is_Finite (X (I)) then
            raise Invalid_Argument with What & " has non-finite entry";
         end if;
      end loop;
   end Require_Finite_Vector;

   procedure Copy_In (Dest : in out Store; Src : Vector; D : Dimension) is
   begin
      Dest := [others => 0.0];
      for I in 1 .. D loop
         Dest (I) := Src (I);
      end loop;
   end Copy_In;

   function Copy_Out (Src : Store; D : Dimension) return Vector is
      Result : Vector (1 .. D);
   begin
      for I in 1 .. D loop
         Result (I) := Src (I);
      end loop;
      return Result;
   end Copy_Out;

   --  Soft-threshold Euclidean projection onto the probability simplex.
   --  Finds τ such that Σ max(x_i − τ, 0) = 1 (Michelot / Duchi et al.).
   procedure Euclidean_Project_Simplex (X : in out Vector) is
      Len    : constant Natural := X'Length;
      N      : Positive;
      Cumsum : Real;
      Rho    : Natural := 0;
      Theta  : Real;
      Tmp    : Real;
   begin
      if Len = 0 then
         raise Invalid_Argument with "cannot project empty vector";
      end if;
      N := Len;
      declare
         Y : Vector (1 .. N);
         U : Vector (1 .. N);
      begin
      for I in 1 .. N loop
         if not Is_Finite (X (X'First + I - 1)) then
            raise Invalid_Argument with "non-finite entry in Project_Simplex";
         end if;
         U (I) := X (X'First + I - 1);
      end loop;

      --  Descending insertion sort of U (N ≤ 64: fine for classroom).
      for I in 2 .. N loop
         Tmp := U (I);
         declare
            J : Integer := I - 1;
         begin
            while J >= 1 and then U (J) < Tmp loop
               U (J + 1) := U (J);
               J := J - 1;
            end loop;
            U (J + 1) := Tmp;
         end;
      end loop;

      Cumsum := 0.0;
      Rho := 0;
      for I in 1 .. N loop
         Cumsum := Cumsum + U (I);
         if U (I) - (Cumsum - 1.0) / Real (I) > 0.0 then
            Rho := I;
         end if;
      end loop;

      if Rho = 0 then
         --  Degenerate: fall back to uniform.
         for I in X'Range loop
            X (I) := 1.0 / Real (N);
         end loop;
         return;
      end if;

      Cumsum := 0.0;
      for I in 1 .. Rho loop
         Cumsum := Cumsum + U (I);
      end loop;
      Theta := (Cumsum - 1.0) / Real (Rho);

      for I in 1 .. N loop
         Tmp := X (X'First + I - 1) - Theta;
         if Tmp > 0.0 then
            Y (I) := Tmp;
         else
            Y (I) := 0.0;
         end if;
      end loop;

      for I in 1 .. N loop
         X (X'First + I - 1) := Y (I);
      end loop;
      end;
   end Euclidean_Project_Simplex;

   procedure Prepare_Entropic_Initial (Dest : in out Store; Src : Vector;
                                       D : Dimension)
   is
      S : Real := 0.0;
   begin
      for I in 1 .. D loop
         if not Is_Finite (Src (I)) or else Src (I) < 0.0 then
            raise Invalid_Argument
              with "entropic initial point must be non-negative and finite";
         end if;
         if Src (I) < Entropy_Floor then
            Dest (I) := Entropy_Floor;
         else
            Dest (I) := Src (I);
         end if;
         S := S + Dest (I);
      end loop;
      if S <= 0.0 or else not Is_Finite (S) then
         raise Invalid_Argument with "entropic initial sum must be positive";
      end if;
      for I in 1 .. D loop
         Dest (I) := Dest (I) / S;
      end loop;
   end Prepare_Entropic_Initial;

   -------------------------------------------------------------------------
   -- Construction / reset
   -------------------------------------------------------------------------

   function Create
     (D    : Dimension;
      Eta  : Positive_Real;
      Kind : Geometry := Euclidean) return State
   is
      S : State;
   begin
      Validate_Eta (Eta);
      S.D := D;
      S.Eta := Eta;
      S.Kind := Kind;
      S.X := [others => 0.0];
      S.Round_Count := 0;
      S.Project_Flag := False;
      case Kind is
         when Euclidean =>
            null;  -- origin
         when Entropic =>
            for I in 1 .. D loop
               S.X (I) := 1.0 / Real (D);
            end loop;
      end case;
      S.Initialized := True;
      return S;
   end Create;

   function Create
     (Eta     : Positive_Real;
      Initial : Vector;
      Kind    : Geometry := Euclidean) return State
   is
      S : State;
      D : Dimension;
   begin
      Validate_Eta (Eta);
      if Initial'Length = 0 or else Initial'Length > Max_Dim then
         raise Invalid_Argument with "initial length out of range";
      end if;
      if Initial'First /= 1 then
         raise Invalid_Argument with "initial vector must be 1-based";
      end if;
      Require_Finite_Vector (Initial, "initial");
      D := Initial'Length;
      S.D := D;
      S.Eta := Eta;
      S.Kind := Kind;
      S.X := [others => 0.0];
      S.Round_Count := 0;
      S.Project_Flag := False;
      case Kind is
         when Euclidean =>
            Copy_In (S.X, Initial, D);
         when Entropic =>
            Prepare_Entropic_Initial (S.X, Initial, D);
      end case;
      S.Initialized := True;
      return S;
   end Create;

   procedure Reset (S : in out State) is
   begin
      Require_Initialized (S);
      S.X := [others => 0.0];
      case S.Kind is
         when Euclidean =>
            null;
         when Entropic =>
            for I in 1 .. S.D loop
               S.X (I) := 1.0 / Real (S.D);
            end loop;
      end case;
      S.Round_Count := 0;
   end Reset;

   procedure Reset (S : in out State; Initial : Vector) is
   begin
      Require_Initialized (S);
      Require_Length (Initial, S.D, "initial");
      Require_Finite_Vector (Initial, "initial");
      case S.Kind is
         when Euclidean =>
            Copy_In (S.X, Initial, S.D);
         when Entropic =>
            Prepare_Entropic_Initial (S.X, Initial, S.D);
      end case;
      S.Round_Count := 0;
   end Reset;

   -------------------------------------------------------------------------
   -- Accessors
   -------------------------------------------------------------------------

   function Dimension_Of (S : State) return Dimension is
   begin
      Require_Initialized (S);
      return S.D;
   end Dimension_Of;

   function Learning_Rate (S : State) return Positive_Real is
   begin
      Require_Initialized (S);
      return S.Eta;
   end Learning_Rate;

   function Geometry_Of (S : State) return Geometry is
   begin
      Require_Initialized (S);
      return S.Kind;
   end Geometry_Of;

   function Rounds (S : State) return Natural is
   begin
      Require_Initialized (S);
      return S.Round_Count;
   end Rounds;

   function Point (S : State) return Vector is
   begin
      Require_Initialized (S);
      return Copy_Out (S.X, S.D);
   end Point;

   function Get (S : State) return Vector is
   begin
      return Point (S);
   end Get;

   procedure Set_Learning_Rate (S : in out State; Eta : Positive_Real) is
   begin
      Require_Initialized (S);
      Validate_Eta (Eta);
      S.Eta := Eta;
   end Set_Learning_Rate;

   procedure Enable_Simplex_Projection
     (S : in out State; Enabled : Boolean := True)
   is
   begin
      Require_Initialized (S);
      S.Project_Flag := Enabled;
   end Enable_Simplex_Projection;

   function Simplex_Projection_Enabled (S : State) return Boolean is
   begin
      Require_Initialized (S);
      return S.Project_Flag;
   end Simplex_Projection_Enabled;

   -------------------------------------------------------------------------
   -- Mirror step
   -------------------------------------------------------------------------

   procedure Step (S : in out State; Gradient : Vector) is
      Factor : Real;
      Z      : Real;
   begin
      Require_Initialized (S);
      Require_Length (Gradient, S.D, "gradient");
      Require_Finite_Vector (Gradient, "gradient");

      case S.Kind is
         when Euclidean =>
            for I in 1 .. S.D loop
               S.X (I) := S.X (I) - S.Eta * Gradient (I);
               if not Is_Finite (S.X (I)) then
                  raise Invalid_Argument with "Euclidean step left non-finite";
               end if;
            end loop;
            if S.Project_Flag then
               declare
                  V : Vector := Copy_Out (S.X, S.D);
               begin
                  Euclidean_Project_Simplex (V);
                  Copy_In (S.X, V, S.D);
               end;
            end if;

         when Entropic =>
            Z := 0.0;
            for I in 1 .. S.D loop
               Factor := Exp (-S.Eta * Gradient (I));
               if not Is_Finite (Factor) or else Factor <= 0.0 then
                  raise Invalid_Argument
                    with "entropic step produced non-positive factor";
               end if;
               S.X (I) := S.X (I) * Factor;
               if S.X (I) < Entropy_Floor then
                  S.X (I) := Entropy_Floor;
               end if;
               if not Is_Finite (S.X (I)) then
                  raise Invalid_Argument with "entropic weight non-finite";
               end if;
               Z := Z + S.X (I);
            end loop;
            if Z <= 0.0 or else not Is_Finite (Z) then
               raise Invalid_Argument with "entropic normalizer invalid";
            end if;
            for I in 1 .. S.D loop
               S.X (I) := S.X (I) / Z;
            end loop;
      end case;

      S.Round_Count := S.Round_Count + 1;
   end Step;

   -------------------------------------------------------------------------
   -- Free vector helpers
   -------------------------------------------------------------------------

   function Dot (A, B : Vector) return Real is
      S : Real := 0.0;
   begin
      if A'Length = 0 or else B'Length = 0 then
         raise Invalid_Argument with "Dot requires non-empty vectors";
      end if;
      if A'Length /= B'Length then
         raise Invalid_Argument with "Dot length mismatch";
      end if;
      for I in 0 .. A'Length - 1 loop
         S := S + A (A'First + I) * B (B'First + I);
      end loop;
      return S;
   end Dot;

   function Norm2 (X : Vector) return Non_Negative is
   begin
      if X'Length = 0 then
         raise Invalid_Argument with "Norm2 requires non-empty vector";
      end if;
      return Sqrt (Dot (X, X));
   end Norm2;

   function Scale (C : Real; X : Vector) return Vector is
      Result : Vector (X'Range);
   begin
      if X'Length = 0 then
         raise Invalid_Argument with "Scale requires non-empty vector";
      end if;
      for I in X'Range loop
         Result (I) := C * X (I);
      end loop;
      return Result;
   end Scale;

   function Add (A, B : Vector) return Vector is
      Result : Vector (A'Range);
   begin
      if A'Length = 0 or else A'Length /= B'Length then
         raise Invalid_Argument with "Add length error";
      end if;
      for I in 0 .. A'Length - 1 loop
         Result (A'First + I) := A (A'First + I) + B (B'First + I);
      end loop;
      return Result;
   end Add;

   function Sub (A, B : Vector) return Vector is
      Result : Vector (A'Range);
   begin
      if A'Length = 0 or else A'Length /= B'Length then
         raise Invalid_Argument with "Sub length error";
      end if;
      for I in 0 .. A'Length - 1 loop
         Result (A'First + I) := A (A'First + I) - B (B'First + I);
      end loop;
      return Result;
   end Sub;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vector_Near
     (A, B : Vector; Tol : Real := 1.0E-9) return Boolean
   is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in 0 .. A'Length - 1 loop
         if abs (A (A'First + I) - B (B'First + I)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vector_Near;

   -------------------------------------------------------------------------
   -- Simplex helpers / Bregman
   -------------------------------------------------------------------------

   function Is_Simplex
     (X : Vector; Tol : Real := 1.0E-9) return Boolean
   is
      S : Real := 0.0;
   begin
      if X'Length = 0 then
         return False;
      end if;
      for I in X'Range loop
         if not Is_Finite (X (I)) or else X (I) < -Tol then
            return False;
         end if;
         S := S + X (I);
      end loop;
      return abs (S - 1.0) <= Tol;
   end Is_Simplex;

   function Normalize_Simplex (X : Vector) return Vector is
      S      : Real := 0.0;
      Result : Vector (X'Range);
   begin
      Require_Finite_Vector (X, "Normalize_Simplex");
      for I in X'Range loop
         S := S + X (I);
      end loop;
      if S <= 0.0 or else not Is_Finite (S) then
         raise Invalid_Argument
           with "Normalize_Simplex requires positive sum";
      end if;
      for I in X'Range loop
         Result (I) := X (I) / S;
      end loop;
      return Result;
   end Normalize_Simplex;

   procedure Project_Simplex (X : in out Vector) is
   begin
      Euclidean_Project_Simplex (X);
   end Project_Simplex;

   function Project_Simplex (X : Vector) return Vector is
      Result : Vector := X;
   begin
      Euclidean_Project_Simplex (Result);
      return Result;
   end Project_Simplex;

   function Bregman_Euclidean (X, Y : Vector) return Non_Negative is
      Diff : Vector (X'Range);
      S    : Real := 0.0;
   begin
      if X'Length = 0 or else X'Length /= Y'Length then
         raise Invalid_Argument with "Bregman_Euclidean length error";
      end if;
      for I in 0 .. X'Length - 1 loop
         Diff (X'First + I) := X (X'First + I) - Y (Y'First + I);
         S := S + Diff (X'First + I) * Diff (X'First + I);
      end loop;
      return 0.5 * S;
   end Bregman_Euclidean;

   function Bregman_Entropy (X, Y : Vector) return Non_Negative is
      S : Real := 0.0;
      Xi, Yi : Real;
   begin
      if X'Length = 0 or else X'Length /= Y'Length then
         raise Invalid_Argument with "Bregman_Entropy length error";
      end if;
      for I in 0 .. X'Length - 1 loop
         Xi := X (X'First + I);
         Yi := Y (Y'First + I);
         if not Is_Finite (Xi) or else not Is_Finite (Yi)
           or else Xi <= 0.0 or else Yi <= 0.0
         then
            raise Invalid_Argument
              with "Bregman_Entropy requires positive finite entries";
         end if;
         S := S + Xi * Log (Xi / Yi);
      end loop;
      if S < 0.0 then
         --  Numerical noise on near-equal points.
         return 0.0;
      end if;
      return S;
   end Bregman_Entropy;

   function Suggested_Eta_Entropic
     (D : Dimension; T : Positive) return Positive_Real
   is
      Eta : Real;
   begin
      Eta := Sqrt (Log (Real (D)) / Real (T));
      if Eta <= 0.0 or else not Is_Finite (Eta) then
         return Real'Model_Small;
      end if;
      return Eta;
   end Suggested_Eta_Entropic;

end Mirror_Descent;
