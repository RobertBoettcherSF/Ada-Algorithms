pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Corporate_Flight_Bookings; use Corporate_Flight_Bookings;
--  Own checks (H120): Flight_Totals (R, N) (I) must be the seats of every
--  booking whose range First .. Last contains flight I. Reference: for each
--  flight, add up the bookings that cover it (brute force). Every list of
--  up to 2 bookings on up to 3 flights with 0 .. 2 seats (exhaustive),
--  500 random cases with up to 300 flights / bookings, and 3 cases of 5000
--  flights / bookings with up to Max_Seats seats (seed 20261009,
--  Park-Miller generator).
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Run (R : Request_List; N : Flight; Tag : String) is
      T : constant Total_Array := Flight_Totals (R, N);
      S : Natural;
   begin
      Cases := Cases + 1;
      for I in 1 .. N loop
         S := 0;
         for J in R'Range loop
            if R (J).First <= I and then I <= R (J).Last then
               S := S + R (J).Seats;
            end if;
         end loop;
         if T (I) /= S then
            Fails := Fails + 1;
            if Fails <= 5 then
               Put_Line ("FAIL " & Tag & " flight" & I'Image);
            end if;
            return;
         end if;
      end loop;
   end Run;

   procedure Random_Case (N : Flight; M : Natural; Max_S : Seat_Count; Tag : String) is
      R : Request_List (1 .. M);
      A, B : Flight;
   begin
      for J in 1 .. M loop
         A := 1 + Rand (N);
         B := 1 + Rand (N);
         R (J) := (First => Flight'Min (A, B), Last => Flight'Max (A, B), Seats => Rand (Max_S + 1));
      end loop;
      Run (R, N, Tag);
   end Random_Case;
begin
   --  exhaustive small cases
   for N in 1 .. 3 loop
      Run ([1 .. 0 => (1, 1, 0)], N, "empty");
      for F1 in 1 .. N loop
         for L1 in F1 .. N loop
            for S1 in 0 .. 2 loop
               Run ([1 => (F1, L1, S1)], N, "one booking");
               for F2 in 1 .. N loop
                  for L2 in F2 .. N loop
                     for S2 in 0 .. 2 loop
                        Run ([(F1, L1, S1), (F2, L2, S2)], N, "two bookings");
                     end loop;
                  end loop;
               end loop;
            end loop;
         end loop;
      end loop;
   end loop;
   for T in 1 .. 500 loop
      Random_Case (1 + Rand (300), Rand (301), 1 + Rand (100), "random" & T'Image);
   end loop;
   for T in 1 .. 3 loop
      Random_Case (5_000, 5_000, Max_Seats, "large" & T'Image);
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Corporate_Flight_Bookings own checks:" & Cases'Image & " cases (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " cases");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
