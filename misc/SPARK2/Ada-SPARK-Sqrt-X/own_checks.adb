pragma Ada_2022;
--  Own checks for Sqrt_X.Sqrt (see tests/SOURCES.txt). No expected
--  value comes from the program: the floor-root property is checked
--  without overflow (R <= N / R and N / (R + 1) < R + 1), small inputs
--  are compared with a count-up reference, and no call may take more
--  than 16 Newton steps (the worst case over all of Natural, at N = 0;
--  see tests/SOURCES.txt).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Sqrt_X; use Sqrt_X;

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

   --  Floor root without any square: R * R <= N iff R = 0 or R <= N / R;
   --  N < (R + 1) ** 2 iff N / (R + 1) < R + 1.
   function Is_Root (N : Natural; R : Natural) return Boolean is
     ((R = 0 or else R <= N / R) and then N / (R + 1) < R + 1);

   procedure Check (N : Natural; Label : String) is
      S : constant Sqrt_Result := Sqrt (N);
   begin
      Report (Is_Root (N, S.Root) and then S.Steps <= 16 and then Floor_Sqrt (N) = S.Root,
              Label & " N =" & N'Image & ": root" & S.Root'Image & ", steps" & S.Steps'Image);
   end Check;

   --  Default seed: FNV-1a (32 bit) of the folder name, folded into the
   --  Park-Miller range; printed; AA_SEED=<n> overrides it.
   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Sqrt-X";
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
      return Natural (Seed);   --  1 .. 2 ** 31 - 2
   end Next;
begin
   --  1. The old table's range, against a count-up reference.
   for N in 0 .. 100 loop
      declare
         Ref : Natural := 0;
      begin
         while (Ref + 1) * (Ref + 1) <= N loop
            Ref := Ref + 1;
         end loop;
         Report (Sqrt (N).Root = Ref and then Sqrt (N).Steps <= 16, "count-up N =" & N'Image);
      end;
   end loop;
   --  2. Around every square near the top of Natural, and the top itself.
   for K in 46_000 .. 46_340 loop
      Check (K * K - 1, "k*k-1");
      Check (K * K, "k*k");
      Check (K * K + 1, "k*k+1");
   end loop;
   Check (Natural'Last, "Natural'Last");
   Check (Natural'Last - 1, "Natural'Last - 1");
   --  3. Random inputs over the whole of Natural.
   for I in 1 .. 100_000 loop
      Check (Next, "random");
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
     & " checks (count-up reference on 0 .. 100, k*k-1 / k*k / k*k+1 for k = 46,000 .. 46,340, Natural'Last, 100,000 random; overflow-free root test; at most 16 steps)");
end Own_Checks;
