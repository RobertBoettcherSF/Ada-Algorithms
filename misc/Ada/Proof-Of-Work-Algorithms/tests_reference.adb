--  tests_reference.adb
--  Proof_Of_Work against deliberately simple references on seeded random
--  inputs (seed 20261009): smallest valid nonce by linear scan, hash chain
--  by repeated digest, smallest memory-puzzle index by linear scan; plus
--  SHA-256 known answers (FIPS 180-2 "abc" and the empty message).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with GNAT.SHA256;
with Proof_Of_Work; use Proof_Of_Work;

procedure Tests_Reference is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   State : Long_Long_Integer := 20261009;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;

   function Img (N : Natural) return String is
      S : constant String := N'Image;
   begin
      return S (S'First + 1 .. S'Last);
   end Img;

   function Zeros (H : String; D : Natural) return Boolean is
     (for all K in H'First .. H'First + D - 1 => H (K) = '0');

   function Random_Text return String is
      S : String (1 .. Next (12));
   begin
      for C of S loop
         C := Character'Val (32 + Next (95));
      end loop;
      return S;
   end Random_Text;

   Hex : constant String := "0123456789abcdef";
begin
   Check (GNAT.SHA256.Digest ("abc")
          = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
          "SHA-256 abc");
   Check (GNAT.SHA256.Digest ("")
          = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
          "SHA-256 empty");

   --  Hashcash: the returned nonce is the smallest with D leading zero hex
   --  digits, the returned hash is its digest; Verify agrees with the
   --  definition on the found nonce and on 20 random other nonces.
   for T in 1 .. 60 loop
      declare
         Data  : constant String := Random_Text;
         D     : constant Natural := Next (4);
         Nonce : Nonce_Type;
         Hash  : String (1 .. 64);
         Ref   : Natural := 0;
      begin
         while not Zeros (GNAT.SHA256.Digest (Data & Img (Ref)), D) loop
            Ref := Ref + 1;
         end loop;
         Generate_Hashcash (Data, Difficulty_Level (D), Nonce, Hash);
         Check (Natural (Nonce) = Ref, "Hashcash smallest nonce, D =" & D'Image);
         Check (Hash = GNAT.SHA256.Digest (Data & Img (Ref)), "Hashcash digest");
         Check (Verify_Hashcash (Data, Difficulty_Level (D), Nonce), "Hashcash verify found");
         for K in 1 .. 20 loop
            declare
               N : constant Natural := Next (100_000);
            begin
               Check (Verify_Hashcash (Data, Difficulty_Level (D), Nonce_Type (N))
                      = Zeros (GNAT.SHA256.Digest (Data & Img (N)), D),
                      "Hashcash verify random nonce");
            end;
         end loop;
      end;
   end loop;

   --  Hash chain: Iterations digests, the first of the seed
   for T in 1 .. 100 loop
      declare
         Seed : constant String := Random_Text;
         It   : constant Positive := 1 + Next (40);
         H    : String (1 .. 64) := GNAT.SHA256.Digest (Seed);
         Got  : String (1 .. 64);
      begin
         for K in 2 .. It loop
            H := GNAT.SHA256.Digest (H);
         end loop;
         Generate_Hash_Chain (Seed, Iteration_Count (It), Got);
         Check (Got = H, "hash chain" & It'Image);
         Check (Verify_Hash_Chain (Seed, Iteration_Count (It), H), "chain verify");
         Check (not Verify_Hash_Chain (Seed, Iteration_Count (It + 1), H), "chain verify +1");
      end;
   end loop;

   --  Memory puzzle: smallest index 1 .. Size whose digest ends in the
   --  target, or PoW_Error when there is none
   for T in 1 .. 200 loop
      declare
         Seed   : constant String := Random_Text;
         Size   : constant Positive := 1 + Next (60);
         Target : constant Character := Hex (1 + Next (16));
         Ref    : Natural := 0;
         Got    : Positive;
      begin
         for I in 1 .. Size loop
            declare
               H : constant String := GNAT.SHA256.Digest (Seed & Img (I));
            begin
               if H (H'Last) = Target then
                  Ref := I;
                  exit;
               end if;
            end;
         end loop;
         begin
            Solve_Memory_Puzzle (Seed, Memory_Size (Size), Target, Got);
            Check (Ref /= 0 and then Got = Ref, "memory puzzle smallest index");
         exception
            when PoW_Error =>
               Check (Ref = 0, "memory puzzle raised with a solution present");
         end;
         for I in 1 .. 5 loop
            declare
               H : constant String := GNAT.SHA256.Digest (Seed & Img (I));
            begin
               Check (Verify_Memory_Puzzle (Seed, Target, I) = (H (H'Last) = Target),
                      "memory puzzle verify");
            end;
         end loop;
      end;
   end loop;

   --  Index 0 is never a solution (Solve searches 1 .. Size), so Verify
   --  must reject it even when the digest of Seed & "0" ends in the target
   declare
      H : constant String := GNAT.SHA256.Digest ("MemSeed0");
   begin
      Check (not Verify_Memory_Puzzle ("MemSeed", H (H'Last), 0),
             "memory puzzle verify accepted index 0");
   end;

   if Fails = 0 then
      Put_Line ("PASS Proof_Of_Work reference comparison (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests_Reference;
