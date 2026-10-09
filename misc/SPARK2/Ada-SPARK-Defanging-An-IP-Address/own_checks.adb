pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent definition, built with
--  Ada.Strings.Unbounded: the defanged text is the input with every "."
--  replaced by "[.]" and every other character copied. Exhaustive over all
--  inputs of length 0 .. 8 drawn from the alphabet '1', '.', ':' (each
--  input padded with random characters after Length, which must be
--  ignored), plus 20,000 seeded random inputs of length 0 .. 32 (dot-heavy
--  and IPv4-like). Output (1 .. Output_Length) must equal the definition.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces; use Interfaces;
with Defanging_IP; use Defanging_IP;

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
      Name : constant String := "Ada-SPARK-Defanging-An-IP-Address";
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

   Pool : constant String := "0123456789.:abc ";

   procedure Check (Input : Text; Length : Length_Type; Label : String) is
      Want : Unbounded_String;
      Output : Out_Text;
      Out_Len : Out_Length_Type;
   begin
      for I in 1 .. Length loop
         if Input (I) = '.' then
            Append (Want, "[.]");
         else
            Append (Want, Input (I));
         end if;
      end loop;
      Defang (Input, Length, Output, Out_Len);
      Report (Out_Len = Ada.Strings.Unbounded.Length (Want)
              and then String (Output (1 .. Out_Len)) = To_String (Want),
              Label);
   end Check;

   Input : Text;
   Alphabet : constant String := "1.:";
   C : Natural;
begin
   for L in 0 .. 8 loop
      for Code in 0 .. 3 ** L - 1 loop
         C := Code;
         for I in Defanging_IP.Index loop
            if I <= L then
               Input (I) := Alphabet (C mod 3 + 1);
               C := C / 3;
            else
               Input (I) := Pool (Next mod Pool'Length + 1);
            end if;
         end loop;
         Check (Input, L, "exhaustive length" & L'Image & " code" & Code'Image);
      end loop;
   end loop;
   for Trial in 1 .. 20_000 loop
      declare
         L : constant Length_Type := Next mod 33;
      begin
         for I in Defanging_IP.Index loop
            Input (I) :=
              (if Trial mod 3 = 0 and then Next mod 2 = 0 then '.'
               else Pool (Next mod Pool'Length + 1));
         end loop;
         Check (Input, L, "random length" & L'Image & " trial" & Trial'Image);
      end;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
