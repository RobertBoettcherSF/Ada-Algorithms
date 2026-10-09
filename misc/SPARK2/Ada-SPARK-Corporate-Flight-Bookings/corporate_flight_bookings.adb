pragma Ada_2022;
package body Corporate_Flight_Bookings with SPARK_Mode => On is
   --  The lemmas, loop invariants and assertions below quantify over every
   --  flight with recursive prefix sums (proof only; quadratic or worse when
   --  executed). The spec Post of Flight_Totals still runs.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);
   function Booked_Seats (B : Bookings) return Total_Seats is
      Result : Total_Seats := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Result <= Seats'Last * (I - Index'First));
         Result := Result + B (I).Count;
      end loop;
      return Result;
   end Booked_Seats;

   --  Difference array over flights 1 .. Max_Flights + 1 (the entry after
   --  a booking's Last takes its seats back off).
   subtype Diff_Index is Positive range 1 .. Max_Flights + 1;
   subtype Diff_Value is Integer range -Max_Bookings * Max_Seats .. Max_Bookings * Max_Seats;
   type Diff_Array is array (Diff_Index) of Diff_Value;

   --  Sum of D (1 .. F) (proof only).
   function Prefix (D : Diff_Array; F : Natural) return Long_Long_Integer is
     (if F = 0 then 0 else Prefix (D, F - 1) + Long_Long_Integer (D (F)))
     with Ghost, Pre => F <= Diff_Index'Last, Subprogram_Variant => (Decreases => F),
          Post => Prefix'Result in -(Long_Long_Integer (F) * (Max_Bookings * Max_Seats)) .. Long_Long_Integer (F) * (Max_Bookings * Max_Seats);

   --  All-zero array: every prefix is 0.
   procedure Lemma_Zero (D : Diff_Array)
     with Ghost, Pre => (for all K in Diff_Index => D (K) = 0),
          Post => (for all F in 0 .. Diff_Index'Last => Prefix (D, F) = 0)
   is
   begin
      for F in 1 .. Diff_Index'Last loop
         pragma Loop_Invariant (for all G in 0 .. F - 1 => Prefix (D, G) = 0);
         pragma Assert (Prefix (D, F) = Prefix (D, F - 1));
      end loop;
   end Lemma_Zero;

   --  Adding S at position P adds S to every prefix from P on.
   procedure Lemma_Update (Old, New_D : Diff_Array; P : Diff_Index; S : Integer)
     with Ghost,
          Pre  => S in -Max_Seats .. Max_Seats
                  and then Long_Long_Integer (New_D (P)) = Long_Long_Integer (Old (P)) + Long_Long_Integer (S)
                  and then (for all K in Diff_Index => (if K /= P then New_D (K) = Old (K))),
          Post => (for all F in 0 .. Diff_Index'Last =>
                     Prefix (New_D, F) = Prefix (Old, F) + (if F >= P then Long_Long_Integer (S) else 0))
   is
   begin
      for F in 1 .. Diff_Index'Last loop
         pragma Loop_Invariant
           (for all G in 0 .. F - 1 =>
              Prefix (New_D, G) = Prefix (Old, G) + (if G >= P then Long_Long_Integer (S) else 0));
         pragma Assert (Prefix (New_D, F) = Prefix (New_D, F - 1) + Long_Long_Integer (New_D (F)));
      end loop;
   end Lemma_Update;

   function Flight_Totals (R : Request_List; N : Flight) return Total_Array is
      D      : Diff_Array := [others => 0];
      Result : Total_Array (1 .. N) := [others => 0];
      Run    : Long_Long_Integer := 0;
   begin
      Lemma_Zero (D);
      for J in R'Range loop
         pragma Loop_Invariant
           (for all F in 1 .. N => Prefix (D, F) = Covered (R, F, J - 1));
         pragma Loop_Invariant
           (for all K in Diff_Index => D (K) in -((J - 1) * Max_Seats) .. (J - 1) * Max_Seats);
         declare
            D0 : constant Diff_Array := D with Ghost;
            D1 : Diff_Array with Ghost;
            S  : constant Seat_Count := R (J).Seats;
         begin
            D (R (J).First) := D (R (J).First) + S;
            D1 := D;
            Lemma_Update (D0, D1, R (J).First, S);
            D (R (J).Last + 1) := D (R (J).Last + 1) - S;
            Lemma_Update (D1, D, R (J).Last + 1, -S);
            pragma Assert
              (for all F in 1 .. N =>
                 Prefix (D, F) = Covered (R, F, J - 1)
                   + (if R (J).First <= F and then F <= R (J).Last then Long_Long_Integer (S) else 0));
         end;
      end loop;
      pragma Assert (for all F in 1 .. N => Prefix (D, F) = Covered (R, F, R'Last));
      for F in 1 .. N loop
         pragma Loop_Invariant (Run = Prefix (D, F - 1));
         pragma Loop_Invariant
           (for all G in 1 .. F - 1 => Long_Long_Integer (Result (G)) = Covered (R, G, R'Last));
         Run := Run + Long_Long_Integer (D (F));
         pragma Assert (Run = Covered (R, F, R'Last));
         Result (F) := Flight_Total (Run);
      end loop;
      return Result;
   end Flight_Totals;
end Corporate_Flight_Bookings;
