--  Standalone test suite for Lagged_Fibonacci_Generator (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lagged_Fibonacci_Generator;
use Lagged_Fibonacci_Generator;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function V (X : Long_Long_Integer) return Value is (Value (X));
   function Pos (X : Positive) return Positive is (X);

   function Zero_Seeds return Seed_Array is
      S : constant Seed_Array := [others => 0];
   begin
      return S;
   end Zero_Seeds;

   type Value_List is array (Positive range <>) of Value;

   function Seeds_Of (Values : Value_List) return Seed_Array is
      S : Seed_Array := [others => 0];
   begin
      for I in Values'Range loop
         S (Lag_Index (I - Values'First + 1)) := Values (I);
      end loop;
      return S;
   end Seeds_Of;

   function Next_Val (G : in out Generator) return Value is
      R : Value;
   begin
      Next (G, R);
      return R;
   end Next_Val;

   G, G2      : Generator;
   X, Y, Z, M : Value;
   B          : Boolean;
   Discard    : Value;
   pragma Unreferenced (Discard);

begin
   -----------------------------------------------------------------
   Section ("1. Validation helpers");
   -----------------------------------------------------------------
   Check (not Is_Valid_Lags (Pos (5), Pos (5)), "j=k=5 invalid");
   Check (not Is_Valid_Lags (Pos (10), Pos (5)), "j>k invalid");
   Check (Is_Valid_Lags (Pos (1), Pos (2)), "j=1 k=2 valid");
   Check (Is_Valid_Lags (Pos (24), Pos (55)), "j=24 k=55 valid");
   Check (not Is_Valid_Lags (Pos (1), Pos (Max_Lag + 1)),
          "k>Max_Lag invalid");
   Check (Is_Valid_Lags (Lag_24_55), "Lag_24_55 valid");
   Check (Is_Valid_Lags (Lag_30_127), "Lag_30_127 valid");
   Check (not Is_Valid_Modulus (V (0)), "M=0 invalid");
   Check (not Is_Valid_Modulus (V (1)), "M=1 invalid");
   Check (Is_Valid_Modulus (V (2)), "M=2 valid");
   Check (Is_Valid_Modulus (Default_Modulus), "Default_Modulus valid");
   Check (not Is_Valid_Modulus (Max_Modulus + 1), "M>Max_Modulus invalid");
   Check (Seeds_In_Range (2, 10, Seeds_Of ([V (1), V (2)])),
          "Seeds_In_Range ok");
   Check (not Seeds_In_Range (2, 10, Seeds_Of ([V (1), V (10)])),
          "Seeds_In_Range seed = M rejected");
   Check (Max_Lag = Nat (128), "Max_Lag=128");
   Check (V (Long_Long_Integer (Default_Modulus)) =
         V (Long_Long_Integer (Max_Modulus)),
         "Default_Modulus=Max_Modulus");

   -----------------------------------------------------------------
   Section ("2. Tiny additive LFG (j=1,k=2,m=16) deterministic");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := Seeds_Of ([V (1), V (1)]);
      Expected : constant array (1 .. 10) of Value :=
        [2, 3, 5, 8, 13, 5, 2, 7, 9, 0];
   begin
      G := Create (1, 2, Add, 16, S);
      Check (Get_J (G) = 1, "Get_J=1");
      Check (Get_K (G) = 2, "Get_K=2");
      Check (Get_Op (G) = Add, "Get_Op=Add");
      Check (Get_Modulus (G) = 16, "Get_Modulus=16");
      Check (Get_Cursor (G) = Nat (0), "cursor starts 0");
      Check (Is_Initialised (G), "initialised");
      Check (Get_Buffer_Word (G, 1) = 1, "buf[1]=X0=1");
      Check (Get_Buffer_Word (G, 2) = 1, "buf[2]=X1=1");
      B := True;
      for I in Expected'Range loop
         if Next_Val (G) /= Expected (I) then
            B := False;
         end if;
      end loop;
      Check (B, "fib-like add sequence 10 terms");
   end;

   -----------------------------------------------------------------
   Section ("3. Subtract and XOR tiny sequences");
   -----------------------------------------------------------------
   G := Create (1, 2, Subtract, 16, Seeds_Of ([V (10), V (3)]));
   Check (Next_Val (G) = 9, "sub X2=9");
   Check (Next_Val (G) = 6, "sub X3=6");
   Check (Next_Val (G) = 13, "sub X4=13");

   G := Create (1, 2, Bitwise_Xor, 16, Seeds_Of ([V (5), V (3)]));
   Check (Next_Val (G) = 6, "xor X2=6");
   Check (Next_Val (G) = 5, "xor X3=5");
   Check (Next_Val (G) = 3, "xor X4=3");
   Check (Get_Op (G) = Bitwise_Xor, "op is Bitwise_Xor");

   -----------------------------------------------------------------
   Section ("4. Reset replay and independent generators");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := Seeds_Of ([V (1), V (2), V (3)]);
      Buf : array (1 .. 6) of Value;
   begin
      G := Create (1, 3, Add, 32, S);
      for I in Buf'Range loop
         Buf (I) := Next_Val (G);
      end loop;
      Reset (G, S);
      B := True;
      for I in Buf'Range loop
         if Next_Val (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "Reset array replay");
      Reset (G, S);
      Check (Get_Cursor (G) = Nat (0), "Reset restores cursor 0");

      G2 := Create (1, 3, Add, 32, S);
      Reset (G, S);
      B := True;
      for I in 1 .. 5 loop
         if Next_Val (G) /= Next_Val (G2) then
            B := False;
         end if;
      end loop;
      Check (B, "independent identical Create");
   end;

   -----------------------------------------------------------------
   Section ("5. LCG seed fill Create / Reset");
   -----------------------------------------------------------------
   G := Create (1, 4, Add, 1000, V (42));
   Check (Is_Initialised (G), "LCG-fill Create ok");
   Check (Get_K (G) = 4, "K=4 after LCG fill");
   B := False;
   declare
      All_In_Range : Boolean := True;
   begin
      for I in 1 .. Get_K (G) loop
         if Get_Buffer_Word (G, I) rem 2 = 1 then
            B := True;
         end if;
         if Get_Buffer_Word (G, I) >= 1000 then
            All_In_Range := False;
         end if;
      end loop;
      Check (B and All_In_Range, "LCG fill words < M and at least one odd");
   end;

   declare
      Buf : array (1 .. 8) of Value;
   begin
      for I in Buf'Range loop
         Buf (I) := Next_Val (G);
      end loop;
      Reset (G, V (42));
      B := True;
      for I in Buf'Range loop
         if Next_Val (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "Reset single-seed replay");
   end;

   -----------------------------------------------------------------
   Section ("6. Lag_Pair Create overloads and constants");
   -----------------------------------------------------------------
   Check (Lag_24_55.J = 24 and Lag_24_55.K = 55, "Lag_24_55");
   Check (Lag_38_89.J = 38 and Lag_38_89.K = 89, "Lag_38_89");
   Check (Lag_37_100.J = 37 and Lag_37_100.K = 100, "Lag_37_100");
   Check (Lag_30_127.J = 30 and Lag_30_127.K = 127, "Lag_30_127");
   Check (V (Long_Long_Integer (Default_Modulus)) = V (4_294_967_296),
         "Default_Modulus=2^32");

   G := Create (Lag_24_55, Add, Default_Modulus, V (12345));
   Check (Get_J (G) = 24, "Lag_Pair Create J");
   Check (Get_K (G) = 55, "Lag_Pair Create K");
   Check (Get_Op (G) = Add, "Lag_Pair Create Op");
   X := Next_Val (G);
   Y := Next_Val (G);
   Check (X < Default_Modulus and Y < Default_Modulus,
          "Lag_24_55 samples < M");

   declare
      S : Seed_Array := Zero_Seeds;
   begin
      for I in 1 .. 55 loop
         S (I) := Value (I);
      end loop;
      G := Create (Lag_24_55, Subtract, Default_Modulus, S);
      Check (Get_Op (G) = Subtract, "array Lag_Pair Subtract");
      Z := Next_Val (G);
      Check (Z < Default_Modulus, "subtract sample < M");
   end;

   -----------------------------------------------------------------
   Section ("7. Modular helpers Add_Mod / Sub_Mod / Xor_Mod");
   -----------------------------------------------------------------
   Check (Add_Mod (V (3), V (5), V (7)) = 1, "3+5 mod 7 = 1");
   Check (Add_Mod (V (6), V (6), V (7)) = 5, "6+6 mod 7 = 5");
   Check (Add_Mod (V (0), V (0), V (2)) = 0, "0+0 mod 2");
   Check (Sub_Mod (V (3), V (5), V (7)) = 5, "3-5 mod 7 = 5");
   Check (Sub_Mod (V (5), V (3), V (7)) = 2, "5-3 mod 7 = 2");
   Check (Sub_Mod (V (0), V (1), V (8)) = 7, "0-1 mod 8 = 7");
   Check (Xor_Mod (V (5), V (3), V (16)) = 6, "5 xor 3 = 6");
   Check (Xor_Mod (V (15), V (15), V (16)) = 0, "15 xor 15 = 0");
   Check (Xor_Mod (V (2), V (1), V (5)) = 3, "(2 xor 1) rem 5 = 3");
   Check (Combine (V (3), V (5), Add, V (7)) = 1, "Combine Add");
   Check (Combine (V (3), V (5), Subtract, V (7)) = 5, "Combine Sub");
   Check (Combine (V (5), V (3), Bitwise_Xor, V (16)) = 6,
          "Combine Xor");
   Check (Add_Mod (Max_Modulus - 1, V (1), Max_Modulus) = 0,
          "Add_Mod wrap at Max_Modulus");
   Check (Sub_Mod (V (0), V (1), Max_Modulus) = Max_Modulus - 1,
          "Sub_Mod wrap Max_Modulus");

   -----------------------------------------------------------------
   Section ("8. j=2,k=5 additive known sequence");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array :=
        Seeds_Of ([V (1), V (2), V (3), V (4), V (5)]);
      Exp : constant array (1 .. 5) of Value := [5, 7, 8, 11, 13];
   begin
      G := Create (2, 5, Add, 32, S);
      B := True;
      for I in Exp'Range loop
         if Next_Val (G) /= Exp (I) then
            B := False;
         end if;
      end loop;
      Check (B, "j=2 k=5 add sequence");
   end;

   -----------------------------------------------------------------
   Section ("9. Freeciv-style (24,55) Add reproducibility");
   -----------------------------------------------------------------
   G := Create (Lag_24_55, Add, Default_Modulus, V (1));
   declare
      Buf : array (1 .. 20) of Value;
   begin
      for I in Buf'Range loop
         Buf (I) := Next_Val (G);
      end loop;
      Reset (G, V (1));
      B := True;
      for I in Buf'Range loop
         if Next_Val (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "(24,55) Add reset replay 20");
   end;

   G := Create (Lag_24_55, Bitwise_Xor, Default_Modulus, V (99));
   G2 := Create (Lag_24_55, Bitwise_Xor, Default_Modulus, V (99));
   B := True;
   for I in 1 .. 30 loop
      if Next_Val (G) /= Next_Val (G2) then
         B := False;
      end if;
   end loop;
   Check (B, "(24,55) XOR twin generators");

   G := Create (Lag_38_89, Subtract, Default_Modulus, V (7));
   Check (Get_J (G) = 38 and Get_K (G) = 89, "(38,89) inspectors");
   X := Next_Val (G);
   Check (X < Default_Modulus, "(38,89) sample");

   -----------------------------------------------------------------
   Section ("10. All three ops on same seeds differ");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := Seeds_Of ([V (7), V (11), V (13)]);
      XA, XS, XX : Value;
   begin
      G := Create (1, 3, Add, 64, S);
      XA := Next_Val (G);
      G := Create (1, 3, Subtract, 64, S);
      XS := Next_Val (G);
      G := Create (1, 3, Bitwise_Xor, 64, S);
      XX := Next_Val (G);
      Check (XA = Add_Mod (13, 7, 64), "Add matches helper");
      Check (XS = Sub_Mod (13, 7, 64), "Sub matches helper");
      Check (XX = Xor_Mod (13, 7, 64), "Xor matches helper");
      Check (XA /= XS, "Add /= Sub on pair");
      Check (XA /= XX, "Add /= Xor on pair");
   end;

   -----------------------------------------------------------------
   Section ("11. Cursor advances mod K");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array :=
        Seeds_Of ([V (1), V (2), V (3), V (4)]);
   begin
      G := Create (1, 4, Add, 100, S);
      Check (Get_Cursor (G) = Nat (0), "cursor 0");
      Discard := Next_Val (G);
      Check (Get_Cursor (G) = Nat (1), "cursor 1");
      Discard := Next_Val (G);
      Check (Get_Cursor (G) = Nat (2), "cursor 2");
      Discard := Next_Val (G);
      Check (Get_Cursor (G) = Nat (3), "cursor 3");
      Discard := Next_Val (G);
      Check (Get_Cursor (G) = Nat (0), "cursor wraps to 0");
   end;

   -----------------------------------------------------------------
   Section ("12. Larger lag pairs smoke (LCG fill)");
   -----------------------------------------------------------------
   G := Create (Lag_30_127, Add, Default_Modulus, V (11));
   Check (Get_K (G) = 127, "k=127");
   for I in 1 .. 50 loop
      X := Next_Val (G);
   end loop;
   Check (X < Default_Modulus, "50 samples (30,127)");

   G := Create (Lag_37_100, Bitwise_Xor, V (2 ** 16), V (3));
   Check (Get_Modulus (G) = 2 ** 16, "M=2^16");
   B := True;
   for I in 1 .. 40 loop
      if Next_Val (G) >= 2 ** 16 then
         B := False;
      end if;
   end loop;
   Check (B, "40 XOR samples < 2^16");

   -----------------------------------------------------------------
   Section ("13. M=2 minimal modulus");
   -----------------------------------------------------------------
   G := Create (1, 2, Add, 2, Seeds_Of ([V (1), V (0)]));
   Check (Next_Val (G) = 1, "m=2 X2");
   Check (Next_Val (G) = 1, "m=2 X3");
   Check (Next_Val (G) = 0, "m=2 X4");

   -----------------------------------------------------------------
   Section ("14. Buffer inspect after advances");
   -----------------------------------------------------------------
   G := Create (1, 3, Add, 64, Seeds_Of ([V (1), V (2), V (3)]));
   X := Next_Val (G);
   Check (X = 4, "X3=4");
   Check (Get_Buffer_Word (G, 1) = 4, "buf[1] overwritten with X3");
   Check (Get_Buffer_Word (G, 2) = 2, "buf[2] still X1");
   Check (Get_Buffer_Word (G, 3) = 3, "buf[3] still X2");

   -----------------------------------------------------------------
   Section ("15. Deterministic multi-op batch");
   -----------------------------------------------------------------
   for Op in Binary_Op loop
      G := Create (2, 7, Op, V (997), V (123));
      G2 := Create (2, 7, Op, V (997), V (123));
      B := True;
      for I in 1 .. 25 loop
         if Next_Val (G) /= Next_Val (G2) then
            B := False;
         end if;
      end loop;
      Check (B, "twin batch op=" & Op'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("16. Seed array Lag_Pair Create + Reset array");
   -----------------------------------------------------------------
   declare
      S : Seed_Array := Zero_Seeds;
      Buf : array (1 .. 15) of Value;
   begin
      for I in 1 .. 55 loop
         S (I) := Value ((I * 17) mod 256);
      end loop;
      S (1) := 1;
      G := Create (Lag_24_55, Add, V (256), S);
      for I in Buf'Range loop
         Buf (I) := Next_Val (G);
      end loop;
      Reset (G, S);
      B := True;
      for I in Buf'Range loop
         if Next_Val (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "Lag_Pair array Reset replay");
   end;

   -----------------------------------------------------------------
   Section ("17. Subtract sequence j=3 k=7");
   -----------------------------------------------------------------
   G := Create (3, 7, Subtract, 1000,
                Seeds_Of ([10, 20, 30, 40, 50, 60, 70]));
   Check (Next_Val (G) = 40, "X7=40");
   Check (Next_Val (G) = 40, "X8=40");
   Check (Next_Val (G) = 40, "X9=40");
   Check (Next_Val (G) = 0, "X10=0");

   -----------------------------------------------------------------
   Section ("18. XOR sequence j=2 k=4");
   -----------------------------------------------------------------
   G := Create (2, 4, Bitwise_Xor, 256,
                Seeds_Of ([V (1), V (2), V (4), V (8)]));
   Check (Next_Val (G) = 5, "xor X4=5");
   Check (Next_Val (G) = 10, "xor X5=10");
   Check (Next_Val (G) = 1, "xor X6=1");

   -----------------------------------------------------------------
   Section ("19. Many small-moduli residues");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := Seeds_Of ([V (1), V (1)]);
      Seen : array (0 .. 15) of Boolean := [others => False];
      C : Natural := 0;
   begin
      G := Create (1, 2, Add, 16, S);
      for I in 1 .. 32 loop
         X := Next_Val (G);
         if not Seen (Natural (X)) then
            Seen (Natural (X)) := True;
            C := C + 1;
         end if;
      end loop;
      Check (C >= Nat (8), "add fib visits >=8 residues in 32");
   end;

   -----------------------------------------------------------------
   Section ("20. Inspector Get_* consistency");
   -----------------------------------------------------------------
   G := Create (5, 17, Subtract, V (10007), V (99));
   Check (Get_J (G) = 5, "J=5");
   Check (Get_K (G) = 17, "K=17");
   Check (Get_Op (G) = Subtract, "Op=Subtract");
   Check (Get_Modulus (G) = 10007, "M=10007");
   Check (Is_Initialised (G), "init");
   for I in Lag_Index range 1 .. 17 loop
      Check (Get_Buffer_Word (G, I) < 10007,
             "seed word" & I'Image & " < M");
   end loop;

   -----------------------------------------------------------------
   Section ("21. Cross-check Combine vs Next for j=1 k=2");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := Seeds_Of ([V (9), V (4)]);
   begin
      for Op in Binary_Op loop
         G := Create (1, 2, Op, 32, S);
         X := Next_Val (G);
         Check (X = Combine (4, 9, Op, 32),
                "Next vs Combine " & Op'Image);
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("22. Varied Create smoke");
   -----------------------------------------------------------------
   for K in Lag_Index range 2 .. 12 loop
      declare
         J : constant Lag_Index := 1;
         Seed_K : constant Value := V (Long_Long_Integer (K));
      begin
         G := Create (J, K, Add, V (1009), Seed_K);
         X := Next_Val (G);
         Check (X < 1009, "smoke k=" & K'Image);
      end;
   end loop;

   for M_Pow in 3 .. 10 loop
      M := 2 ** M_Pow;
      G := Create (1, 3, Bitwise_Xor, M, V (1));
      B := True;
      for I in 1 .. 5 loop
         if Next_Val (G) >= M then
            B := False;
         end if;
      end loop;
      Check (B, "xor M=2^" & M_Pow'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("23. More Add_Mod / Sub_Mod identities");
   -----------------------------------------------------------------
   for T in 1 .. 12 loop
      declare
         A : constant Value := V (Long_Long_Integer (T * 3)) rem 17;
         Bv : constant Value := V (Long_Long_Integer (T * 5)) rem 17;
         Modulus : constant Modulus_Type := 17;
      begin
         Check (Add_Mod (A, Bv, Modulus) =
                  (A + Bv) rem Modulus,
                "Add_Mod id t=" & T'Image);
         Check (Sub_Mod (A, A, Modulus) = 0,
                "Sub_Mod A-A=0 t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("24. Reset after many draws");
   -----------------------------------------------------------------
   G := Create (Lag_24_55, Add, V (10007), V (77));
   declare
      First : constant Value := Next_Val (G);
   begin
      for I in 1 .. 200 loop
         Discard := Next_Val (G);
      end loop;
      Reset (G, V (77));
      Check (Next_Val (G) = First, "reset after 200 draws");
   end;

   -----------------------------------------------------------------
   Section ("25. Uninitialised default and Is_Valid_Lags edges");
   -----------------------------------------------------------------
   declare
      U : Generator;
      Bad_Lags : constant Lag_Pair := (J => 5, K => 5);
   begin
      Check (not Is_Initialised (U), "default not initialised");
      Check (not Is_Valid_Lags (Bad_Lags), "j=k Lag_Pair invalid");
   end;

   -----------------------------------------------------------------
   Section ("26. Add_Mod at Default_Modulus edges");
   -----------------------------------------------------------------
   Check (Add_Mod (V (0), V (0), Default_Modulus) = 0,
          "0+0 mod 2^32");
   Check (Add_Mod (Default_Modulus - 1, Default_Modulus - 1,
                   Default_Modulus) = Default_Modulus - 2,
          "(M-1)+(M-1) mod M");
   Check (Xor_Mod (V (0), V (0), Default_Modulus) = 0, "0 xor 0");
   Check (Xor_Mod (V (1), V (2), Default_Modulus) = 3, "1 xor 2");

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
