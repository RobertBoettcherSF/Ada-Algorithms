pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Lemke_Howson; use Lemke_Howson;

--  Expected values: see tests/SOURCES.txt.  Every result is checked with
--  this file's own exact best-response check (Big_Integer, not the
--  package's Is_Nash), for every starting label; games with known
--  equilibria also check the result is one of them (worked by hand).
procedure Tests is
   Failures : Natural := 0;
   Checks   : Natural := 0;

   procedure Check (Ok : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL " & Label);
      end if;
   end Check;

   function B (V : Integer) return Big_Integer renames To_Big_Integer;

   --  Own check: X / Dx, Y / Dy are mixed strategies and best responses.
   function Own_Nash (A, Bm : Payoff_Matrix; E : Exact_Equilibrium) return Boolean is
      M : constant Positive := A'Last (1);
      N : constant Positive := A'Last (2);
      SX, SY : Big_Integer := B (0);
      PA : array (1 .. M) of Big_Integer := [others => B (0)];
      PB : array (1 .. N) of Big_Integer := [others => B (0)];
      Best : Big_Integer;
   begin
      for I in 1 .. M loop
         if E.X (I) < B (0) then return False; end if;
         SX := SX + E.X (I);
      end loop;
      for J in 1 .. N loop
         if E.Y (J) < B (0) then return False; end if;
         SY := SY + E.Y (J);
      end loop;
      if SX /= E.Dx or else SY /= E.Dy or else E.Dx <= B (0) or else E.Dy <= B (0) then
         return False;
      end if;
      for I in 1 .. M loop
         for J in 1 .. N loop
            PA (I) := PA (I) + B (A (I, J)) * E.Y (J);
            PB (J) := PB (J) + B (Bm (I, J)) * E.X (I);
         end loop;
      end loop;
      Best := PA (1);
      for I in 2 .. M loop
         if PA (I) > Best then Best := PA (I); end if;
      end loop;
      for I in 1 .. M loop
         if E.X (I) > B (0) and then PA (I) /= Best then return False; end if;
      end loop;
      Best := PB (1);
      for J in 2 .. N loop
         if PB (J) > Best then Best := PB (J); end if;
      end loop;
      for J in 1 .. N loop
         if E.Y (J) > B (0) and then PB (J) /= Best then return False; end if;
      end loop;
      return True;
   end Own_Nash;

   type Int_Vector is array (Positive range <>) of Natural;

   --  E is found and its strategies equal Num_X / Den_X and Num_Y / Den_Y
   --  exactly (Dx, Dy > 0: zero vectors would match any fraction).
   function Equals (E : Exact_Equilibrium; Num_X : Int_Vector; Den_X : Positive;
                Num_Y : Int_Vector; Den_Y : Positive) return Boolean is
     (E.Found and then E.Dx > B (0) and then E.Dy > B (0)
      and then (for all I in 1 .. E.M => E.X (I) * B (Den_X) = B (Num_X (I)) * E.Dx)
      and then (for all J in 1 .. E.N => E.Y (J) * B (Den_Y) = B (Num_Y (J)) * E.Dy));

   procedure All_Drops (Name : String; A, Bm : Payoff_Matrix) is
   begin
      for D in 1 .. A'Last (1) + A'Last (2) loop
         declare
            E : constant Exact_Equilibrium := Find_Equilibrium (A, Bm, D);
         begin
            Check (E.Found and then Own_Nash (A, Bm, E), Name & " drop" & D'Image & ": equilibrium");
         end;
      end loop;
   end All_Drops;

   L  : constant Integer := Integer'Last;
   F  : constant Integer := Integer'First;
begin
   --  Battle of the sexes: (1,0)/(1,0), (0,1)/(0,1), (3/5,2/5)/(2/5,3/5).
   declare
      A  : constant Payoff_Matrix := [[3, 0], [0, 2]];
      Bm : constant Payoff_Matrix := [[2, 0], [0, 3]];
   begin
      All_Drops ("BoS", A, Bm);
      for D in 1 .. 4 loop
         declare
            E : constant Exact_Equilibrium := Find_Equilibrium (A, Bm, D);
         begin
            Check (Equals (E, [1, 0], 1, [1, 0], 1) or else Equals (E, [0, 1], 1, [0, 1], 1)
                   or else Equals (E, [3, 2], 5, [2, 3], 5), "BoS drop" & D'Image & ": one of the three");
         end;
      end loop;
   end;

   --  Matching pennies: only (1/2,1/2)/(1/2,1/2).
   declare
      A  : constant Payoff_Matrix := [[1, -1], [-1, 1]];
      Bm : constant Payoff_Matrix := [[-1, 1], [1, -1]];
   begin
      for D in 1 .. 4 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1, 1], 2, [1, 1], 2), "pennies drop" & D'Image);
      end loop;
   end;

   --  Prisoner's dilemma: only (0,1)/(0,1).
   declare
      A  : constant Payoff_Matrix := [[3, 0], [5, 1]];
      Bm : constant Payoff_Matrix := [[3, 5], [0, 1]];
   begin
      for D in 1 .. 4 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [0, 1], 1, [0, 1], 1), "PD drop" & D'Image);
      end loop;
   end;

   --  Hawk-dove: (1,0)/(0,1), (0,1)/(1,0), (1/2,1/2)/(1/2,1/2).
   declare
      A  : constant Payoff_Matrix := [[0, 3], [1, 2]];
      Bm : constant Payoff_Matrix := [[0, 1], [3, 2]];
   begin
      All_Drops ("hawk-dove", A, Bm);
      for D in 1 .. 4 loop
         declare
            E : constant Exact_Equilibrium := Find_Equilibrium (A, Bm, D);
         begin
            Check (Equals (E, [1, 0], 1, [0, 1], 1) or else Equals (E, [0, 1], 1, [1, 0], 1)
                   or else Equals (E, [1, 1], 2, [1, 1], 2), "hawk-dove drop" & D'Image & ": one of the three");
         end;
      end loop;
   end;

   --  Rock-paper-scissors: only the uniform pair.
   declare
      A  : constant Payoff_Matrix := [[0, -1, 1], [1, 0, -1], [-1, 1, 0]];
      Bm : constant Payoff_Matrix := [[0, 1, -1], [-1, 0, 1], [1, -1, 0]];
   begin
      for D in 1 .. 6 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1, 1, 1], 3, [1, 1, 1], 3), "RPS drop" & D'Image);
      end loop;
   end;

   --  1 x 1.
   Check (Equals (Find_Equilibrium ([[10]], [[5]], 1), [1], 1, [1], 1), "1x1 drop 1");
   Check (Equals (Find_Equilibrium ([[10]], [[5]], 2), [1], 1, [1], 1), "1x1 drop 2");

   --  All payoffs negative: row 1 dominates, then column 2: (1,0)/(0,1).
   declare
      A  : constant Payoff_Matrix := [[-10, -20], [-30, -40]];
      Bm : constant Payoff_Matrix := [[-40, -30], [-20, -10]];
   begin
      for D in 1 .. 4 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1, 0], 1, [0, 1], 1), "negative drop" & D'Image);
      end loop;
   end;

   --  Degenerate 2 x 3: column 3 strictly dominates, and against it both
   --  rows pay 1, so every x with y = (0, 0, 1) is an equilibrium.
   declare
      A  : constant Payoff_Matrix := [[2, 0, 1], [0, 3, 1]];
      Bm : constant Payoff_Matrix := [[1, 0, 2], [0, 1, 2]];
   begin
      All_Drops ("2x3 degenerate", A, Bm);
      for D in 1 .. 5 loop
         declare
            E : constant Exact_Equilibrium := Find_Equilibrium (A, Bm, D);
         begin
            Check (E.Y (1) = B (0) and then E.Y (2) = B (0), "2x3 degenerate drop" & D'Image & ": y = (0,0,1)");
         end;
      end loop;
   end;

   --  Degenerate 3 x 3 games (ties), found by a seeded search where the
   --  old floating-point code returned a non-equilibrium: drop 1 gave
   --  x = (1,0,0) against y = (2/3,0,1/3), where row 1 pays 1/3 and rows 2
   --  and 3 pay 4/3; and x = (1/2,1/2,0) against y = (3/5,0,2/5), where
   --  row 1 pays 2/5, row 2 pays 9/5.
   All_Drops ("degenerate 1", [[0, 1, 1], [1, 2, 2], [2, 1, 0]], [[0, 0, 0], [0, 0, 2], [1, 0, 2]]);
   All_Drops ("degenerate 2", [[0, 1, 1], [3, 0, 0], [1, 1, 3]], [[3, 3, 1], [1, 0, 3], [0, 1, 0]]);
   --  Everything ties.
   All_Drops ("all equal 3x3", [[1, 1, 1], [1, 1, 1], [1, 1, 1]], [[1, 1, 1], [1, 1, 1], [1, 1, 1]]);
   All_Drops ("all zero 5x5", [for I in 1 .. 5 => [for J in 1 .. 5 => 0]], [for I in 1 .. 5 => [for J in 1 .. 5 => 0]]);

   --  Payoffs at the Integer limits: matching pennies times Integer'Last
   --  (still only the halves), and with Integer'First in it.
   declare
      A  : constant Payoff_Matrix := [[L, -L], [-L, L]];
      Bm : constant Payoff_Matrix := [[-L, L], [L, -L]];
   begin
      for D in 1 .. 4 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1, 1], 2, [1, 1], 2), "pennies * Integer'Last drop" & D'Image);
      end loop;
      All_Drops ("Integer'First", [[F, L], [L, F]], [[L, F], [F, L]]);
   end;

   --  Rock-paper-scissors-lizard-spock times Integer'Last: strategy i beats
   --  i + 1 and i + 2 (mod 5) and loses to the other two; the uniform pair
   --  is the only equilibrium.  The pivots multiply 32-bit numbers, so the
   --  intermediate products need far more than 64 bits.
   declare
      function W (I, J : Positive) return Integer is
        (case (J - I) mod 5 is when 1 | 2 => -L, when 3 | 4 => L, when others => 0);
      A  : constant Payoff_Matrix := [for I in 1 .. 5 => [for J in 1 .. 5 => W (I, J)]];
      Bm : constant Payoff_Matrix := [for I in 1 .. 5 => [for J in 1 .. 5 => -W (I, J)]];
   begin
      for D in 1 .. 10 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1, 1, 1, 1, 1], 5, [1, 1, 1, 1, 1], 5), "RPSLS * Integer'Last drop" & D'Image);
      end loop;
   end;

   --  A 5 x 5 game with payoffs spread over all of Integer (Park-Miller
   --  sequence from seed 20261009, mapped to Integer'First + 1 .. Integer'Last).
   declare
      S  : Long_Long_Integer := 20_261_009;
      function Next return Integer is
      begin
         S := (S * 16_807) mod 2_147_483_647;
         return Integer (2 * S - 2_147_483_647);
      end Next;
      A, Bm : Payoff_Matrix (1 .. 5, 1 .. 5);
   begin
      for I in 1 .. 5 loop
         for J in 1 .. 5 loop
            A (I, J) := Next;
            Bm (I, J) := Next;
         end loop;
      end loop;
      All_Drops ("5x5 full Integer range", A, Bm);
   end;

   --  1 x 4, the smallest payoff of A at (1, 3), not (1, 1): player 2's
   --  only best reply to the single row is column 2 (B = 2 there, -1
   --  elsewhere), so the only equilibrium is (1)/(0,1,0,0).
   declare
      A  : constant Payoff_Matrix := [[1, 1, -2, 2]];
      Bm : constant Payoff_Matrix := [[-1, 2, -1, -1]];
   begin
      for D in 1 .. 5 loop
         Check (Equals (Find_Equilibrium (A, Bm, D), [1], 1, [0, 1, 0, 0], 1), "1x4 minimum off (1,1) drop" & D'Image);
      end loop;
   end;

   --  Every 2 x 2 game with payoffs in -1 .. 1 (many ties; the smallest
   --  payoff is often away from (1, 1), which the shift to positive
   --  payoffs must find): every starting label gives an equilibrium.
   declare
      Bad : Natural := 0;
   begin
      for Code in 0 .. 3 ** 8 - 1 loop
         declare
            A, Bm : Payoff_Matrix (1 .. 2, 1 .. 2);
            C     : Natural := Code;
         begin
            for I in 1 .. 2 loop
               for J in 1 .. 2 loop
                  A (I, J) := C mod 3 - 1;
                  C := C / 3;
                  Bm (I, J) := C mod 3 - 1;
                  C := C / 3;
               end loop;
            end loop;
            for D in 1 .. 4 loop
               declare
                  E : constant Exact_Equilibrium := Find_Equilibrium (A, Bm, D);
               begin
                  if not (E.Found and then Own_Nash (A, Bm, E)) then
                     Bad := Bad + 1;
                  end if;
               end;
            end loop;
         end;
      end loop;
      Check (Bad = 0, "all 2x2 games with payoffs -1 .. 1, every drop:" & Bad'Image & " not an equilibrium");
   end;

   if Failures = 0 then
      Put_Line ("PASS Lemke_Howson (" & Checks'Image & " checks)");
   else
      Put_Line ("FAIL Lemke_Howson:" & Failures'Image & " of" & Checks'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
