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
   pragma Warnings (Off, Next);

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

   type Seq is array (1 .. 31) of Value;
   S : Seq;
   Cnt : Natural;
   --  own model of the unbalanced BST: depth of each inserted key
   function Depth_Ok (S : Seq; N : Natural) return Boolean is
      D : Natural;
   begin
      for I in 1 .. N loop
         --  depth of S (I) = 1 + number of earlier keys on its search path
         D := 1;
         for J in 1 .. I - 1 loop
            declare
               On_Path : Boolean := True;
            begin
               --  S (J) is an ancestor of S (I) iff no earlier key lies strictly between them
               for M in 1 .. J - 1 loop
                  if (S (M) > S (J) and then S (M) < S (I)) or else (S (M) < S (J) and then S (M) > S (I)) then
                     On_Path := False;
                  end if;
               end loop;
               if On_Path then
                  D := D + 1;
               end if;
            end;
         end loop;
         if D > 5 then
            return False;
         end if;
      end loop;
      return True;
   end Depth_Ok;
begin
   for K in 1 .. 4_000 loop
      Cnt := Next (0, (if K mod 2 = 0 then 8 else 20));
      for I in 1 .. Cnt loop
         loop
            S (I) := Next (-30, 30);
            exit when (for all J in 1 .. I - 1 => S (J) /= S (I));
         end loop;
      end loop;
      if Depth_Ok (S, Cnt) then
         declare
            T : Tree := Empty;
            Ok : Boolean := True;
         begin
            for I in 1 .. Cnt loop
               Insert (T, S (I));
            end loop;
            for V in -32 .. 32 loop
               Ok := Ok and then Contains (T, V) = (for some J in 1 .. Cnt => S (J) = V);
            end loop;
            Report (Ok, "random" & K'Image);
         end;
      end if;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own set-membership reference)");
end Own_Checks;
