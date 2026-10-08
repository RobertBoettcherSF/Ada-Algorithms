--  Own tests for Coin_Change_II (see tests/SOURCES.txt).
--  Combinations (A, D, N) must be the number of multisets of the first N (distinct)
--  denominations that sum to A, for A >= 1.
pragma Ada_2022;
with Ada.Text_IO;
with Coin_Change_II; use Coin_Change_II;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   D : Coins;
   function Ref (A : Natural; From, N : Positive) return Natural is
      --  multisets of coins D (From .. N) summing to A
      R : Natural := 0;
   begin
      if A = 0 then return 1; end if;
      if From > N then return 0; end if;
      for K in 0 .. A / D (From) loop
         R := R + Ref (A - K * D (From), From + 1, N);
      end loop;
      return R;
   end Ref;
begin
   --  every set of distinct denominations (as an ordered array), every A in 1 .. 4, every N
   for C1 in Coin loop
      for C2 in Coin loop
         for C3 in Coin loop
            for C4 in Coin loop
               D := [C1, C2, C3, C4];
               for N in 0 .. 4 loop
                  if (for all I in 1 .. N => (for all J in 1 .. I - 1 => D (I) /= D (J))) then
                     for A in 1 .. 4 loop
                        Report (Combinations (A, D, N) = (if N = 0 then 0 else Ref (A, 1, N)), "case");
                     end loop;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own multiset-enumeration reference, exhaustive)");
end Own_Checks;
