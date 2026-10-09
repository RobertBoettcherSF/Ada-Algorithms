pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Zigzag_Iterator_Stub; use Zigzag_Iterator_Stub;
--  Own checks (H115): the zigzag order of two lists of 0 .. 1000 values
--  (A (1), B (1), A (2), B (2), ...; the rest of the longer list at the
--  end), built independently as "for I: A (I) if any, then B (I) if any",
--  against the iterator. Every pair of lengths in 0 .. 12, and 3,000 random
--  pairs of lengths in 0 .. 1000 (seed 20261009, Park-Miller generator).
procedure Own_Checks is
   Max_Len : constant := 1_000;
   Fails   : Natural := 0;
   Ops     : Natural := 0;
   Seed    : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Ops := Ops + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   type Ref_Array is array (1 .. 2 * Max_Len) of Integer;

   procedure Trace (LA, LB : Natural) is
      RA, RB, Want : Ref_Array := [others => 0];
      N : Natural := 0;
      Tag : constant String := " lengths" & LA'Image & LB'Image;
   begin
      for I in 1 .. LA loop
         RA (I) := Rand (201) - 100;
      end loop;
      for I in 1 .. LB loop
         RB (I) := Rand (201) - 100;
      end loop;
      for I in 1 .. Natural'Max (LA, LB) loop
         if I <= LA then
            N := N + 1;
            Want (N) := RA (I);
         end if;
         if I <= LB then
            N := N + 1;
            Want (N) := RB (I);
         end if;
      end loop;
      declare
         A, B : Value_Array := [others => 0];
      begin
         for I in 1 .. LA loop
            A (I) := RA (I);
         end loop;
         for I in 1 .. LB loop
            B (I) := RB (I);
         end loop;
         declare
            It : Iterator := Create (A, LA, B, LB);
            V  : Value;
         begin
            for K in 1 .. N loop
               Check (Has_Next (It), "Has_Next" & Tag);
               Next (It, V);
               Check (V = Want (K), "value" & K'Image & Tag);
            end loop;
            Check (not Has_Next (It), "end" & Tag);
         end;
      end;
   exception
      when Constraint_Error =>
         Check (False, "rejected" & Tag);
   end Trace;
begin
   for LA in 0 .. 12 loop
      for LB in 0 .. 12 loop
         Trace (LA, LB);
      end loop;
   end loop;
   Trace (Max_Len, Max_Len);
   Trace (Max_Len, 0);
   Trace (0, Max_Len);
   for T in 1 .. 3_000 loop
      Trace (Rand (Max_Len + 1), Rand (Max_Len + 1));
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Zigzag_Iterator own checks:" & Ops'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Ops'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
