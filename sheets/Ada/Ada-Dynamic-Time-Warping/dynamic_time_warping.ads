--  Dynamic_Time_Warping — Ada 2023 educational package for classic
--  Dynamic Time Warping (DTW): optimal monotonic alignment cost between
--  two integer sequences under absolute local cost.
--  Recurrence: DTW(i,j) = |X_i - Y_j| + min(DTW(i-1,j), DTW(i,j-1),
--  DTW(i-1,j-1)) with cumulative first row/column.
--  Optional Sakoe–Chiba band window is provided.
--  Primary source:
--  https://en.wikipedia.org/wiki/Dynamic_time_warping

pragma Ada_2022;

package Dynamic_Time_Warping
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational fixed DP pool)
   ---------------------------------------------------------------------------

   --  Maximum length of each input series. The DP table is sized to
   --  Max_Len × Max_Len. Inputs longer than Max_Len raise Invalid_Argument.
   Max_Len : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Types
   ---------------------------------------------------------------------------

   --  One temporal sequence of integer samples. Any Positive bounds are
   --  accepted (First need not be 1); Length is what matters.
   type Series is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * either series is empty, or
   --    * either length exceeds Max_Len, or
   --    * (windowed) Window < |X'Length - Y'Length| (band cannot cover
   --      the ends under Sakoe–Chiba constraints).

   ---------------------------------------------------------------------------
   -- Distance (classic unconstrained DTW)
   ---------------------------------------------------------------------------

   function Distance (X, Y : Series) return Natural;
   --  Classic DTW path cost with local cost d(x,y) = |x - y|.
   --  Empty series or length > Max_Len → Invalid_Argument.
   --  Identical nonempty series → 0. Symmetric: Distance(X,Y)=Distance(Y,X).

   ---------------------------------------------------------------------------
   -- Distance with Sakoe–Chiba band
   ---------------------------------------------------------------------------

   function Distance (X, Y : Series; Window : Natural) return Natural;
   --  Same local cost and recurrence, but cell (i,j) is admissible only
   --  when |i - j| ≤ Window (1-based indices along each series).
   --  Requires Window ≥ |X'Length - Y'Length|; otherwise Invalid_Argument.
   --  Window ≥ max(X'Length, Y'Length) recovers unconstrained DTW.

   ---------------------------------------------------------------------------
   -- Local cost helper (public for education / tests)
   ---------------------------------------------------------------------------

   function Local_Cost (A, B : Integer) return Natural;
   --  Absolute difference |A - B| without using Ada's abs (avoids
   --  overflow on Integer'First).

end Dynamic_Time_Warping;
