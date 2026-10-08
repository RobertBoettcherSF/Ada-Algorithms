--  Standalone test suite for AKS_Primality_Test (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with AKS_Primality_Test; use AKS_Primality_Test;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function U (X : U64) return U64 is (X);

   function Trial_Is_Prime (N : U64) return Boolean is
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      declare
         D : U64 := 3;
      begin
         while D * D <= N loop
            if N rem D = 0 then
               return False;
            end if;
            D := D + 2;
         end loop;
         return True;
      end;
   end Trial_Is_Prime;

   procedure Expect_Invalid_AKS (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Is_Prime_AKS (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_Prime_AKS: " & Label);
   end Expect_Invalid_AKS;

   procedure Expect_Invalid_R (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Find_AKS_R (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Find_AKS_R: " & Label);
   end Expect_Invalid_R;

   Cross_Mismatches : Natural := 0;
   Cross_Checked    : Natural := 0;

begin
   Ada.Text_IO.Put_Line ("AKS_Primality_Test test suite");
   Ada.Text_IO.Put_Line
     ("Max_Educational_N =" & U64'Image (Max_Educational_N));

   ------------------------------------------------------------------
   Section ("Mul_Mod / Gcd / Floor_Log2");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (6), U (7), U (10)) = 2, "Mul_Mod 6*7 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (3)) = 0, "Mul_Mod 0*5 mod 3 = 0");
   Check (Mul_Mod (U (5), U (5), U (1)) = 0, "Mul_Mod mod 1 = 0");
   Check (Gcd (U (12), U (8)) = 4, "Gcd(12,8)=4");
   Check (Gcd (U (17), U (13)) = 1, "Gcd(17,13)=1");
   Check (Gcd (U (0), U (5)) = 5, "Gcd(0,5)=5");
   Check (Gcd (U (5), U (0)) = 5, "Gcd(5,0)=5");
   Check (Floor_Log2 (U (1)) = 0, "Floor_Log2(1)=0");
   Check (Floor_Log2 (U (2)) = 1, "Floor_Log2(2)=1");
   Check (Floor_Log2 (U (31)) = 4, "Floor_Log2(31)=4");
   Check (Floor_Log2 (U (32)) = 5, "Floor_Log2(32)=5");
   Check (Floor_Log2_Squared (U (31)) = 24, "Floor_Log2_Squared(31)=24");
   Check (Floor_Log2_Squared (U (2)) = 1, "Floor_Log2_Squared(2)=1");

   ------------------------------------------------------------------
   Section ("Totient");
   ------------------------------------------------------------------
   Check (Totient (U (1)) = 1, "phi(1)=1");
   Check (Totient (U (2)) = 1, "phi(2)=1");
   Check (Totient (U (7)) = 6, "phi(7)=6");
   Check (Totient (U (10)) = 4, "phi(10)=4");
   Check (Totient (U (29)) = 28, "phi(29)=28");
   Check (Totient (U (9)) = 6, "phi(9)=6");

   ------------------------------------------------------------------
   Section ("Is_Perfect_Power");
   ------------------------------------------------------------------
   Check (not Is_Perfect_Power (U (2)), "2 not perfect power");
   Check (not Is_Perfect_Power (U (3)), "3 not perfect power");
   Check (Is_Perfect_Power (U (4)), "4=2^2");
   Check (Is_Perfect_Power (U (8)), "8=2^3");
   Check (Is_Perfect_Power (U (9)), "9=3^2");
   Check (Is_Perfect_Power (U (16)), "16=2^4");
   Check (Is_Perfect_Power (U (25)), "25=5^2");
   Check (Is_Perfect_Power (U (27)), "27=3^3");
   Check (Is_Perfect_Power (U (32)), "32=2^5");
   Check (Is_Perfect_Power (U (36)), "36=6^2");
   Check (Is_Perfect_Power (U (49)), "49=7^2");
   Check (Is_Perfect_Power (U (81)), "81=3^4");
   Check (Is_Perfect_Power (U (121)), "121=11^2");
   Check (not Is_Perfect_Power (U (10)), "10 not perfect power");
   Check (not Is_Perfect_Power (U (12)), "12 not perfect power");
   Check (not Is_Perfect_Power (U (97)), "97 not perfect power");

   ------------------------------------------------------------------
   Section ("Perfect powers → composite via AKS step 1");
   ------------------------------------------------------------------
   declare
      Powers : constant array (Positive range <>) of U64 :=
        [9, 16, 25, 27, 32, 49, 81, 121];
   begin
      for I in Powers'Range loop
         Check
           (not Is_Prime_AKS (Powers (I)),
            "AKS composite perfect power" & U64'Image (Powers (I)));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("Find_AKS_R smoke");
   ------------------------------------------------------------------
   Check (Find_AKS_R (U (31)) = 29, "Find_AKS_R(31)=29 (Wikipedia example)");
   Check (Find_AKS_R (U (2)) >= 2, "Find_AKS_R(2) >= 2");
   Check (Find_AKS_R (U (97)) = 59, "Find_AKS_R(97)=59");
   Check (Find_AKS_R (U (5)) >= 2, "Find_AKS_R(5) >= 2");
   declare
      R11 : constant U64 := Find_AKS_R (U (11));
   begin
      Check (R11 >= 2 and then Gcd (11, R11) = 1, "Find_AKS_R(11) coprime");
   end;

   ------------------------------------------------------------------
   Section ("Small primes (AKS True)");
   ------------------------------------------------------------------
   declare
      Primes : constant array (Positive range <>) of U64 :=
        [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
         53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107,
         109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167,
         173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229,
         233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283,
         293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359,
         367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431,
         433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499];
   begin
      for I in Primes'Range loop
         if Primes (I) <= Max_Educational_N then
            Check
              (Is_Prime_AKS (Primes (I)),
               "prime" & U64'Image (Primes (I)));
         end if;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("Small composites (AKS False)");
   ------------------------------------------------------------------
   declare
      Comps : constant array (Positive range <>) of U64 :=
        [4, 6, 8, 10, 12, 14, 15, 18, 20, 21, 22, 24, 26, 28, 30,
         33, 34, 35, 38, 39, 40, 42, 44, 45, 46, 48, 50, 51, 52,
         55, 57, 58, 62, 63, 64, 65, 66, 68, 69, 70, 74, 75, 76,
         77, 85, 87, 91, 93, 94, 95, 99, 100, 119, 121, 125, 133,
         143, 169, 187, 209, 221, 247, 289, 299, 319, 323, 341,
         361, 377, 391, 403, 407, 451, 473, 481, 493];
   begin
      for I in Comps'Range loop
         if Comps (I) <= Max_Educational_N then
            Check
              (not Is_Prime_AKS (Comps (I)),
               "composite" & U64'Image (Comps (I)));
         end if;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("Invalid_Argument domain");
   ------------------------------------------------------------------
   Expect_Invalid_AKS ("N=0", U (0));
   Expect_Invalid_AKS ("N=1", U (1));
   Expect_Invalid_AKS
     ("N=Max+1", Max_Educational_N + 1);
   Expect_Invalid_R ("N=0", U (0));
   Expect_Invalid_R ("N=1", U (1));
   Expect_Invalid_R ("N=Max+1", Max_Educational_N + 1);

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (U (1), U (1), U (0));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod M=0");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Natural := Floor_Log2 (U (0));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Floor_Log2(0)");
   end;

   ------------------------------------------------------------------
   Section ("Full cross-check vs trial division");
   ------------------------------------------------------------------
   Cross_Mismatches := 0;
   Cross_Checked    := 0;
   declare
      N : U64 := 2;
   begin
      while N <= Max_Educational_N loop
         declare
            AKS_P   : constant Boolean := Is_Prime_AKS (N);
            Trial_P : constant Boolean := Trial_Is_Prime (N);
         begin
            Cross_Checked := Cross_Checked + 1;
            if AKS_P /= Trial_P then
               Cross_Mismatches := Cross_Mismatches + 1;
               Ada.Text_IO.Put_Line
                 ("  FAIL: mismatch at N =" & U64'Image (N)
                  & " AKS=" & Boolean'Image (AKS_P)
                  & " trial=" & Boolean'Image (Trial_P));
            end if;
         end;
         N := N + 1;
      end loop;
   end;
   Check
     (Cross_Mismatches = 0,
      "cross-check 2.."
      & U64'Image (Max_Educational_N)
      & " ("
      & Natural'Image (Cross_Checked)
      & " values, 0 mismatches)");

   --  Count each matched N as soft progress already covered by one assert;
   --  add a few range-summary checks for PASS volume.
   Check (Cross_Checked = Natural (Max_Educational_N - 1),
          "cross-check covered Max_Educational_N-1 values");

   ------------------------------------------------------------------
   Section ("Summary");
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:"
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
