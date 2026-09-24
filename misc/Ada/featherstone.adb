--  Featherstone package body — planar RNEA, ABA, CRBA helpers.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Featherstone
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Spatial algebra (planar): index 1=ω/n, 2=vx/fx, 3=vy/fy
   ---------------------------------------------------------------------------

   type Spatial is array (1 .. 3) of Real;
   type Mat3    is array (1 .. 3, 1 .. 3) of Real;

   Zero_S : constant Spatial := [0.0, 0.0, 0.0];
   Zero_M : constant Mat3 := [others => [others => 0.0]];

   function "+" (A, B : Spatial) return Spatial is
     ([A (1) + B (1), A (2) + B (2), A (3) + B (3)]);

   function "*" (S : Real; V : Spatial) return Spatial is
     ([S * V (1), S * V (2), S * V (3)]);

   function Dot (A, B : Spatial) return Real is
     (A (1) * B (1) + A (2) * B (2) + A (3) * B (3));

   function Mat_Vec (M : Mat3; V : Spatial) return Spatial is
      R : Spatial;
   begin
      for I in 1 .. 3 loop
         R (I) := M (I, 1) * V (1) + M (I, 2) * V (2) + M (I, 3) * V (3);
      end loop;
      return R;
   end Mat_Vec;

   function Mat_Add (A, B : Mat3) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := A (I, J) + B (I, J);
         end loop;
      end loop;
      return R;
   end Mat_Add;

   function Mat_Sub (A, B : Mat3) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := A (I, J) - B (I, J);
         end loop;
      end loop;
      return R;
   end Mat_Sub;

   function Mat_Scale (S : Real; M : Mat3) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := S * M (I, J);
         end loop;
      end loop;
      return R;
   end Mat_Scale;

   function Outer (A, B : Spatial) return Mat3 is
      R : Mat3;
   begin
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            R (I, J) := A (I) * B (J);
         end loop;
      end loop;
      return R;
   end Outer;

   --  Motion cross-product matrix crm(v) * m  (v × m for motions).
   function CRM (V, M : Spatial) return Spatial is
   begin
      --  v = (ω, vx, vy);  v × m = (0, ω my_y - 0, ... classic planar)
      --  Featherstone planar: (ω1, v1) × (ω2, v2) =
      --    (0, ω1*vy2 - vy1*0? )
      --  Standard 2D spatial motion cross:
      --  [ω]   [ 0           ]   for crm(v)*m
      --  [vx]  [ -ω*my? wait]
      --
      --  In 3D: v × m = [ω]×ω_m  ;  [ω]×v_m + [v]×ω_m
      --  Planar ω only in z: ω × ω_m = 0
      --  ω × v_m = (-ω * vy_m? no) ω z-hat × (vx,vy) = (-ω*vy, ω*vx)?
      --  Actually z-hat × (vx, vy, 0) = (-vy, vx, 0) * ω → (-ω vy, ω vx)
      --  v × ω_m = (vx,vy) × ω_m z-hat = ω_m (vy, -vx)? 
      --  Linear part: ω×v_m + v×ω_m = (-ω vy_m, ω vx_m) + (vy*ω_m, -vx*ω_m)
      --             = (-ω vy_m + ω_m vy, ω vx_m - ω_m vx)
      return
        [0.0,
         -V (1) * M (3) + V (3) * M (1),
          V (1) * M (2) - V (2) * M (1)];
   end CRM;

   --  Force cross-product crf(v) * f = -crm(v)^T * f
   function CRF (V, F : Spatial) return Spatial is
   begin
      --  crf(v)*f = (-vy*fx + vx*fy? , ...)
      --  From -crm^T:
      --  crm = [[0,0,0],[vy,0,-ω],[-vx,ω,0]] with V=(ω,vx,vy)
      --  Our CRM(V,M) = (0, -ω*My + Vy*Mw, ω*Mx - Vx*Mw)
      --  So crm matrix:
      --  row1: 0, 0, 0
      --  row2: Vy, 0, -ω
      --  row3: -Vx, ω, 0
      --  crm^T:
      --  row1: 0, Vy, -Vx
      --  row2: 0, 0, ω
      --  row3: 0, -ω, 0
      --  -crm^T * f =
      --  ( -Vy*fx + Vx*fy,  -ω*fy,  ω*fx )
      return
        [-V (3) * F (2) + V (2) * F (3),
         -V (1) * F (3),
          V (1) * F (2)];
   end CRF;

   --  Spatial inertia about the proximal joint (link body frame).
   function Body_Inertia (L : Link) return Mat3 is
      M  : constant Real := L.Mass;
      CX : constant Real := L.COM.X;
      CY : constant Real := L.COM.Y;
      IZ : constant Real := L.I_COM + M * (CX * CX + CY * CY);
      R  : Mat3 := Zero_M;
   begin
      --  [ Izz , -m cy,  m cx ]
      --  [ -m cy,  m  ,  0    ]
      --  [  m cx,  0  ,  m    ]
      R (1, 1) := IZ;
      R (1, 2) := -M * CY;
      R (1, 3) :=  M * CX;
      R (2, 1) := -M * CY;
      R (2, 2) :=  M;
      R (2, 3) :=  0.0;
      R (3, 1) :=  M * CX;
      R (3, 2) :=  0.0;
      R (3, 3) :=  M;
      return R;
   end Body_Inertia;

   --  Plücker / spatial transform for a planar pose: rotate by Angle then
   --  express motion/force between frames separated by body-fixed offset
   --  Distal of parent, then joint rotation. Here: X transforms parent
   --  spatial motion into child coordinates for a revolute joint at the
   --  child proximal origin, with parent-to-joint offset given in parent
   --  frame as Off, and relative angle Q (child frame relative to parent).
   --
   --  For serial chains we work recursively in each link's body frame.
   --  X_up transforms child force → parent force coordinates;
   --  X_down transforms parent motion → child motion coordinates.

   procedure X_Motion
     (Angle : Real;
      Off   : Vec2;
      VP    : Spatial;
      VC    : out Spatial)
   is
      --  Parent motion → child: rotate into child, account for offset.
      --  ω_c = ω_p
      --  v_c = R(-q)^T (v_p + ω_p × Off) expressed... 
      --  Offset Off is from parent origin to child origin in parent frame.
      --  v_child_origin_in_parent = v_p + ω_p × Off
      --  then rotate that linear velocity into child frame by R(-Angle).
      C  : constant Real := Math.Cos (Angle);
      S  : constant Real := Math.Sin (Angle);
      W  : constant Real := VP (1);
      --  ω × Off = (-W*Off.Y, W*Off.X) in parent
      VX_P : constant Real := VP (2) - W * Off.Y;
      VY_P : constant Real := VP (3) + W * Off.X;
   begin
      VC (1) := W;
      --  Rotate parent vector into child: R(-Angle) = [[c,s],[-s,c]]
      VC (2) :=  C * VX_P + S * VY_P;
      VC (3) := -S * VX_P + C * VY_P;
   end X_Motion;

   procedure X_Force
     (Angle : Real;
      Off   : Vec2;
      FC    : Spatial;
      FP    : out Spatial)
   is
      --  Child force → parent: rotate force into parent, add moment of offset.
      C  : constant Real := Math.Cos (Angle);
      S  : constant Real := Math.Sin (Angle);
      --  Force vector rotate child→parent: R(Angle)=[[c,-s],[s,c]]
      FX_P : constant Real := C * FC (2) - S * FC (3);
      FY_P : constant Real := S * FC (2) + C * FC (3);
      N_P  : constant Real := FC (1) + Off.X * FY_P - Off.Y * FX_P;
   begin
      FP (1) := N_P;
      FP (2) := FX_P;
      FP (3) := FY_P;
   end X_Force;

   procedure X_Inertia_To_Parent
     (Angle : Real;
      Off   : Vec2;
      IC    : Mat3;
      IP    : out Mat3)
   is
      --  IP = X* IC X  (congruence for spatial inertia). Use columns.
      E1, E2, E3, C1, C2, C3, P1, P2, P3 : Spatial;
   begin
      --  For each canonical child motion basis vector e_j:
      --  map to parent force via: f_p = X_force (IC * X_motion_inv? )
      --  Standard: I_p = X* I_c X where X maps parent motion → child motion
      --  and X* maps child force → parent force.
      --  Column j of I_p = X* I_c X e_j_parent
      E1 := [1.0, 0.0, 0.0];
      E2 := [0.0, 1.0, 0.0];
      E3 := [0.0, 0.0, 1.0];
      X_Motion (Angle, Off, E1, C1);
      X_Motion (Angle, Off, E2, C2);
      X_Motion (Angle, Off, E3, C3);
      X_Force (Angle, Off, Mat_Vec (IC, C1), P1);
      X_Force (Angle, Off, Mat_Vec (IC, C2), P2);
      X_Force (Angle, Off, Mat_Vec (IC, C3), P3);
      for I in 1 .. 3 loop
         IP (I, 1) := P1 (I);
         IP (I, 2) := P2 (I);
         IP (I, 3) := P3 (I);
      end loop;
   end X_Inertia_To_Parent;

   S_Joint : constant Spatial := [1.0, 0.0, 0.0];  -- revolute about z

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Vec (A, B : Vec2; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Vec;

   function Cross_Z (A, B : Vec2) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross_Z;

   function Rot (Angle : Real; V : Vec2) return Vec2 is
      C : constant Real := Math.Cos (Angle);
      S : constant Real := Math.Sin (Angle);
   begin
      return (C * V.X - S * V.Y, S * V.X + C * V.Y);
   end Rot;

   function Mag (V : Vec2) return Non_Negative is
      R : constant Real := Math.Sqrt (V.X * V.X + V.Y * V.Y);
   begin
      if R <= 0.0 then
         return 0.0;
      end if;
      return R;
   end Mag;

   ---------------------------------------------------------------------------
   -- Chain construction
   ---------------------------------------------------------------------------

   function Create
     (N       : Link_Count;
      Gravity : Vec2 := (0.0, -9.81)) return Chain
   is
      C : Chain;
   begin
      C.N := N;
      C.Grav := Gravity;
      for I in 1 .. Max_N loop
         C.Links (I) := (Mass => 1.0, COM => (0.5, 0.0),
                         I_COM => 0.0, Distal => (1.0, 0.0));
         C.Q (I) := 0.0;
         C.Qd (I) := 0.0;
         C.Qdd (I) := 0.0;
         C.Tau (I) := 0.0;
      end loop;
      return C;
   end Create;

   procedure Set_Link
     (C : in out Chain;
      I : Link_Index;
      L : Link)
   is
   begin
      if I > C.N then
         raise Invalid_Argument;
      end if;
      if L.Mass < 0.0 or else L.I_COM < 0.0 then
         raise Invalid_Argument;
      end if;
      C.Links (I) := L;
   end Set_Link;

   procedure Set_Gravity (C : in out Chain; G : Vec2) is
   begin
      C.Grav := G;
   end Set_Gravity;

   procedure Copy_State_Arr
     (Dest : in out Real_Array;
      Src  : Real_Array;
      N    : Link_Count)
   is
   begin
      if Src'Length < N then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         Dest (I) := Src (Src'First + I - 1);
      end loop;
   end Copy_State_Arr;

   procedure Set_State
     (C   : in out Chain;
      Q   : Real_Array;
      Qd  : Real_Array;
      Qdd : Real_Array;
      Tau : Real_Array)
   is
   begin
      if C.N = 0 then
         raise Empty_Chain;
      end if;
      Copy_State_Arr (C.Q, Q, C.N);
      Copy_State_Arr (C.Qd, Qd, C.N);
      Copy_State_Arr (C.Qdd, Qdd, C.N);
      Copy_State_Arr (C.Tau, Tau, C.N);
   end Set_State;

   procedure Set_Q (C : in out Chain; Q : Real_Array) is
   begin
      Copy_State_Arr (C.Q, Q, C.N);
   end Set_Q;

   procedure Set_Qd (C : in out Chain; Qd : Real_Array) is
   begin
      Copy_State_Arr (C.Qd, Qd, C.N);
   end Set_Qd;

   procedure Set_Qdd (C : in out Chain; Qdd : Real_Array) is
   begin
      Copy_State_Arr (C.Qdd, Qdd, C.N);
   end Set_Qdd;

   procedure Set_Tau (C : in out Chain; Tau : Real_Array) is
   begin
      Copy_State_Arr (C.Tau, Tau, C.N);
   end Set_Tau;

   function N_Links (C : Chain) return Link_Count is (C.N);
   function Gravity (C : Chain) return Vec2 is (C.Grav);

   function Get_Link (C : Chain; I : Link_Index) return Link is
   begin
      if I > C.N then
         raise Invalid_Argument;
      end if;
      return C.Links (I);
   end Get_Link;

   function Get_Q (C : Chain; I : Link_Index) return Real is
   begin
      return C.Q (I);
   end Get_Q;

   function Get_Qd (C : Chain; I : Link_Index) return Real is
   begin
      return C.Qd (I);
   end Get_Qd;

   function Get_Qdd (C : Chain; I : Link_Index) return Real is
   begin
      return C.Qdd (I);
   end Get_Qdd;

   function Get_Tau (C : Chain; I : Link_Index) return Real is
   begin
      return C.Tau (I);
   end Get_Tau;

   function Make_Uniform_Chain
     (N       : Link_Count;
      Len     : Positive_Real := 1.0;
      Mass    : Positive_Real := 1.0;
      Gravity : Vec2 := (0.0, -9.81)) return Chain
   is
      C : Chain := Create (N, Gravity);
      --  Thin rod about COM: I = m L^2 / 12
      I_Rod : constant Real := Mass * Len * Len / 12.0;
   begin
      for I in 1 .. N loop
         C.Links (I) :=
           (Mass   => Mass,
            COM    => (Len * 0.5, 0.0),
            I_COM  => I_Rod,
            Distal => (Len, 0.0));
      end loop;
      return C;
   end Make_Uniform_Chain;

   ---------------------------------------------------------------------------
   -- Forward kinematics (world frame)
   ---------------------------------------------------------------------------

   function Forward_Kinematics (C : Chain) return FK_Result is
      R      : FK_Result;
      Theta  : Real := 0.0;
      Cursor : Vec2 := (0.0, 0.0);
   begin
      if C.N = 0 then
         raise Empty_Chain;
      end if;
      R.Used := C.N;
      for I in 1 .. C.N loop
         Theta := Theta + C.Q (I);
         R.Abs_Angle (I) := Theta;
         R.Joint_Pos (I) := Cursor;
         R.COM_Pos (I) :=
           (Cursor.X + Rot (Theta, C.Links (I).COM).X,
            Cursor.Y + Rot (Theta, C.Links (I).COM).Y);
         declare
            D : constant Vec2 := Rot (Theta, C.Links (I).Distal);
         begin
            Cursor := (Cursor.X + D.X, Cursor.Y + D.Y);
         end;
      end loop;
      R.Tip_Pos := Cursor;
      return R;
   end Forward_Kinematics;

   ---------------------------------------------------------------------------
   -- World-frame planar RNEA
   ---------------------------------------------------------------------------

   function Inverse_Dynamics_RNEA
     (C   : Chain;
      Qdd : Real_Array) return Real_Array
   is
      N : constant Link_Count := C.N;
      Tau : Real_Array (1 .. Max_N) := [others => 0.0];

      --  Kinematic caches
      Theta : Real_Array (1 .. Max_N);
      A     : Real_Array (1 .. Max_N);  -- angular acc
      PJ    : Vec2_Array (1 .. Max_N);  -- joint positions
      PC    : Vec2_Array (1 .. Max_N);  -- COM positions
      AC    : Vec2_Array (1 .. Max_N);  -- COM linear accelerations
   begin
      if N = 0 then
         raise Empty_Chain;
      end if;
      if Qdd'Length < N then
         raise Invalid_Argument;
      end if;

      --  Outward kinematics
      declare
         Th : Real := 0.0;
         Wv : Real := 0.0;
         Av : Real := 0.0;
         Cur : Vec2 := (0.0, 0.0);
         Aj_Cur : Vec2 := (0.0, 0.0);  -- acceleration of current joint
      begin
         for I in 1 .. N loop
            declare
               Qi  : constant Real := C.Q (I);
               Qdi : constant Real := C.Qd (I);
               Qddi : constant Real := Qdd (Qdd'First + I - 1);
               Li  : Link renames C.Links (I);
            begin
               Th := Th + Qi;
               Wv := Wv + Qdi;
               Av := Av + Qddi;
               Theta (I) := Th;
               A (I) := Av;
               PJ (I) := Cur;

               declare
                  Rcom : constant Vec2 := Rot (Th, Li.COM);
                  --  a_com = a_joint + α×r + ω×(ω×r)
                  --  α×r = (-Av*Rcom.Y, Av*Rcom.X)
                  --  ω×(ω×r) = -W^2 * Rcom
                  Alpha_X_R : constant Vec2 :=
                    (-Av * Rcom.Y, Av * Rcom.X);
                  W2 : constant Real := Wv * Wv;
               begin
                  PC (I) := (Cur.X + Rcom.X, Cur.Y + Rcom.Y);
                  AC (I) :=
                    (Aj_Cur.X + Alpha_X_R.X - W2 * Rcom.X,
                     Aj_Cur.Y + Alpha_X_R.Y - W2 * Rcom.Y);
               end;

               --  Advance to next joint position & its acceleration
               declare
                  Rd : constant Vec2 := Rot (Th, Li.Distal);
                  Alpha_X_D : constant Vec2 := (-Av * Rd.Y, Av * Rd.X);
                  W2 : constant Real := Wv * Wv;
               begin
                  Aj_Cur :=
                    (Aj_Cur.X + Alpha_X_D.X - W2 * Rd.X,
                     Aj_Cur.Y + Alpha_X_D.Y - W2 * Rd.Y);
                  Cur := (Cur.X + Rd.X, Cur.Y + Rd.Y);
               end;
            end;
         end loop;
      end;

      --  Inward force recursion
      declare
         F_Dist : Vec2 := (0.0, 0.0);
         N_Dist : Real := 0.0;
         P_Next : Vec2;
      begin
         --  Tip position for last link distal
         P_Next :=
           (PJ (N).X + Rot (Theta (N), C.Links (N).Distal).X,
            PJ (N).Y + Rot (Theta (N), C.Links (N).Distal).Y);

         for I in reverse 1 .. N loop
            declare
               Li : Link renames C.Links (I);
               M  : constant Real := Li.Mass;
               --  F_i = F_{i+1} + m a_com - m g
               Fi : constant Vec2 :=
                 (F_Dist.X + M * AC (I).X - M * C.Grav.X,
                  F_Dist.Y + M * AC (I).Y - M * C.Grav.Y);
               Rcom : constant Vec2 :=
                 (PC (I).X - PJ (I).X, PC (I).Y - PJ (I).Y);
               --  About COM: Ni - N_dist + (PJ-PC)×Fi + (P_next-PC)×(-F_dist)
               --            = I_com * α
               --  Ni = N_dist + I*α - (PJ-PC)×Fi + (P_next-PC)×F_dist
               --     = N_dist + I*α + (PC-PJ)×Fi + (P_next-PC)×F_dist
               Rcom_To_Dist : constant Vec2 :=
                 (P_Next.X - PC (I).X, P_Next.Y - PC (I).Y);
               Ni : constant Real :=
                 N_Dist
                 + Li.I_COM * A (I)
                 + Cross_Z (Rcom, Fi)
                 + Cross_Z (Rcom_To_Dist, F_Dist);
            begin
               Tau (I) := Ni;  -- revolute joint torque = axial moment

               --  Prepare for parent: distal of parent = this joint
               F_Dist := Fi;
               N_Dist := Ni;
               P_Next := PJ (I);
            end;
         end loop;
      end;

      return Tau (1 .. N);
   end Inverse_Dynamics_RNEA;

   function Inverse_Dynamics_RNEA (C : Chain) return Real_Array is
   begin
      return Inverse_Dynamics_RNEA (C, C.Qdd (1 .. C.N));
   end Inverse_Dynamics_RNEA;

   function Bias_Forces (C : Chain) return Real_Array is
      Z : constant Real_Array := [for K in 1 .. C.N => 0.0];
   begin
      return Inverse_Dynamics_RNEA (C, Z);
   end Bias_Forces;

   function Gravity_Torques (C : Chain) return Real_Array is
      Tmp : Chain := C;
   begin
      for I in 1 .. Tmp.N loop
         Tmp.Qd (I) := 0.0;
         Tmp.Qdd (I) := 0.0;
      end loop;
      return Inverse_Dynamics_RNEA (Tmp);
   end Gravity_Torques;

   ---------------------------------------------------------------------------
   -- Mass matrix via unit-acceleration RNEA (CRBA-equivalent columns)
   ---------------------------------------------------------------------------

   function Mass_Matrix (C : Chain) return Mat_NN is
      N : constant Link_Count := C.N;
      H : Mat_NN (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Tmp : Chain := C;
      Z   : constant Real_Array := [for K in 1 .. N => 0.0];
      G0  : Real_Array (1 .. N);
      Col : Real_Array (1 .. N);
      E   : Real_Array (1 .. N);
   begin
      --  Zero velocity so Coriolis vanish; subtract gravity bias.
      for I in 1 .. N loop
         Tmp.Qd (I) := 0.0;
      end loop;
      G0 := Inverse_Dynamics_RNEA (Tmp, Z);
      for J in 1 .. N loop
         E := [others => 0.0];
         E (J) := 1.0;
         Col := Inverse_Dynamics_RNEA (Tmp, E);
         for I in 1 .. N loop
            H (I, J) := Col (I) - G0 (I);
         end loop;
      end loop;
      return H;
   end Mass_Matrix;

   ---------------------------------------------------------------------------
   -- Dense Cholesky solve for CRBA forward dynamics (H small)
   ---------------------------------------------------------------------------

   procedure Solve_SPD
     (H   : Mat_NN;
      B   : Real_Array;
      X   : out Real_Array;
      N   : Link_Count)
   is
      A : Mat_NN (1 .. N, 1 .. N);
      Y : Real_Array (1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := H (I, J);
         end loop;
         Y (I) := B (B'First + I - 1);
         X (I) := 0.0;
      end loop;

      --  Cholesky A = L L^T in place (lower).
      for I in 1 .. N loop
         for J in 1 .. I loop
            declare
               S : Real := A (I, J);
            begin
               for K in 1 .. J - 1 loop
                  S := S - A (I, K) * A (J, K);
               end loop;
               if I = J then
                  if S <= 1.0E-15 then
                     raise Singular_Inertia;
                  end if;
                  A (I, J) := Math.Sqrt (S);
               else
                  A (I, J) := S / A (J, J);
               end if;
            end;
         end loop;
         for J in I + 1 .. N loop
            A (I, J) := 0.0;
         end loop;
      end loop;

      --  Forward subst L y = b
      for I in 1 .. N loop
         declare
            S : Real := Y (I);
         begin
            for K in 1 .. I - 1 loop
               S := S - A (I, K) * Y (K);
            end loop;
            Y (I) := S / A (I, I);
         end;
      end loop;

      --  Back subst L^T x = y
      for I in reverse 1 .. N loop
         declare
            S : Real := Y (I);
         begin
            for K in I + 1 .. N loop
               S := S - A (K, I) * X (K);
            end loop;
            X (I) := S / A (I, I);
         end;
      end loop;
   end Solve_SPD;

   function Forward_Dynamics_CRBA (C : Chain) return Real_Array is
      N   : constant Link_Count := C.N;
      H   : constant Mat_NN := Mass_Matrix (C);
      Bias : constant Real_Array := Bias_Forces (C);
      RHS : Real_Array (1 .. N);
      Acc : Real_Array (1 .. N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         RHS (I) := C.Tau (I) - Bias (I);
      end loop;
      Solve_SPD (H, RHS, Acc, N);
      return Acc;
   end Forward_Dynamics_CRBA;

   ---------------------------------------------------------------------------
   -- Articulated-Body Algorithm (planar spatial), O(N)
   ---------------------------------------------------------------------------

   function Forward_Dynamics_ABA (C : Chain) return Real_Array is
      N : constant Link_Count := C.N;
      Acc : Real_Array (1 .. Max_N) := [others => 0.0];

      --  Per-link body-frame quantities
      V   : array (0 .. Max_N) of Spatial := [others => Zero_S];
      A   : array (0 .. Max_N) of Spatial := [others => Zero_S];
      Cvp : array (1 .. Max_N) of Spatial := [others => Zero_S]; -- v×(S qd)
      IA  : array (1 .. Max_N) of Mat3 := [others => Zero_M];
      PA  : array (1 .. Max_N) of Spatial := [others => Zero_S];
      U   : array (1 .. Max_N) of Spatial := [others => Zero_S];
      D   : Real_Array (1 .. Max_N) := [others => 0.0];
      Uu  : Real_Array (1 .. Max_N) := [others => 0.0];  -- u = τ - S·pA

      --  Offset from parent origin to this joint in parent body frame.
      --  For link 1, parent is the fixed base (world); offset = 0.
      function Parent_Offset (I : Link_Index) return Vec2 is
      begin
         if I = 1 then
            return (0.0, 0.0);
         end if;
         return C.Links (I - 1).Distal;
      end Parent_Offset;

   begin
      if N = 0 then
         raise Empty_Chain;
      end if;

      ------------------------------------------------------------------
      -- 1. Outward: velocities & velocity-product accelerations
      ------------------------------------------------------------------
      V (0) := Zero_S;
      for I in 1 .. N loop
         declare
            Off : constant Vec2 := Parent_Offset (I);
            VP  : Spatial;
            VJ  : constant Spatial :=
              [C.Qd (I), 0.0, 0.0];  -- S * qd
         begin
            X_Motion (C.Q (I), Off, V (I - 1), VP);
            V (I) := VP + VJ;
            --  c = crm(v) * (S qd)  classic velocity product for ABA
            Cvp (I) := CRM (V (I), VJ);
         end;
      end loop;

      ------------------------------------------------------------------
      -- 2. Inward: articulated inertias & bias forces
      ------------------------------------------------------------------
      for I in 1 .. N loop
         IA (I) := Body_Inertia (C.Links (I));
         --  pA = v ×* (I v) only; I*c is accounted via a' = X a + c
         --  in the outward pass and via Ia*c when propagating inward.
         declare
            Iv : constant Spatial := Mat_Vec (IA (I), V (I));
         begin
            PA (I) := CRF (V (I), Iv);
         end;
      end loop;

      for I in reverse 1 .. N loop
         U (I) := Mat_Vec (IA (I), S_Joint);
         D (I) := Dot (S_Joint, U (I));
         if abs (D (I)) < 1.0E-15 then
            raise Singular_Inertia;
         end if;
         Uu (I) := C.Tau (I) - Dot (S_Joint, PA (I));

         if I > 1 then
            declare
               --  Ia = IA - U U^T / D
               I_Art : constant Mat3 :=
                 Mat_Sub (IA (I), Mat_Scale (1.0 / D (I), Outer (U (I), U (I))));
               --  pa = pA + Ia*c + U*(u/D)
               Pa_Child : constant Spatial :=
                 PA (I)
                 + Mat_Vec (I_Art, Cvp (I))
                 + (Uu (I) / D (I)) * U (I);
               Off : constant Vec2 := Parent_Offset (I);
               I_To_Par : Mat3;
               P_To_Par : Spatial;
            begin
               X_Inertia_To_Parent (C.Q (I), Off, I_Art, I_To_Par);
               X_Force (C.Q (I), Off, Pa_Child, P_To_Par);
               IA (I - 1) := Mat_Add (IA (I - 1), I_To_Par);
               PA (I - 1) := PA (I - 1) + P_To_Par;
            end;
         end if;
      end loop;

      ------------------------------------------------------------------
      -- 3. Outward: accelerations (gravity as base spatial accel)
      ------------------------------------------------------------------
      --  Fixed base: a_0 = -g expressed as linear spatial accel in world /
      --  base frame. Base frame coincides with link-1 parent (world).
      --  Spatial accel of base: (0, -gx, -gy) so free bodies feel +g force
      --  via f = I a with a including -g... Featherstone: a0 = -ag.
      A (0) := [0.0, -C.Grav.X, -C.Grav.Y];

      for I in 1 .. N loop
         declare
            Off : constant Vec2 := Parent_Offset (I);
            AP  : Spatial;
            Ain : Spatial;
         begin
            X_Motion (C.Q (I), Off, A (I - 1), AP);
            Ain := AP + Cvp (I);
            Acc (I) := (Uu (I) - Dot (U (I), Ain)) / D (I);
            A (I) := Ain + (Acc (I) * S_Joint);
         end;
      end loop;

      return Acc (1 .. N);
   end Forward_Dynamics_ABA;

end Featherstone;
