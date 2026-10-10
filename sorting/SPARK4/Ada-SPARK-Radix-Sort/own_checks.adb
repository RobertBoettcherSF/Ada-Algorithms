pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Radix_Sort; use Radix_Sort;
--  Own checks (H144): multi-pass LSD radix sort. Keys 0 .. 255 are two
--  base-16 digits; Pass (A, P, B, Src) must be a stable distribution of A
--  by digit P (P = 1: low digit, P = 2: high digit): B equals an own
--  stable insertion sort of A by that digit, B (J) = A (Src (J)), and Sort
--  must equal Pass 1 followed by Pass 2 with Pass_Count = 2. Keys with
--  equal low digit and different high digit (16#21#, 16#31#) must keep
--  their input order in pass 1; keys with equal high digit (16#22#,
--  16#21#) come out in pass-1 order. Exhaustive: every array of length
--  0 .. 4 over a 6-key set with repeated digits; 3,000 random arrays of
--  length 0 .. 64 (seed 20261010).
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261010;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   function Dig (X : Element; P : Positive) return Natural is
     (if P = 1 then X mod 16 else X / 16);

   --  Own stable reference: insertion sort by digit P (moves only past
   --  strictly larger digits).
   function By_Digit (A : Element_Array; P : Positive) return Element_Array is
      B : Element_Array := A;
      T : Element;
      J : Natural;
   begin
      for I in B'First + 1 .. B'Last loop
         T := B (I);
         J := I;
         while J > B'First and then Dig (B (J - 1), P) > Dig (T, P) loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end By_Digit;

   procedure Run (A : Element_Array; Tag : String) is
      B1, B2 : Element_Array (A'Range);
      S1, S2 : Source_Map (A'Range);
      S      : Element_Array := A;
      Map_Ok : Boolean := True;
   begin
      Pass (A, 1, B1, S1);
      Pass (B1, 2, B2, S2);
      for J in A'Range loop
         Map_Ok := Map_Ok and then B1 (J) = A (S1 (J)) and then B2 (J) = B1 (S2 (J));
      end loop;
      Sort (S);
      Check (B1 = By_Digit (A, 1), Tag & " pass 1 stable by low digit");
      Check (B2 = By_Digit (B1, 2), Tag & " pass 2 stable by high digit");
      Check (Map_Ok, Tag & " source maps");
      Check (S = B2, Tag & " Sort = pass 1 then pass 2");
      Check (Is_Sorted (S), Tag & " sorted");
   end Run;

   Keys : constant array (0 .. 5) of Element := [16#21#, 16#31#, 16#22#, 16#12#, 16#00#, 16#FF#];
begin
   Check (Pass_Count = 2, "two passes for 8-bit keys in base 16");
   declare
      A  : constant Element_Array := [16#21#, 16#31#];
      B  : Element_Array (A'Range);
      Sr : Source_Map (A'Range);
   begin
      Pass (A, 1, B, Sr);
      Check (B = [16#21#, 16#31#], "equal low digit keeps input order in pass 1");
   end;
   declare
      A  : constant Element_Array := [16#22#, 16#21#];
      B1, B2 : Element_Array (A'Range);
      S1, S2 : Source_Map (A'Range);
   begin
      Pass (A, 1, B1, S1);
      Pass (B1, 2, B2, S2);
      Check (B1 = [16#21#, 16#22#] and then B2 = [16#21#, 16#22#] and then S2 (1) = 1,
             "equal high digit comes out in pass-1 order");
   end;
   declare
      A  : constant Element_Array := [16#12#, 16#21#];
      B1 : Element_Array (A'Range);
      S1 : Source_Map (A'Range);
   begin
      Pass (A, 1, B1, S1);
      Check (B1 = [16#21#, 16#12#], "one pass alone does not sort");
   end;
   for L in 0 .. 4 loop
      for Code in 0 .. 6 ** L - 1 loop
         declare
            A : Element_Array (1 .. L);
            C : Natural := Code;
         begin
            for I in A'Range loop
               A (I) := Keys (C mod 6);
               C := C / 6;
            end loop;
            Run (A, "exhaustive L =" & L'Image & " code" & Code'Image);
         end;
      end loop;
   end loop;
   for T in 1 .. 3_000 loop
      declare
         L : constant Natural := Rand (Max_N + 1);
         O : constant Positive := 1 + Rand (Max_N - L + 1);
         A : Element_Array (O .. O + L - 1);
      begin
         for I in A'Range loop
            A (I) := (if T mod 2 = 0 then Rand (256) else Keys (Rand (6)));
         end loop;
         Run (A, "random" & T'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Radix_Sort own checks:" & Cases'Image & " checks (seed 20261010)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
