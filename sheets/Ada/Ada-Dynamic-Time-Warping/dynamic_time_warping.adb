--  Dynamic_Time_Warping body — classic DTW DP with fixed Max_Len pool
--  and optional Sakoe–Chiba band.

pragma Ada_2022;

package body Dynamic_Time_Warping
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local cost
   -------------------------------------------------------------------------

   function Local_Cost (A, B : Integer) return Natural is
   begin
      if A >= B then
         return Natural (A - B);
      else
         return Natural (B - A);
      end if;
   end Local_Cost;

   -------------------------------------------------------------------------
   -- Index helpers (arbitrary Positive bounds on Series)
   -------------------------------------------------------------------------

   function At_X (X : Series; I : Positive) return Integer is
     (X (X'First + (I - 1)));

   function At_Y (Y : Series; J : Positive) return Integer is
     (Y (Y'First + (J - 1)));

   -------------------------------------------------------------------------
   -- Validate lengths
   -------------------------------------------------------------------------

   procedure Check_Lengths (M, N : Natural) is
   begin
      if M = 0 or else N = 0 then
         raise Invalid_Argument;
      end if;
      if M > Max_Len or else N > Max_Len then
         raise Invalid_Argument;
      end if;
   end Check_Lengths;

   -------------------------------------------------------------------------
   -- Unconstrained Distance
   -------------------------------------------------------------------------

   function Distance (X, Y : Series) return Natural is
      M : constant Natural := X'Length;
      N : constant Natural := Y'Length;

      --  Fixed educational DP pool (1-based series indices).
      type Cost_Matrix is array (Positive range <>, Positive range <>)
        of Natural;
      DTW : Cost_Matrix (1 .. M, 1 .. N);

      function Min3 (A, B, C : Natural) return Natural is
         R : Natural := A;
      begin
         if B < R then
            R := B;
         end if;
         if C < R then
            R := C;
         end if;
         return R;
      end Min3;
   begin
      Check_Lengths (M, N);

      DTW (1, 1) := Local_Cost (At_X (X, 1), At_Y (Y, 1));

      for J in 2 .. N loop
         DTW (1, J) :=
           DTW (1, J - 1) + Local_Cost (At_X (X, 1), At_Y (Y, J));
      end loop;

      for I in 2 .. M loop
         DTW (I, 1) :=
           DTW (I - 1, 1) + Local_Cost (At_X (X, I), At_Y (Y, 1));
      end loop;

      for I in 2 .. M loop
         for J in 2 .. N loop
            DTW (I, J) :=
              Local_Cost (At_X (X, I), At_Y (Y, J))
              + Min3 (DTW (I - 1, J), DTW (I, J - 1), DTW (I - 1, J - 1));
         end loop;
      end loop;

      return DTW (M, N);
   end Distance;

   -------------------------------------------------------------------------
   -- Sakoe–Chiba banded Distance
   -------------------------------------------------------------------------

   function Distance (X, Y : Series; Window : Natural) return Natural is
      M : constant Natural := X'Length;
      N : constant Natural := Y'Length;

      --  Sentinel larger than any feasible educational path cost built from
      --  modest Integer samples under Max_Len (avoids mixing with "real"
      --  Natural'Last arithmetic surprises in Min3).
      Inf : constant Natural := Natural'Last / 4;

      type Cost_Matrix is array (Positive range <>, Positive range <>)
        of Natural;
      DTW : Cost_Matrix (1 .. M, 1 .. N);

      Diff : Natural;
      J_Lo, J_Hi : Integer;

      function Min3 (A, B, C : Natural) return Natural is
         R : Natural := A;
      begin
         if B < R then
            R := B;
         end if;
         if C < R then
            R := C;
         end if;
         return R;
      end Min3;

      function In_Band (I, J : Positive) return Boolean is
         D : constant Integer := Integer (I) - Integer (J);
      begin
         if D >= 0 then
            return Natural (D) <= Window;
         else
            return Natural (-D) <= Window;
         end if;
      end In_Band;

      function Cell (I, J : Integer) return Natural is
      begin
         if I < 1 or else J < 1 or else I > M or else J > N then
            return Inf;
         end if;
         return DTW (I, J);
      end Cell;
   begin
      Check_Lengths (M, N);

      if M >= N then
         Diff := M - N;
      else
         Diff := N - M;
      end if;
      if Window < Diff then
         raise Invalid_Argument;
      end if;

      --  Initialise all cells to Inf; fill admissible band.
      for I in 1 .. M loop
         for J in 1 .. N loop
            DTW (I, J) := Inf;
         end loop;
      end loop;

      DTW (1, 1) := Local_Cost (At_X (X, 1), At_Y (Y, 1));

      for J in 2 .. N loop
         if In_Band (1, J) then
            DTW (1, J) :=
              DTW (1, J - 1) + Local_Cost (At_X (X, 1), At_Y (Y, J));
         end if;
      end loop;

      for I in 2 .. M loop
         if In_Band (I, 1) then
            DTW (I, 1) :=
              DTW (I - 1, 1) + Local_Cost (At_X (X, I), At_Y (Y, 1));
         end if;
      end loop;

      for I in 2 .. M loop
         J_Lo := Integer (I) - Integer (Window);
         if J_Lo < 2 then
            J_Lo := 2;
         end if;
         J_Hi := Integer (I) + Integer (Window);
         if J_Hi > N then
            J_Hi := N;
         end if;
         for J in J_Lo .. J_Hi loop
            DTW (I, J) :=
              Local_Cost (At_X (X, I), At_Y (Y, J))
              + Min3 (Cell (I - 1, J), Cell (I, J - 1), Cell (I - 1, J - 1));
         end loop;
      end loop;

      if DTW (M, N) >= Inf then
         --  Should not occur when Window ≥ |M-N|; treat as invalid band.
         raise Invalid_Argument;
      end if;

      return DTW (M, N);
   end Distance;

end Dynamic_Time_Warping;
