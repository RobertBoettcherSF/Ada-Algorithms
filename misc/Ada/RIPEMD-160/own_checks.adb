--  Own checks (see tests/SOURCES.txt). The expected digests are the
--  authors' published test vectors, not values taken from this program.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ripemd_160; use Ripemd_160;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   type U32 is mod 2 ** 32;
   Default_Seed : constant U32 := 20261008;
   function Seed_From_Env return U32 is
      S : U32 := Default_Seed;
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         S := U32'Value (Ada.Environment_Variables.Value ("AA_SEED"));
      end if;
      Put_Line ("own checks seed:" & S'Image & " (default" & Default_Seed'Image
                & "; set AA_SEED to override)");
      return S;
   end Seed_From_Env;
   Lcg : U32 := Seed_From_Env;
   function Rand (M : Positive) return Natural is
   begin
      Lcg := Lcg * 1664525 + 1013904223;
      return Natural ((Lcg / 256) mod U32 (M));
   end Rand;

   function To_Hex (D : Digest_Type) return String is
      Hex : constant String := "0123456789abcdef";
      R   : String (1 .. 40);
   begin
      for I in D'Range loop
         R (I * 2 + 1) := Hex (Natural (D (I) / 16) + 1);
         R (I * 2 + 2) := Hex (Natural (D (I) mod 16) + 1);
      end loop;
      return R;
   end To_Hex;

   function Ten return String is ("1234567890");

   function Build (Token : String) return String is
   begin
      if Token = "EMPTY" then
         return "";
      elsif Token = "A*1000000" then
         return [1 .. 1_000_000 => 'a'];
      elsif Token = "8*1234567890" then
         return Ten & Ten & Ten & Ten & Ten & Ten & Ten & Ten;
      else
         return Token;
      end if;
   end Build;

   --  chunked hashing compared with the published digest
   procedure Check_Chunks (Msg : String; Hex : String; What : String) is
      Sizes : constant array (1 .. 6) of Positive := [1, 55, 56, 63, 64, 1 + Rand (80)];
   begin
      Expect (To_Hex (Hash (Msg)) = Hex, What & " one shot");
      Expect (To_Hex (Hash (To_Bytes (Msg))) = Hex, What & " bytes");
      for S of Sizes loop
         declare
            Ctx : Context;
            D   : Digest_Type;
            I   : Natural := Msg'First;
         begin
            Init (Ctx);
            while I <= Msg'Last loop
               declare
                  J : constant Natural := Natural'Min (Msg'Last, I + S - 1);
               begin
                  Update (Ctx, Msg (I .. J));
                  I := J + 1;
               end;
            end loop;
            Finalize (Ctx, D);
            Expect (To_Hex (D) = Hex, What & " chunks of" & S'Image);
            Expect (not Is_Initialized (Ctx), What & " finalized");
         end;
      end loop;
      if Msg'Length > 0 then
         declare
            B : constant Byte_Array (7 .. 6 + Msg'Length) := To_Bytes (Msg);
         begin
            Expect (To_Hex (Hash (B)) = Hex, What & " index origin 7");
         end;
      end if;
   end Check_Chunks;

begin
   declare
      F : File_Type;
   begin
      Open (F, In_File, "tests/authors_vectors.txt");
      while not End_Of_File (F) loop
         declare
            Line : constant String := Get_Line (F);
         begin
            if Line'Length > 0 and then Line (Line'First) /= '#' then
               declare
                  Hex   : constant String := Line (Line'First .. Line'First + 39);
                  Token : constant String := Ada.Strings.Fixed.Trim (Line (Line'First + 41 .. Line'Last), Ada.Strings.Both);
               begin
                  Check_Chunks (Build (Token), Hex, Token);
               end;
            end if;
         end;
      end loop;
      Close (F);
   end;
   Expect (Checked > 50, "enough vectors:" & Checked'Image);
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (authors' RIPEMD-160 vectors, chunked)");
end Own_Checks;
