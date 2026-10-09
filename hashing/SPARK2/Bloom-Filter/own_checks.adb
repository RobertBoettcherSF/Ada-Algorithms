pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model: the set of bit positions
--  {K mod 64, (K / 7) mod 64} of every inserted key K, computed here with
--  Long_Long_Integer and an explicit remainder; Might_Contain (Q) must be
--  True exactly when both of Q's positions are in that set. In particular
--  every inserted key is reported (no false negatives) and the empty
--  filter reports nothing.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Bloom_Filter; use Bloom_Filter;

procedure Own_Checks is
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
      Name : constant String := "Bloom-Filter";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   subtype LL is Long_Long_Integer;
   type Bit_Set is array (0 .. 63) of Boolean;

   function Rem_64 (X : LL) return Natural is (Natural (X - 64 * (X / 64)));

   function Random_Key return Natural is
     (case Next mod 4 is
        when 0 => Next mod 64,
        when 1 => Next mod 1000,
        when 2 => Natural'Last - Next mod 1000,
        when others => Next);

   F    : Filter;
   Bits : Bit_Set;
   Keys : array (1 .. 40) of Natural;
begin
   for Rep in 1 .. 4_000 loop
      F := Empty;
      Bits := [others => False];
      declare
         N : constant Natural := Next mod 41;
      begin
         for I in 1 .. N loop
            Keys (I) := Random_Key;
            Insert (F, Keys (I));
            Bits (Rem_64 (LL (Keys (I)))) := True;
            Bits (Rem_64 (LL (Keys (I)) / 7)) := True;
         end loop;
         for I in 1 .. N loop
            Report (Might_Contain (F, Keys (I)), "inserted key" & Keys (I)'Image);
         end loop;
         for Q in 1 .. 200 loop
            declare
               K : constant Natural := (if Q <= 64 then Q - 1 else Random_Key);
            begin
               Report (Might_Contain (F, K) = (Bits (Rem_64 (LL (K))) and then Bits (Rem_64 (LL (K) / 7))),
                       "query" & K'Image & " after" & N'Image & " keys");
            end;
         end loop;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
