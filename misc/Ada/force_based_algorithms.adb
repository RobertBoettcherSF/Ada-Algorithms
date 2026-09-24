--  Force_Based_Algorithms body — Fruchterman–Reingold spring-embedder.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Force_Based_Algorithms
  with SPARK_Mode => Off
is

   use Ada.Numerics;
   use Ada.Numerics.Elementary_Functions;

   Tiny       : constant Float := 1.0e-4;
   Max_Force  : constant Float := 1.0e6;
   Max_Coord  : constant Float := 1.0e30;

   type U32 is mod 2**32;

   function Next_Unit (State : in out U32) return Float is
   begin
      State := State * 1_103_515_245 + 12_345;
      return Float (State rem 10_000) / 10_000.0;
   end Next_Unit;

   function Dist_Floor (DX, DY : Float) return Float is
      D : constant Float := Sqrt (DX * DX + DY * DY);
   begin
      if D < Tiny then
         return Tiny;
      end if;
      return D;
   end Dist_Floor;

   procedure Check_Positions
     (Positions : Position_Array; N : Natural) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Positions'First /= 1
        or else Natural (Positions'Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Check_Positions;

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.E := 0;
   end Clear;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.E = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.E := G.E + 1;
      G.U (G.E) := U;
      G.V (G.E) := V;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.E);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Seeded initial placement
   -------------------------------------------------------------------------

   procedure Seed_Positions
     (G         : Graph;
      Seed      : Natural := 1;
      Scale     : Float := 1.0;
      Positions : out Position_Array)
   is
      N     : constant Natural := G.N;
      R     : Float;
      State : U32;
      Angle : Float;
      JR    : Float;
      JA    : Float;
      VI    : Vertex_Id;
   begin
      Check_Positions (Positions, N);
      if Scale <= 0.0 then
         raise Invalid_Argument;
      end if;

      for P of Positions loop
         P := (0.0, 0.0);
      end loop;

      if N = 1 then
         Positions (1) := (0.0, 0.0);
         return;
      end if;

      R := Scale * Sqrt (Float (N));
      State := U32 (Seed) * 1_000_003 + 17;

      for I in 1 .. N loop
         VI := Vertex_Id (I);
         Angle := 2.0 * Float (Pi) * Float (I - 1) / Float (N);
         JA := (Next_Unit (State) - 0.5) * 0.12;
         JR := (Next_Unit (State) - 0.5) * 0.12 * R;
         Positions (VI) :=
           ((R + JR) * Cos (Angle + JA),
            (R + JR) * Sin (Angle + JA));
      end loop;
   end Seed_Positions;

   -------------------------------------------------------------------------
   -- Force-directed iteration
   -------------------------------------------------------------------------

   procedure Layout
     (G                   : Graph;
      Iterations          : Positive := 100;
      Ideal_Length        : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule            : Temperature_Schedule := Linear;
      Cooling_Factor      : Float := 0.95;
      Positions           : in out Position_Array)
   is
      N : constant Natural := G.N;
      K : Float;
      T : Float;
      DX, DY, Dist, Mag, Fx, Fy, Len, Step : Float;
      VI, VJ : Vertex_Id;
      Disp_X : array (Vertex_Id) of Float;
      Disp_Y : array (Vertex_Id) of Float;
      UU, VV : Vertex_Id;
      PX, PY : Float;
   begin
      Check_Positions (Positions, N);
      if Ideal_Length <= 0.0 then
         raise Invalid_Argument;
      end if;
      if Initial_Temperature < 0.0 then
         raise Invalid_Argument;
      end if;
      if Schedule = Exponential
        and then (Cooling_Factor <= 0.0 or else Cooling_Factor > 1.0)
      then
         raise Invalid_Argument;
      end if;

      K := Ideal_Length;

      for Iter in 1 .. Iterations loop
         if Schedule = Linear then
            T := Initial_Temperature
              * Float (Iterations - Iter + 1) / Float (Iterations);
         else
            T := Initial_Temperature
              * (Cooling_Factor ** Float (Iter - 1));
         end if;

         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            Disp_X (V) := 0.0;
            Disp_Y (V) := 0.0;
         end loop;

         --  Repulsion: all unordered pairs.
         for I in 1 .. N loop
            VI := Vertex_Id (I);
            for J in I + 1 .. N loop
               VJ := Vertex_Id (J);
               DX := Positions (VI).X - Positions (VJ).X;
               DY := Positions (VI).Y - Positions (VJ).Y;
               Dist := Sqrt (DX * DX + DY * DY);
               if Dist < Tiny then
                  --  Coincident: unit push along (1, 0), distance Tiny.
                  DX := 1.0;
                  DY := 0.0;
                  Dist := Tiny;
               end if;
               Mag := (K * K) / Dist;
               if Mag > Max_Force then
                  Mag := Max_Force;
               end if;
               Fx := (DX / Dist) * Mag;
               Fy := (DY / Dist) * Mag;
               Disp_X (VI) := Disp_X (VI) + Fx;
               Disp_Y (VI) := Disp_Y (VI) + Fy;
               Disp_X (VJ) := Disp_X (VJ) - Fx;
               Disp_Y (VJ) := Disp_Y (VJ) - Fy;
            end loop;
         end loop;

         --  Attraction: each stored non-loop edge.
         for E in 1 .. G.E loop
            UU := G.U (E);
            VV := G.V (E);
            if UU /= VV then
               DX := Positions (UU).X - Positions (VV).X;
               DY := Positions (UU).Y - Positions (VV).Y;
               Dist := Dist_Floor (DX, DY);
               Mag := (Dist * Dist) / K;
               if Mag > Max_Force then
                  Mag := Max_Force;
               end if;
               Fx := (DX / Dist) * Mag;
               Fy := (DY / Dist) * Mag;
               Disp_X (UU) := Disp_X (UU) - Fx;
               Disp_Y (UU) := Disp_Y (UU) - Fy;
               Disp_X (VV) := Disp_X (VV) + Fx;
               Disp_Y (VV) := Disp_Y (VV) + Fy;
            end if;
         end loop;

         --  Temperature-capped Euler step.
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            PX := Disp_X (V);
            PY := Disp_Y (V);
            Len := Sqrt (PX * PX + PY * PY);
            if Len > Tiny * Tiny then
               if Len < T then
                  Step := Len;
               else
                  Step := T;
               end if;
               Positions (V).X := Positions (V).X + (PX / Len) * Step;
               Positions (V).Y := Positions (V).Y + (PY / Len) * Step;
            end if;
         end loop;
      end loop;
   end Layout;

   procedure Compute
     (G                   : Graph;
      Iterations          : Positive := 100;
      Ideal_Length        : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule            : Temperature_Schedule := Linear;
      Cooling_Factor      : Float := 0.95;
      Seed                : Natural := 1;
      Positions           : out Position_Array)
   is
   begin
      --  Validate layout parameters before writing Positions so a bad
      --  temperature / length does not leave a half-seeded buffer.
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      if Ideal_Length <= 0.0 then
         raise Invalid_Argument;
      end if;
      if Initial_Temperature < 0.0 then
         raise Invalid_Argument;
      end if;
      if Schedule = Exponential
        and then (Cooling_Factor <= 0.0 or else Cooling_Factor > 1.0)
      then
         raise Invalid_Argument;
      end if;
      Seed_Positions (G, Seed, Ideal_Length, Positions);
      Layout
        (G, Iterations, Ideal_Length, Initial_Temperature,
         Schedule, Cooling_Factor, Positions);
   end Compute;

   -------------------------------------------------------------------------
   -- Geometry helpers
   -------------------------------------------------------------------------

   function Euclidean (A, B : Point2D) return Float is
      DX : constant Float := A.X - B.X;
      DY : constant Float := A.Y - B.Y;
   begin
      return Sqrt (DX * DX + DY * DY);
   end Euclidean;

   function Position_Of
     (Positions : Position_Array; V : Vertex_Id) return Point2D
   is
   begin
      if V < Positions'First or else V > Positions'Last then
         raise Invalid_Argument;
      end if;
      return Positions (V);
   end Position_Of;

   function Mean_Edge_Length
     (G : Graph; Positions : Position_Array) return Float
   is
      Acc   : Float := 0.0;
      Count : Natural := 0;
      UU, VV : Vertex_Id;
   begin
      Check_Positions (Positions, G.N);
      for E in 1 .. G.E loop
         UU := G.U (E);
         VV := G.V (E);
         if UU /= VV then
            Acc := Acc + Euclidean (Positions (UU), Positions (VV));
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         raise Invalid_Argument;
      end if;
      return Acc / Float (Count);
   end Mean_Edge_Length;

   function Is_Finite (P : Point2D) return Boolean is
   begin
      return P.X'Valid
        and then P.Y'Valid
        and then abs (P.X) < Max_Coord
        and then abs (P.Y) < Max_Coord;
   end Is_Finite;

end Force_Based_Algorithms;
