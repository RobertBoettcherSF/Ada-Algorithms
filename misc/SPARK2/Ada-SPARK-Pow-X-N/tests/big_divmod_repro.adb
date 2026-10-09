pragma Ada_2022;
--  Big_Integers "/", "mod" and "rem" against Long_Long_Integer for every
--  A in -12 .. 12 and nonzero B in -6 .. 6, plus +/-1_999_999_999 with
--  +/-7 (see SOURCES.txt). Operands are variables. Not part of the build:
--    gnatmake -gnat2022 big_divmod_repro.adb && ./big_divmod_repro
--  GNAT 14.2 and 12.2: "/" and "rem" agree everywhere; "mod" is wrong in
--  44 of 912 checks, exactly when A > 0, B < 0 and B does not divide A
--  (11 mod -5 gives -6 instead of -4).
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
procedure Big_Divmod_Repro is
   Bad   : Natural := 0;
   Total : Natural := 0;

   procedure Check (Op : String; A, B : Long_Long_Integer; Got : Big_Integer; Want : Long_Long_Integer) is
   begin
      Total := Total + 1;
      if Got /= To_Big_Integer (Integer (Want)) then
         Bad := Bad + 1;
         Put_Line ("mismatch:" & A'Image & " " & Op & B'Image & " gives " & To_String (Got)
                   & ", Long_Long_Integer gives" & Want'Image);
      end if;
   end Check;

   procedure Check_All (A, B : Long_Long_Integer) is
      X : constant Big_Integer := To_Big_Integer (Integer (A));
      Y : constant Big_Integer := To_Big_Integer (Integer (B));
   begin
      Check ("/", A, B, X / Y, A / B);
      Check ("mod", A, B, X mod Y, A mod B);
      Check ("rem", A, B, X rem Y, A rem B);
   end Check_All;
begin
   for A in Long_Long_Integer range -12 .. 12 loop
      for B in Long_Long_Integer range -6 .. 6 loop
         if B /= 0 then
            Check_All (A, B);
         end if;
      end loop;
   end loop;
   for SA in Long_Long_Integer range -1 .. 1 loop
      for SB in Long_Long_Integer range -1 .. 1 loop
         if SA /= 0 and then SB /= 0 then
            Check_All (SA * 1_999_999_999, SB * 7);
         end if;
      end loop;
   end loop;
   Put_Line ("checked" & Total'Image & ", mismatches" & Bad'Image);
end Big_Divmod_Repro;
