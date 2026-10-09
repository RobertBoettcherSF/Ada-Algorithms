pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent definition: the number of
--  merged accounts is the number of positions A in 1 .. N whose owner does
--  not occur at any earlier position B < A (first occurrences, compared
--  pairwise; no Seen table). Exhaustive for N = 1 .. 6 over owners 1 .. 4
--  (entries after N set to arbitrary owners, which must be ignored), plus
--  seeded random arrays for N = 1 .. 32 over narrow and wide owner ranges.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Accounts_Merge_Lite; use Accounts_Merge_Lite;

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
      Name : constant String := "Ada-SPARK-Accounts-Merge-Lite";
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

   function Reference (N : Account; O : Owner_Array) return Natural is
      R : Natural := 0;
      First : Boolean;
   begin
      for A in 1 .. N loop
         First := True;
         for B in 1 .. A - 1 loop
            if O (B) = O (A) then
               First := False;
            end if;
         end loop;
         if First then
            R := R + 1;
         end if;
      end loop;
      return R;
   end Reference;

   O : Owner_Array;
   C : Natural;
begin
   for N in 1 .. 6 loop
      for Code in 0 .. 4 ** N - 1 loop
         C := Code;
         for A in Account loop
            if A <= N then
               O (A) := C mod 4 + 1;
               C := C / 4;
            else
               O (A) := Next mod Max_Accounts + 1;
            end if;
         end loop;
         Report (Merge_Count (N, O) = Reference (N, O),
                 "exhaustive N" & N'Image & " code" & Code'Image);
      end loop;
   end loop;
   for Trial in 1 .. 20_000 loop
      declare
         N     : constant Account := Next mod Max_Accounts + 1;
         Range_Size : constant Positive :=
           (case Trial mod 4 is
              when 0 => 1, when 1 => 3, when 2 => N, when others => 32);
      begin
         for A in Account loop
            O (A) := Next mod Range_Size + 1;
         end loop;
         Report (Merge_Count (N, O) = Reference (N, O),
                 "random N" & N'Image & " trial" & Trial'Image);
      end;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
