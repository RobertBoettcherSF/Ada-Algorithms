pragma Ada_2022;

-- Positive-Negative Counter (PN-Counter) CRDT sheet.
-- Merge is componentwise max of the P and N vectors;
-- Value is sum(P) - sum(N). Bounded actors; no heap/access.
package Pn_Counter
  with SPARK_Mode => On
is
   Max_Actors : constant Positive := 4;
   subtype Actor_Id is Positive range 1 .. Max_Actors;

   -- Per-actor tick bound keeps sums inside Integer'range for Level-2 proof.
   Max_Ticks : constant := 16;
   subtype Tick is Natural range 0 .. Max_Ticks;

   type Counter is private;

   function Empty return Counter
     with Global => null;

   function P_At (C : Counter; Who : Actor_Id) return Tick
     with Global => null;

   function N_At (C : Counter; Who : Actor_Id) return Tick
     with Global => null;

   function Value (C : Counter) return Integer
     with Global => null,
          Post   => Value'Result in
            -(Max_Actors * Max_Ticks) .. Max_Actors * Max_Ticks;

   procedure Increment (C : in out Counter; Who : Actor_Id)
     with Global => null,
          Pre    => P_At (C, Who) < Max_Ticks,
          Post   => P_At (C, Who) = P_At (C'Old, Who) + 1
            and then N_At (C, Who) = N_At (C'Old, Who)
            and then (for all A in Actor_Id =>
                        (if A /= Who then
                           P_At (C, A) = P_At (C'Old, A)
                           and then N_At (C, A) = N_At (C'Old, A)));

   procedure Decrement (C : in out Counter; Who : Actor_Id)
     with Global => null,
          Pre    => N_At (C, Who) < Max_Ticks,
          Post   => N_At (C, Who) = N_At (C'Old, Who) + 1
            and then P_At (C, Who) = P_At (C'Old, Who)
            and then (for all A in Actor_Id =>
                        (if A /= Who then
                           P_At (C, A) = P_At (C'Old, A)
                           and then N_At (C, A) = N_At (C'Old, A)));

   procedure Merge (Into : in out Counter; Other : Counter)
     with Global => null,
          Post   =>
            (for all A in Actor_Id =>
               P_At (Into, A) =
                 Tick'Max (P_At (Into'Old, A), P_At (Other, A))
               and then N_At (Into, A) =
                 Tick'Max (N_At (Into'Old, A), N_At (Other, A)));

private
   type Tick_Vector is array (Actor_Id) of Tick;

   type Counter is record
      P : Tick_Vector;
      N : Tick_Vector;
   end record;

   function P_At (C : Counter; Who : Actor_Id) return Tick is (C.P (Who));
   function N_At (C : Counter; Who : Actor_Id) return Tick is (C.N (Who));
end Pn_Counter;
