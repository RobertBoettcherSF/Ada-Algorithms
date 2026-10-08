--  Own tests for Convert_BST_To_Greater_Tree (see tests/SOURCES.txt).
--  For a strictly increasing in-order sequence, every output must be the sum of all
--  input values greater than or equal to that element (the greater-tree value).
pragma Ada_2022;
with Ada.Text_IO;
with Convert_BST_To_Greater_Tree; use Convert_BST_To_Greater_Tree;

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

   X : Tree;
   G : Greater_Tree;
   S : Integer;
   Used : array (-100 .. 100) of Boolean;
begin
   for Iter in 1 .. 4_000 loop
      --  16 distinct values, then sorted: a valid in-order BST sequence
      Used := [others => False];
      for I in Index loop
         loop
            X (I) := Next (-100, 100);
            exit when not Used (X (I));
         end loop;
         Used (X (I)) := True;
      end loop;
      declare
         K : Natural := 0;
      begin
         for V in Used'Range loop
            if Used (V) then K := K + 1; X (K) := V; end if;
         end loop;
      end;
      G := Convert (X);
      for I in Index loop
         S := 0;
         for J in Index loop
            if X (J) >= X (I) then S := S + X (J); end if;
         end loop;
         Report (G (I) = S, "random" & Iter'Image);
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own sum-of-greater-or-equal reference)");
end Own_Checks;
