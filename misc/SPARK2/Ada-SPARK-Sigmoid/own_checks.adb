pragma Ada_2022;
--  Own checks for Sigmoid (independent of the package's exact Taylor
--  series), see tests/SOURCES.txt:
--  * every X_Milli in -30000 .. 30000 against round half up of
--    50 (1 + tanh (x / 2)) in Long_Float (tanh, not exp);
--  * every rounding threshold: for k in 0 .. 99 the value 100 s crosses
--    k + 1/2 at x_k = ln ((2k + 1) / (199 - 2k)); Percent must be k on
--    the grid point just below x_k and k + 1 just above;
--  * 200,000 seeded random X_Milli over all of Integer against the tanh
--    reference, with Percent (-x) = 100 - Percent (x).
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Sigmoid; use Sigmoid;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Sigmoid";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  Round half up of 50 (1 + tanh (x / 2)); for |x| > 40 tanh is +-1 in
   --  Long_Float, which gives 100 / 0 as required.
   function Ref (X_Milli : Integer) return Integer is
      X : constant Long_Float := Long_Float (X_Milli) / 1000.0;
      T : constant Long_Float := (if abs X > 40.0 then (if X > 0.0 then 1.0 else -1.0) else Tanh (X / 2.0));
   begin
      return Integer (Long_Float'Floor (50.0 * (1.0 + T) + 0.5));
   end Ref;
begin
   for X in -30_000 .. 30_000 loop
      Report (Percent (X) = Ref (X), "grid" & X'Image);
   end loop;

   for K in 0 .. 99 loop
      declare
         XK : constant Long_Float := Log (Long_Float (2 * K + 1) / Long_Float (199 - 2 * K));
         Lo : constant Integer := Integer (Long_Float'Floor (XK * 1000.0));
      begin
         Report (Percent (Lo) = K and then Percent (Lo + 1) = K + 1, "threshold" & K'Image & " at" & Lo'Image);
      end;
   end loop;

   for I in 1 .. 200_000 loop
      declare
         X : constant Integer := Integer (Long_Long_Integer (Next) * 2 - 2_147_483_647);
      begin
         Report (Percent (X) = Ref (X) and then Percent (X) + Percent (-X) = 100, "random" & X'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
