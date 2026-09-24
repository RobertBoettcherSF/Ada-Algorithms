--  Fast_Multipole_Method body — 2-D log-kernel hierarchical multipole.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Fast_Multipole_Method is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Tiny : constant Real := 1.0E-30;

   -------------------------------------------------------------------------
   -- Complex helpers
   -------------------------------------------------------------------------

   function "+" (A, B : Complex) return Complex is
   begin
      return (A.Re + B.Re, A.Im + B.Im);
   end "+";

   function "*" (A, B : Complex) return Complex is
   begin
      return (A.Re * B.Re - A.Im * B.Im,
              A.Re * B.Im + A.Im * B.Re);
   end "*";

   function "*" (S : Real; A : Complex) return Complex is
   begin
      return (S * A.Re, S * A.Im);
   end "*";

   function Inv (A : Complex) return Complex is
      D : constant Real := A.Re * A.Re + A.Im * A.Im;
   begin
      if D <= Tiny then
         return (0.0, 0.0);
      end if;
      return (A.Re / D, -A.Im / D);
   end Inv;

   --  z^n for n >= 0 by successive multiply.
   function Pow (Z : Complex; N : Natural) return Complex is
      R : Complex := (1.0, 0.0);
   begin
      for I in 1 .. N loop
         R := R * Z;
      end loop;
      return R;
   end Pow;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Hypot (X, Y : Real) return Non_Negative is
      AX : constant Real := abs (X);
      AY : constant Real := abs (Y);
      M  : Real;
   begin
      if AX > AY then
         M := AX;
      else
         M := AY;
      end if;
      if M <= Tiny then
         return 0.0;
      end if;
      declare
         SX : constant Real := X / M;
         SY : constant Real := Y / M;
      begin
         return Non_Negative (M * Math.Sqrt (SX * SX + SY * SY));
      end;
   end Hypot;

   function Soft_Radius (DX, DY, Soft_Eps : Real) return Positive_Real is
      R2 : constant Real := DX * DX + DY * DY + Soft_Eps * Soft_Eps;
      R  : Real;
   begin
      if R2 <= Tiny then
         return Positive_Real (1.0E-15);
      end if;
      R := Math.Sqrt (R2);
      if R <= Tiny then
         return Positive_Real (1.0E-15);
      end if;
      return Positive_Real (R);
   end Soft_Radius;

   function Log_Kernel (R : Positive_Real) return Real is
   begin
      return -Math.Log (R);
   end Log_Kernel;

   function Well_Separated
     (CX1, CY1, Size1 : Real;
      CX2, CY2, Size2 : Real;
      Theta           : Positive_Real) return Boolean
   is
      Dist : constant Non_Negative := Hypot (CX1 - CX2, CY1 - CY2);
      S    : Real;
   begin
      if Dist <= Tiny then
         return False;
      end if;
      if Size1 > Size2 then
         S := Size1;
      else
         S := Size2;
      end if;
      return S / Dist < Theta;
   end Well_Separated;

   -------------------------------------------------------------------------
   -- Multipole API
   -------------------------------------------------------------------------

   function Zero_Multipole return Multipole is
   begin
      return (A0 => 0.0, A => [others => (0.0, 0.0)]);
   end Zero_Multipole;

   function Monopole_Of (M : Multipole) return Real is
   begin
      return M.A0;
   end Monopole_Of;

   function Moment_Re (M : Multipole; K : Order_Value) return Real is
   begin
      return M.A (K).Re;
   end Moment_Re;

   function Moment_Im (M : Multipole; K : Order_Value) return Real is
   begin
      return M.A (K).Im;
   end Moment_Im;

   procedure P2M
     (M      : in out Multipole;
      Parts  : Particle_Array;
      First  : Particle_Index;
      Last   : Particle_Count;
      CX, CY : Real;
      P      : Order_Value)
   is
   begin
      if Last = 0 or else Last < First then
         return;
      end if;
      for I in First .. Particle_Index (Last) loop
         declare
            DX : constant Real := Parts (I).X - CX;
            DY : constant Real := Parts (I).Y - CY;
            Q  : constant Real := Parts (I).Q;
            Z  : constant Complex := (DX, DY);
            ZK : Complex := (1.0, 0.0);
         begin
            M.A0 := M.A0 + Q;
            for K in 1 .. P loop
               ZK := ZK * Z;  -- z^k
               --  a_k += - q * z^k / k
               M.A (K) := M.A (K)
                 + ((-Q / Real (K)) * ZK);
            end loop;
         end;
      end loop;
   end P2M;

   --  Binomial coefficient C(n, k) for small n <= Max_Order.
   function Binom (N, K : Natural) return Real is
      R : Real := 1.0;
   begin
      if K > N then
         return 0.0;
      end if;
      declare
         KK : Natural := K;
      begin
         if KK > N - KK then
            KK := N - KK;
         end if;
         for I in 1 .. KK loop
            R := R * Real (N - KK + I) / Real (I);
         end loop;
      end;
      return R;
   end Binom;

   procedure M2M
     (Parent           : in out Multipole;
      Child            : Multipole;
      DX, DY           : Real;
      P                : Order_Value)
   is
      --  Translate child multipole (about child centre) to parent centre.
      --  t = child_centre - parent_centre = (DX, DY).
      --  Greengard shift:
      --    a'_0 = a_0
      --    a'_l = -a_0 * t^l / l + sum_{k=1}^l a_k * C(l-1, k-1) * t^{l-k}
      T  : constant Complex := (DX, DY);
      TL : Complex;
      Acc : Complex;
   begin
      Parent.A0 := Parent.A0 + Child.A0;
      for L in 1 .. P loop
         TL := Pow (T, L);
         Acc := (-Child.A0 / Real (L)) * TL;
         for K in 1 .. L loop
            Acc := Acc
              + (Binom (L - 1, K - 1)
                 * (Child.A (K) * Pow (T, L - K)));
         end loop;
         Parent.A (L) := Parent.A (L) + Acc;
      end loop;
   end M2M;

   function Evaluate_Multipole
     (M      : Multipole;
      TX, TY : Real;
      CX, CY : Real;
      P      : Order_Value) return Real
   is
      DX : constant Real := TX - CX;
      DY : constant Real := TY - CY;
      R  : constant Non_Negative := Hypot (DX, DY);
      Z  : Complex;
      ZInv : Complex;
      ZPow : Complex;
      Acc  : Complex := (0.0, 0.0);
      Phi  : Real;
   begin
      if R <= Tiny then
         return 0.0;
      end if;
      Z := (DX, DY);
      ZInv := Inv (Z);
      --  Real potential Phi = -Re(complex GR expansion):
      --    Phi = a0*log(1/|z|) - Re(sum a_k/z^k)
      --  with Greengard a_k = -sum q z_j^k / k.
      Phi := M.A0 * Log_Kernel (Positive_Real (R));
      ZPow := (1.0, 0.0);
      for K in 1 .. P loop
         ZPow := ZPow * ZInv;  -- 1/z^k
         Acc := Acc + (M.A (K) * ZPow);
      end loop;
      Phi := Phi - Acc.Re;
      return Phi;
   end Evaluate_Multipole;

   function Default_Config return FMM_Config is
   begin
      return (P             => 4,
              Leaf_Capacity => 8,
              Theta         => 0.5,
              Soft_Eps      => 1.0E-4,
              Domain_Min_X  => 0.0,
              Domain_Min_Y  => 0.0,
              Domain_Size   => 1.0);
   end Default_Config;

   -------------------------------------------------------------------------
   -- Tree helpers
   -------------------------------------------------------------------------

   procedure Clear_Tree (T : in out Tree) is
   begin
      T.Free_Top := 0;
      T.Root     := 0;
      T.N_Parts  := 0;
      for I in T.Nodes'Range loop
         T.Nodes (I).Used := False;
         T.Nodes (I).Is_Leaf := True;
         T.Nodes (I).Children := [others => 0];
         T.Nodes (I).First := 0;
         T.Nodes (I).Last := 0;
         T.Nodes (I).Mom := Zero_Multipole;
      end loop;
   end Clear_Tree;

   function Alloc_Node (T : in out Tree) return Node_Index is
   begin
      if T.Free_Top = Max_Nodes then
         raise Capacity_Exceeded;
      end if;
      T.Free_Top := T.Free_Top + 1;
      T.Nodes (T.Free_Top).Used := True;
      T.Nodes (T.Free_Top).Is_Leaf := True;
      T.Nodes (T.Free_Top).Children := [others => 0];
      T.Nodes (T.Free_Top).Mom := Zero_Multipole;
      T.Nodes (T.Free_Top).First := 0;
      T.Nodes (T.Free_Top).Last := 0;
      return T.Free_Top;
   end Alloc_Node;

   function Node_Count (T : Tree) return Natural is
   begin
      return Natural (T.Free_Top);
   end Node_Count;

   function Root_Monopole (T : Tree) return Real is
   begin
      if T.Root = 0 then
         return 0.0;
      end if;
      return T.Nodes (T.Root).Mom.A0;
   end Root_Monopole;

   --  Partition Idx(Lo .. Hi) into four quadrants relative to (CX, CY).
   --  Returns end indices of each quadrant in place via four segments.
   procedure Partition_Quad
     (T            : in out Tree;
      Lo, Hi       : Natural;
      CX, CY       : Real;
      Parts        : Particle_Array;
      Ends         : out Child_Slots)
   is
      --  Ends(Q) = last index of quadrant Q after partition; start of Q0 = Lo.
      --  Use a simple gather into temp then copy back.
      subtype Quad is Integer range 0 .. 3;
      Counts : array (Quad) of Natural := [others => 0];
      Buf    : array (1 .. Max_Particles) of Particle_Index;
      Pos    : array (Quad) of Natural;
      N      : constant Natural := (if Hi >= Lo then Hi - Lo + 1 else 0);
      Q      : Quad;
      PX, PY : Real;
      Base   : Natural;
   begin
      Ends := [others => 0];
      if N = 0 then
         return;
      end if;
      for I in Lo .. Hi loop
         PX := Parts (T.Idx (I)).X;
         PY := Parts (T.Idx (I)).Y;
         if PX < CX then
            if PY < CY then
               Q := 0;  -- SW
            else
               Q := 1;  -- NW
            end if;
         else
            if PY < CY then
               Q := 2;  -- SE
            else
               Q := 3;  -- NE
            end if;
         end if;
         Counts (Q) := Counts (Q) + 1;
      end loop;
      Pos (0) := 1;
      for Q in 1 .. 3 loop
         Pos (Q) := Pos (Q - 1) + Counts (Q - 1);
      end loop;
      for I in Lo .. Hi loop
         PX := Parts (T.Idx (I)).X;
         PY := Parts (T.Idx (I)).Y;
         if PX < CX then
            if PY < CY then
               Q := 0;
            else
               Q := 1;
            end if;
         else
            if PY < CY then
               Q := 2;
            else
               Q := 3;
            end if;
         end if;
         Buf (Pos (Q)) := T.Idx (I);
         Pos (Q) := Pos (Q) + 1;
      end loop;
      for I in 1 .. N loop
         T.Idx (Lo + I - 1) := Buf (I);
      end loop;
      Base := Lo - 1;
      for Q in Quad loop
         Base := Base + Counts (Q);
         if Counts (Q) > 0 then
            Ends (Q) := Node_Index (Base);
         else
            Ends (Q) := 0;
         end if;
      end loop;
      --  Encode starts via Ends: we also need starts. Store as:
      --  For Build we recompute starts from Ends and Counts.
      --  Overwrite Ends to hold the LAST index; starts recovered below.
      declare
         S : Natural := Lo;
      begin
         for Q in Quad loop
            if Counts (Q) = 0 then
               Ends (Q) := 0;
            else
               --  pack: high 16 unused; we store last in Ends, start = S
               --  Actually Child_Slots is Node_Index — misuse for particle
               --  ends only during partition; Build_Subtree uses separate.
               Ends (Q) := Node_Index (S + Counts (Q) - 1);
               S := S + Counts (Q);
            end if;
         end loop;
      end;
   end Partition_Quad;

   procedure Build_Subtree
     (T      : in out Tree;
      Nid    : Node_Index;
      Lo, Hi : Natural;
      Parts  : Particle_Array;
      Depth  : Natural)
   is
      N     : constant Natural := (if Hi >= Lo then Hi - Lo + 1 else 0);
      CX    : constant Real := T.Nodes (Nid).CX;
      CY    : constant Real := T.Nodes (Nid).CY;
      HSize : constant Real := T.Nodes (Nid).Size * 0.5;
      Ends  : Child_Slots;
      Counts : array (0 .. 3) of Natural;
      Starts : array (0 .. 3) of Natural;
      Child  : Node_Index;
      Off_X  : constant array (0 .. 3) of Real :=
        [-0.5, -0.5, 0.5, 0.5];
      Off_Y  : constant array (0 .. 3) of Real :=
        [-0.5, 0.5, -0.5, 0.5];
   begin
      if N = 0 then
         T.Nodes (Nid).Is_Leaf := True;
         T.Nodes (Nid).First := 0;
         T.Nodes (Nid).Last := 0;
         return;
      end if;

      if N <= T.Leaf_Cap or else HSize <= Tiny or else Depth > 24 then
         T.Nodes (Nid).Is_Leaf := True;
         T.Nodes (Nid).First := Lo;
         T.Nodes (Nid).Last := Hi;
         --  P2M from leaf particles
         declare
            --  Temporary contiguous particle slice for P2M
            --  Form moments by iterating indices.
            M : Multipole := Zero_Multipole;
         begin
            for I in Lo .. Hi loop
               declare
                  PIdx : constant Particle_Index := T.Idx (I);
                  One  : Particle_Array (1 .. 1);
               begin
                  One (1) := Parts (PIdx);
                  P2M (M, One, 1, 1, CX, CY, T.P);
               end;
            end loop;
            T.Nodes (Nid).Mom := M;
         end;
         return;
      end if;

      --  Internal node: partition and recurse
      T.Nodes (Nid).Is_Leaf := False;
      Partition_Quad (T, Lo, Hi, CX, CY, Parts, Ends);

      declare
         S : Natural := Lo;
         C : Natural;
         Last_E : Natural;
      begin
         for Q in 0 .. 3 loop
            if Ends (Q) = 0 then
               Counts (Q) := 0;
               Starts (Q) := 0;
            else
               Last_E := Natural (Ends (Q));
               C := Last_E - S + 1;
               Counts (Q) := C;
               Starts (Q) := S;
               S := Last_E + 1;
            end if;
         end loop;
      end;

      for Q in 0 .. 3 loop
         if Counts (Q) > 0 then
            Child := Alloc_Node (T);
            T.Nodes (Nid).Children (Q) := Child;
            --  Child side = HSize; centre offset from parent = ± Size/4
            --  Off_X/Y are ±0.5 so Off * Size * 0.5 = ± Size/4.
            T.Nodes (Child).CX := CX + Off_X (Q) * T.Nodes (Nid).Size * 0.5;
            T.Nodes (Child).CY := CY + Off_Y (Q) * T.Nodes (Nid).Size * 0.5;
            T.Nodes (Child).Size := HSize;
            Build_Subtree
              (T, Child, Starts (Q), Starts (Q) + Counts (Q) - 1,
               Parts, Depth + 1);
            --  M2M: child -> parent; DX = child_c - parent_c
            M2M
              (T.Nodes (Nid).Mom,
               T.Nodes (Child).Mom,
               T.Nodes (Child).CX - CX,
               T.Nodes (Child).CY - CY,
               T.P);
         end if;
      end loop;
   end Build_Subtree;

   procedure Build_Tree
     (T      : in out Tree;
      Parts  : Particle_Array;
      Count  : Particle_Count;
      Config : FMM_Config)
   is
      Root : Node_Index;
   begin
      Clear_Tree (T);
      T.P        := Config.P;
      T.Soft_Eps := Config.Soft_Eps;
      T.Theta    := Config.Theta;
      T.Leaf_Cap := Config.Leaf_Capacity;
      T.N_Parts  := Count;

      if Count = 0 then
         Root := Alloc_Node (T);
         T.Root := Root;
         T.Nodes (Root).CX := Config.Domain_Min_X + 0.5 * Config.Domain_Size;
         T.Nodes (Root).CY := Config.Domain_Min_Y + 0.5 * Config.Domain_Size;
         T.Nodes (Root).Size := Config.Domain_Size;
         return;
      end if;

      for I in 1 .. Count loop
         T.Idx (I) := I;
      end loop;

      Root := Alloc_Node (T);
      T.Root := Root;
      T.Nodes (Root).CX := Config.Domain_Min_X + 0.5 * Config.Domain_Size;
      T.Nodes (Root).CY := Config.Domain_Min_Y + 0.5 * Config.Domain_Size;
      T.Nodes (Root).Size := Config.Domain_Size;

      Build_Subtree (T, Root, 1, Natural (Count), Parts, 0);
   end Build_Tree;

   -------------------------------------------------------------------------
   -- Potentials
   -------------------------------------------------------------------------

   procedure Compute_Potentials_Brute
     (Parts    : Particle_Array;
      Count    : Particle_Count;
      Soft_Eps : Non_Negative;
      Out_Phi  : out Real_Array)
   is
   begin
      for I in 1 .. Count loop
         Out_Phi (I) := 0.0;
      end loop;
      if Count = 0 then
         return;
      end if;
      for I in 1 .. Count loop
         declare
            Acc : Real := 0.0;
            DX, DY : Real;
            R : Positive_Real;
         begin
            for J in 1 .. Count loop
               if J /= I then
                  DX := Parts (I).X - Parts (J).X;
                  DY := Parts (I).Y - Parts (J).Y;
                  R := Soft_Radius (DX, DY, Soft_Eps);
                  Acc := Acc + Parts (J).Q * Log_Kernel (R);
               end if;
            end loop;
            Out_Phi (I) := Acc;
         end;
      end loop;
   end Compute_Potentials_Brute;

   --  Direct sum of sources in leaf node onto target particle Ti.
   function Direct_Leaf
     (T      : Tree;
      Nid    : Node_Index;
      Ti     : Particle_Index;
      Parts  : Particle_Array) return Real
   is
      Acc : Real := 0.0;
      Lo  : constant Natural := T.Nodes (Nid).First;
      Hi  : constant Natural := T.Nodes (Nid).Last;
      PJ  : Particle_Index;
      DX, DY : Real;
      R : Positive_Real;
   begin
      if Lo = 0 or else Hi < Lo then
         return 0.0;
      end if;
      for K in Lo .. Hi loop
         PJ := T.Idx (K);
         if PJ /= Ti then
            DX := Parts (Ti).X - Parts (PJ).X;
            DY := Parts (Ti).Y - Parts (PJ).Y;
            R := Soft_Radius (DX, DY, T.Soft_Eps);
            Acc := Acc + Parts (PJ).Q * Log_Kernel (R);
         end if;
      end loop;
      return Acc;
   end Direct_Leaf;

   function Eval_Node
     (T      : Tree;
      Nid    : Node_Index;
      Ti     : Particle_Index;
      Parts  : Particle_Array) return Real
   is
      N : Node renames T.Nodes (Nid);
      Dist : Non_Negative;
      Acc  : Real := 0.0;
      C    : Node_Index;
   begin
      if not N.Used then
         return 0.0;
      end if;

      if N.Is_Leaf then
         return Direct_Leaf (T, Nid, Ti, Parts);
      end if;

      Dist := Hypot (Parts (Ti).X - N.CX, Parts (Ti).Y - N.CY);
      if Dist > Tiny
        and then Well_Separated
                   (Parts (Ti).X, Parts (Ti).Y, 0.0,
                    N.CX, N.CY, N.Size, T.Theta)
      then
         --  Far field: M2P (treat target as point; Size_target = 0)
         return Evaluate_Multipole
           (N.Mom, Parts (Ti).X, Parts (Ti).Y, N.CX, N.CY, T.P);
      end if;

      --  Near / not accepted: recurse children
      for Q in 0 .. 3 loop
         C := N.Children (Q);
         if C /= 0 then
            Acc := Acc + Eval_Node (T, C, Ti, Parts);
         end if;
      end loop;
      return Acc;
   end Eval_Node;

   procedure Compute_Potentials_FMM
     (T        : Tree;
      Parts    : Particle_Array;
      Count    : Particle_Count;
      Config   : FMM_Config;
      Out_Phi  : out Real_Array)
   is
      pragma Unreferenced (Config);
   begin
      for I in 1 .. Count loop
         Out_Phi (I) := 0.0;
      end loop;
      if Count = 0 or else T.Root = 0 then
         return;
      end if;
      for I in 1 .. Count loop
         Out_Phi (I) := Eval_Node (T, T.Root, I, Parts);
      end loop;
   end Compute_Potentials_FMM;

   function Max_Abs_Error
     (A, B : Real_Array; Count : Particle_Count) return Non_Negative
   is
      M : Real := 0.0;
      D : Real;
   begin
      for I in 1 .. Count loop
         D := abs (A (I) - B (I));
         if D > M then
            M := D;
         end if;
      end loop;
      return Non_Negative (M);
   end Max_Abs_Error;

   function Total_Charge
     (Parts : Particle_Array; Count : Particle_Count) return Real
   is
      S : Real := 0.0;
   begin
      for I in 1 .. Count loop
         S := S + Parts (I).Q;
      end loop;
      return S;
   end Total_Charge;

   procedure Compute_Potentials_FMM_From_Particles
     (Parts    : Particle_Array;
      Count    : Particle_Count;
      Config   : FMM_Config;
      Out_Phi  : out Real_Array)
   is
      T : Tree;
   begin
      Build_Tree (T, Parts, Count, Config);
      Compute_Potentials_FMM (T, Parts, Count, Config, Out_Phi);
   end Compute_Potentials_FMM_From_Particles;

end Fast_Multipole_Method;
