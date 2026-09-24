--  Barnes_Hut body — 2-D gravitational Barnes–Hut quadtree (monopole/COM).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Barnes_Hut is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Tiny : constant Real := 1.0E-30;

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

   function Soft_Denom (DX, DY, Soft_Eps : Real) return Positive_Real is
      R2 : constant Real := DX * DX + DY * DY + Soft_Eps * Soft_Eps;
      R  : Real;
      D  : Real;
   begin
      if R2 <= Tiny then
         return Positive_Real (1.0E-45);
      end if;
      R := Math.Sqrt (R2);
      D := R2 * R;  -- (r^2+eps^2)^{3/2}
      if D <= Tiny then
         return Positive_Real (1.0E-45);
      end if;
      return Positive_Real (D);
   end Soft_Denom;

   function Pair_Force
     (M1, M2           : Non_Negative;
      P1, P2           : Vec2;
      G, Soft_Eps      : Non_Negative) return Vec2
   is
      DX : constant Real := P2.X - P1.X;
      DY : constant Real := P2.Y - P1.Y;
      Den : constant Positive_Real := Soft_Denom (DX, DY, Soft_Eps);
      Scale : constant Real := G * M1 * M2 / Den;
   begin
      return (Scale * DX, Scale * DY);
   end Pair_Force;

   function Accept_Node
     (Node_Size : Non_Negative;
      Dist      : Non_Negative;
      Theta     : Non_Negative) return Boolean
   is
   begin
      if Dist <= Tiny or else Theta <= Tiny then
         return False;
      end if;
      return Node_Size / Dist < Theta;
   end Accept_Node;

   function Well_Separated
     (Node_CX, Node_CY, Node_Size : Real;
      Body_X, Body_Y              : Real;
      Theta                       : Non_Negative) return Boolean
   is
      Dist : constant Non_Negative :=
        Hypot (Body_X - Node_CX, Body_Y - Node_CY);
   begin
      return Accept_Node (Non_Negative (Node_Size), Dist, Theta);
   end Well_Separated;

   function Default_Config return BH_Config is
   begin
      return (Theta         => 0.5,
              Softening     => 1.0E-3,
              G             => 1.0,
              Leaf_Capacity => 1,
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
      T.N_Bodies := 0;
      for I in T.Nodes'Range loop
         T.Nodes (I).Used := False;
         T.Nodes (I).Is_Leaf := True;
         T.Nodes (I).Children := [others => 0];
         T.Nodes (I).First := 0;
         T.Nodes (I).Last := 0;
         T.Nodes (I).Mass := 0.0;
         T.Nodes (I).COMX := 0.0;
         T.Nodes (I).COMY := 0.0;
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
      T.Nodes (T.Free_Top).Mass := 0.0;
      T.Nodes (T.Free_Top).COMX := 0.0;
      T.Nodes (T.Free_Top).COMY := 0.0;
      T.Nodes (T.Free_Top).First := 0;
      T.Nodes (T.Free_Top).Last := 0;
      return T.Free_Top;
   end Alloc_Node;

   function Node_Count (T : Tree) return Natural is
   begin
      return Natural (T.Free_Top);
   end Node_Count;

   function Total_Mass (T : Tree) return Non_Negative is
   begin
      if T.Root = 0 then
         return 0.0;
      end if;
      return Non_Negative (T.Nodes (T.Root).Mass);
   end Total_Mass;

   function Root_COM (T : Tree) return Vec2 is
   begin
      if T.Root = 0 or else T.Nodes (T.Root).Mass <= Tiny then
         return (0.0, 0.0);
      end if;
      return (T.Nodes (T.Root).COMX, T.Nodes (T.Root).COMY);
   end Root_COM;

   procedure Partition_Quad
     (T            : in out Tree;
      Lo, Hi       : Natural;
      CX, CY       : Real;
      Bodies       : Body_Array;
      Ends         : out Child_Slots)
   is
      subtype Quad is Integer range 0 .. 3;
      Counts : array (Quad) of Natural := [others => 0];
      Buf    : array (1 .. Max_Bodies) of Body_Index;
      Pos    : array (Quad) of Natural;
      N      : constant Natural := (if Hi >= Lo then Hi - Lo + 1 else 0);
      Q      : Quad;
      PX, PY : Real;
   begin
      Ends := [others => 0];
      if N = 0 then
         return;
      end if;
      for I in Lo .. Hi loop
         PX := Bodies (T.Idx (I)).Pos.X;
         PY := Bodies (T.Idx (I)).Pos.Y;
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
         Counts (Q) := Counts (Q) + 1;
      end loop;
      Pos (0) := 1;
      for QQ in 1 .. 3 loop
         Pos (QQ) := Pos (QQ - 1) + Counts (QQ - 1);
      end loop;
      for I in Lo .. Hi loop
         PX := Bodies (T.Idx (I)).Pos.X;
         PY := Bodies (T.Idx (I)).Pos.Y;
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
      declare
         S : Natural := Lo;
      begin
         for QQ in Quad loop
            if Counts (QQ) = 0 then
               Ends (QQ) := 0;
            else
               Ends (QQ) := Node_Index (S + Counts (QQ) - 1);
               S := S + Counts (QQ);
            end if;
         end loop;
      end;
   end Partition_Quad;

   procedure Accumulate_COM
     (T      : in out Tree;
      Nid    : Node_Index;
      Lo, Hi : Natural;
      Bodies : Body_Array)
   is
      M  : Real := 0.0;
      MX : Real := 0.0;
      MY : Real := 0.0;
      BI : Body_Index;
      BM : Real;
   begin
      if Lo = 0 or else Hi < Lo then
         T.Nodes (Nid).Mass := 0.0;
         T.Nodes (Nid).COMX := T.Nodes (Nid).CX;
         T.Nodes (Nid).COMY := T.Nodes (Nid).CY;
         return;
      end if;
      for I in Lo .. Hi loop
         BI := T.Idx (I);
         BM := Bodies (BI).Mass;
         M  := M + BM;
         MX := MX + BM * Bodies (BI).Pos.X;
         MY := MY + BM * Bodies (BI).Pos.Y;
      end loop;
      T.Nodes (Nid).Mass := M;
      if M > Tiny then
         T.Nodes (Nid).COMX := MX / M;
         T.Nodes (Nid).COMY := MY / M;
      else
         T.Nodes (Nid).COMX := T.Nodes (Nid).CX;
         T.Nodes (Nid).COMY := T.Nodes (Nid).CY;
      end if;
   end Accumulate_COM;

   procedure Build_Subtree
     (T      : in out Tree;
      Nid    : Node_Index;
      Lo, Hi : Natural;
      Bodies : Body_Array;
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
      TM, TX, TY : Real;
   begin
      if N = 0 then
         T.Nodes (Nid).Is_Leaf := True;
         T.Nodes (Nid).First := 0;
         T.Nodes (Nid).Last := 0;
         T.Nodes (Nid).Mass := 0.0;
         return;
      end if;

      if N <= T.Leaf_Cap or else HSize <= Tiny or else Depth > 24 then
         T.Nodes (Nid).Is_Leaf := True;
         T.Nodes (Nid).First := Lo;
         T.Nodes (Nid).Last := Hi;
         Accumulate_COM (T, Nid, Lo, Hi, Bodies);
         return;
      end if;

      T.Nodes (Nid).Is_Leaf := False;
      Partition_Quad (T, Lo, Hi, CX, CY, Bodies, Ends);

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

      TM := 0.0;
      TX := 0.0;
      TY := 0.0;

      for Q in 0 .. 3 loop
         if Counts (Q) > 0 then
            Child := Alloc_Node (T);
            T.Nodes (Nid).Children (Q) := Child;
            T.Nodes (Child).CX := CX + Off_X (Q) * T.Nodes (Nid).Size * 0.5;
            T.Nodes (Child).CY := CY + Off_Y (Q) * T.Nodes (Nid).Size * 0.5;
            T.Nodes (Child).Size := HSize;
            Build_Subtree
              (T, Child, Starts (Q), Starts (Q) + Counts (Q) - 1,
               Bodies, Depth + 1);
            --  Aggregate monopole (mass + COM) from children
            declare
               CM : constant Real := T.Nodes (Child).Mass;
            begin
               TM := TM + CM;
               TX := TX + CM * T.Nodes (Child).COMX;
               TY := TY + CM * T.Nodes (Child).COMY;
            end;
         end if;
      end loop;

      T.Nodes (Nid).Mass := TM;
      if TM > Tiny then
         T.Nodes (Nid).COMX := TX / TM;
         T.Nodes (Nid).COMY := TY / TM;
      else
         T.Nodes (Nid).COMX := CX;
         T.Nodes (Nid).COMY := CY;
      end if;
   end Build_Subtree;

   procedure Build_Tree
     (T      : in out Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config)
   is
      Root : Node_Index;
   begin
      Clear_Tree (T);
      T.Soft_Eps := Config.Softening;
      T.Theta    := Config.Theta;
      T.G        := Config.G;
      T.Leaf_Cap := Config.Leaf_Capacity;
      T.N_Bodies := Count;

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

      Build_Subtree (T, Root, 1, Natural (Count), Bodies, 0);
   end Build_Tree;

   -------------------------------------------------------------------------
   -- Forces
   -------------------------------------------------------------------------

   function Force_Brute
     (Bodies : Body_Array;
      Count  : Body_Count;
      Target : Body_Index;
      Config : BH_Config) return Vec2
   is
      Acc : Vec2 := (0.0, 0.0);
      F   : Vec2;
   begin
      if Count = 0 then
         return Acc;
      end if;
      for J in 1 .. Count loop
         if J /= Target then
            F := Pair_Force
              (Bodies (Target).Mass, Bodies (J).Mass,
               Bodies (Target).Pos, Bodies (J).Pos,
               Config.G, Config.Softening);
            Acc.X := Acc.X + F.X;
            Acc.Y := Acc.Y + F.Y;
         end if;
      end loop;
      return Acc;
   end Force_Brute;

   --  Softened force from a point mass (M, CX, CY) onto target body.
   function Point_Force
     (Target_Mass : Non_Negative;
      Target_Pos  : Vec2;
      Src_Mass    : Real;
      Src_X, Src_Y : Real;
      G, Soft_Eps : Non_Negative) return Vec2
   is
   begin
      if Src_Mass <= Tiny or else Target_Mass <= Tiny then
         return (0.0, 0.0);
      end if;
      return Pair_Force
        (Target_Mass, Non_Negative (Src_Mass),
         Target_Pos, (Src_X, Src_Y),
         G, Soft_Eps);
   end Point_Force;

   function Direct_Leaf
     (T      : Tree;
      Nid    : Node_Index;
      Ti     : Body_Index;
      Bodies : Body_Array;
      Config : BH_Config) return Vec2
   is
      Acc : Vec2 := (0.0, 0.0);
      Lo  : constant Natural := T.Nodes (Nid).First;
      Hi  : constant Natural := T.Nodes (Nid).Last;
      BJ  : Body_Index;
      F   : Vec2;
   begin
      if Lo = 0 or else Hi < Lo then
         return Acc;
      end if;
      for K in Lo .. Hi loop
         BJ := T.Idx (K);
         if BJ /= Ti then
            F := Pair_Force
              (Bodies (Ti).Mass, Bodies (BJ).Mass,
               Bodies (Ti).Pos, Bodies (BJ).Pos,
               Config.G, Config.Softening);
            Acc.X := Acc.X + F.X;
            Acc.Y := Acc.Y + F.Y;
         end if;
      end loop;
      return Acc;
   end Direct_Leaf;

   function Walk_Force
     (T      : Tree;
      Nid    : Node_Index;
      Ti     : Body_Index;
      Bodies : Body_Array;
      Config : BH_Config) return Vec2
   is
      Acc  : Vec2 := (0.0, 0.0);
      Dist : Non_Negative;
      F    : Vec2;
      Child : Node_Index;
   begin
      if Nid = 0 or else not T.Nodes (Nid).Used then
         return Acc;
      end if;

      if T.Nodes (Nid).Mass <= Tiny then
         return Acc;
      end if;

      if T.Nodes (Nid).Is_Leaf then
         return Direct_Leaf (T, Nid, Ti, Bodies, Config);
      end if;

      --  Internal: MAC against COM
      Dist := Hypot
        (Bodies (Ti).Pos.X - T.Nodes (Nid).COMX,
         Bodies (Ti).Pos.Y - T.Nodes (Nid).COMY);

      if Accept_Node
           (Non_Negative (T.Nodes (Nid).Size), Dist, Config.Theta)
      then
         return Point_Force
           (Bodies (Ti).Mass, Bodies (Ti).Pos,
            T.Nodes (Nid).Mass,
            T.Nodes (Nid).COMX, T.Nodes (Nid).COMY,
            Config.G, Config.Softening);
      end if;

      for Q in 0 .. 3 loop
         Child := T.Nodes (Nid).Children (Q);
         if Child /= 0 then
            F := Walk_Force (T, Child, Ti, Bodies, Config);
            Acc.X := Acc.X + F.X;
            Acc.Y := Acc.Y + F.Y;
         end if;
      end loop;
      return Acc;
   end Walk_Force;

   function Force_Barnes_Hut
     (T      : Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Target : Body_Index;
      Config : BH_Config) return Vec2
   is
   begin
      if Count = 0 or else T.Root = 0 then
         return (0.0, 0.0);
      end if;
      return Walk_Force (T, T.Root, Target, Bodies, Config);
   end Force_Barnes_Hut;

   procedure Forces_All_Brute
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
   is
   begin
      for I in Out_F'Range loop
         Out_F (I) := (0.0, 0.0);
      end loop;
      if Count = 0 then
         return;
      end if;
      for I in 1 .. Count loop
         Out_F (I) := Force_Brute (Bodies, Count, I, Config);
      end loop;
   end Forces_All_Brute;

   procedure Forces_All_Barnes_Hut
     (T      : Tree;
      Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
   is
   begin
      for I in Out_F'Range loop
         Out_F (I) := (0.0, 0.0);
      end loop;
      if Count = 0 then
         return;
      end if;
      for I in 1 .. Count loop
         Out_F (I) := Force_Barnes_Hut (T, Bodies, Count, I, Config);
      end loop;
   end Forces_All_Barnes_Hut;

   procedure Forces_All_Barnes_Hut_From_Bodies
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Out_F  : out Force_Array)
   is
      T : Tree;
   begin
      Build_Tree (T, Bodies, Count, Config);
      Forces_All_Barnes_Hut (T, Bodies, Count, Config, Out_F);
   end Forces_All_Barnes_Hut_From_Bodies;

   function Max_Abs_Error
     (A, B  : Force_Array;
      Count : Body_Count) return Non_Negative
   is
      M : Real := 0.0;
      E : Real;
   begin
      for I in 1 .. Count loop
         E := abs (A (I).X - B (I).X) + abs (A (I).Y - B (I).Y);
         if E > M then
            M := E;
         end if;
      end loop;
      return Non_Negative (M);
   end Max_Abs_Error;

   function Sum_Masses
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
   is
      S : Real := 0.0;
   begin
      for I in 1 .. Count loop
         S := S + Bodies (I).Mass;
      end loop;
      return Non_Negative (S);
   end Sum_Masses;

   procedure Euler_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : BH_Config;
      Dt     : Real)
   is
      T  : Tree;
      F  : Force_Array (1 .. (if Count = 0 then 1 else Body_Index (Count)));
      AX, AY : Real;
   begin
      if Count = 0 or else Dt <= 0.0 then
         return;
      end if;
      Build_Tree (T, Bodies, Count, Config);
      Forces_All_Barnes_Hut (T, Bodies, Count, Config, F);
      for I in 1 .. Count loop
         if Bodies (I).Mass > Tiny then
            AX := F (I).X / Bodies (I).Mass;
            AY := F (I).Y / Bodies (I).Mass;
            Bodies (I).Vel.X := Bodies (I).Vel.X + AX * Dt;
            Bodies (I).Vel.Y := Bodies (I).Vel.Y + AY * Dt;
            Bodies (I).Pos.X := Bodies (I).Pos.X + Bodies (I).Vel.X * Dt;
            Bodies (I).Pos.Y := Bodies (I).Pos.Y + Bodies (I).Vel.Y * Dt;
         end if;
      end loop;
   end Euler_Step;

end Barnes_Hut;
