--  Own tests for BST_Insert_Search (see tests/SOURCES.txt).
--  After inserting distinct values (tree depth <= 5), Contains is set membership.
pragma Ada_2022;
with Ada.Text_IO;
with BST_Insert_Search; use BST_Insert_Search;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

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


   type Seq is array (1 .. 31) of Value;
   S : Seq;
   Cnt : Natural;
   procedure Check_Seq (S : Seq; Cnt : Natural; Label : String) is
      T : Tree := Empty;
      Ok : Boolean := True;
   begin
      for I in 1 .. Cnt loop
         Insert (T, S (I));
      end loop;
      for V in Value loop
         Ok := Ok and then Contains (T, V) = (for some J in 1 .. Cnt => S (J) = V);
      end loop;
      Report (Ok, Label);
   end Check_Seq;
begin
   --  hand cases: sorted inserts give a chain as deep as the number of keys
   for N in 1 .. 31 loop
      Check_Seq ([for I in 1 .. 31 => I], N, "ascending 1 .." & N'Image);
      Check_Seq ([for I in 1 .. 31 => 1000 - I], N, "descending, " & N'Image & " keys");
      Check_Seq ([for I in 1 .. 31 => (if I mod 2 = 1 then -I else I)], N, "zig-zag, " & N'Image & " keys");
   end loop;
   --  random sequences of distinct keys, any shape (up to the full 31 slots); every third run draws
   --  repeated keys from a small range (a repeated key leaves the tree unchanged)
   for K in 1 .. 6_000 loop
      Cnt := Next (0, (if K mod 2 = 0 then 8 else 31));
      for I in 1 .. Cnt loop
         loop
            S (I) := (if K mod 3 = 0 then Next (-6, 6) else Next (-1000, 1000));
            exit when K mod 3 = 0 or else (for all J in 1 .. I - 1 => S (J) /= S (I));
         end loop;
      end loop;
      Check_Seq (S, Cnt, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own set-membership reference)");
end Own_Checks;
