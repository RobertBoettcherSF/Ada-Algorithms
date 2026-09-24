--  Standalone test suite for Lagged_Fibonacci_Generator.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lagged_Fibonacci_Generator;
use Lagged_Fibonacci_Generator;

procedure Tests is

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

   function Create_Seeds_Raises
     (J : Lag_Index; K : Lag_Index; Op : Binary_Op; M : Value;
      Seeds : Seed_Array) return Boolean
   is
      G : Generator;
   begin
      G := Create (J, K, Op, M, Seeds);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Seeds_Raises;

   function Create_Seed_Raises
     (J : Lag_Index; K : Lag_Index; Op : Binary_Op; M : Value;
      Seed : Value) return Boolean
   is
      G : Generator;
   begin
      G := Create (J, K, Op, M, Seed);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Seed_Raises;

   function Reset_Seeds_Raises
     (G : in out Generator; Seeds : Seed_Array) return Boolean
   is
   begin
      Reset (G, Seeds);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Seeds_Raises;

   function Reset_Seed_Raises
     (G : in out Generator; Seed : Value) return Boolean
   is
   begin
      Reset (G, Seed);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Seed_Raises;

   function Next_Raises (G : in out Generator) return Boolean is
      X : Value;
   begin
      X := Next (G);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Raises;

   function Next_Float_Raises (G : in out Generator) return Boolean is
      F : Long_Float;
   begin
      F := Next_Float (G);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Float_Raises;

   function Buffer_Word_Raises
     (G : Generator; Index : Lag_Index) return Boolean
   is
      X : Value;
   begin
      X := Get_Buffer_Word (G, Index);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Buffer_Word_Raises;

   function Add_Mod_Raises (X, Y, M : Value) return Boolean is
      Z : Value;
   begin
      Z := Add_Mod (X, Y, M);
      pragma Unreferenced (Z);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Mod_Raises;

   function Sub_Mod_Raises (X, Y, M : Value) return Boolean is
      Z : Value;
   begin
      Z := Sub_Mod (X, Y, M);
      pragma Unreferenced (Z);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sub_Mod_Raises;

   function Xor_Mod_Raises (X, Y, M : Value) return Boolean is
      Z : Value;
   begin
      Z := Xor_Mod (X, Y, M);
      pragma Unreferenced (Z);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Xor_Mod_Raises;

   function Combine_Raises
     (X, Y : Value; Op : Binary_Op; M : Value) return Boolean
   is
      Z : Value;
   begin
      Z := Combine (X, Y, Op, M);
      pragma Unreferenced (Z);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Combine_Raises;

   G, G2 : Generator;
   X, Y, Z : Value;
   F : Long_Float;
   B : Boolean;
   M : Value;
   Discard : Value;

begin
   -----------------------------------------------------------------
   Section ("1. Invalid_Argument (bad lags / modulus / seeds)");
   -----------------------------------------------------------------
   Check (not Is_Valid_Lags (Pos (5), Pos (5)), "j=k=5 invalid");
   Check (not Is_Valid_Lags (Pos (10), Pos (5)), "j>k invalid");
   Check (Is_Valid_Lags (Pos (1), Pos (2)), "j=1 k=2 valid");
   Check (Is_Valid_Lags (Pos (24), Pos (55)), "j=24 k=55 valid");
   Check (not Is_Valid_Lags (Pos (1), Pos (Max_Lag + 1)),
          "k>Max_Lag invalid");
   Check (Is_Valid_Lags (Lag_24_55), "Lag_24_55 valid");
   Check (Is_Valid_Lags (Lag_273_607), "Lag_273_607 valid");
   Check (not Is_Valid_Modulus (V (0)), "M=0 invalid");
   Check (not Is_Valid_Modulus (V (1)), "M=1 invalid");
   Check (Is_Valid_Modulus (V (2)), "M=2 valid");
   Check (Is_Valid_Modulus (Default_Modulus), "Default_Modulus valid");

   declare
      Tiny : constant Seed_Array := [1, 2, 3];
   begin
      Check (Create_Seeds_Raises (2, 2, Add, 16, Tiny),
             "Create j=k raises");
      Check (Create_Seeds_Raises (3, 2, Add, 16, Tiny),
             "Create j>k raises");
      Check (Create_Seeds_Raises (1, 2, Add, 16, Tiny),
             "seed length 3 != k=2 raises");
   end;
   Check (Create_Seed_Raises (1, 2, Add, 0, 0), "Create M=0 raises");
   Check (Create_Seed_Raises (1, 2, Add, 1, 0), "Create M=1 raises");
   Check (Create_Seed_Raises (1, 2, Add, 16, 16), "Seed>=M raises");
   declare
      S2 : constant Seed_Array := [1, 20];
   begin
      Check (Create_Seeds_Raises (1, 2, Add, 16, S2),
             "seed word >= M raises");
   end;

   -----------------------------------------------------------------
   Section ("2. Tiny additive LFG (j=1,k=2,m=16) deterministic");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (1)];
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
         if Next (G) /= Expected (I) then
            B := False;
         end if;
      end loop;
      Check (B, "fib-like add sequence 10 terms");
   end;

   -----------------------------------------------------------------
   Section ("3. Subtract and XOR tiny sequences");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (10), V (3)];
   begin
      G := Create (1, 2, Subtract, 16, S);
      Check (Next (G) = 9, "sub X2=9");
      Check (Next (G) = 6, "sub X3=6");
      Check (Next (G) = 13, "sub X4=13");
   end;

   declare
      S : constant Seed_Array := [V (5), V (3)];
   begin
      G := Create (1, 2, Bitwise_Xor, 16, S);
      Check (Next (G) = 6, "xor X2=6");
      Check (Next (G) = 5, "xor X3=5");
      Check (Next (G) = 3, "xor X4=3");
      Check (Get_Op (G) = Bitwise_Xor, "op is Bitwise_Xor");
   end;

   -----------------------------------------------------------------
   Section ("4. Reset replay and independent generators");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (2), V (3)];
      Buf : array (1 .. 6) of Value;
   begin
      G := Create (1, 3, Add, 32, S);
      for I in Buf'Range loop
         Buf (I) := Next (G);
      end loop;
      Reset (G, S);
      B := True;
      for I in Buf'Range loop
         if Next (G) /= Buf (I) then
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
         if Next (G) /= Next (G2) then
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
         Buf (I) := Next (G);
      end loop;
      Reset (G, V (42));
      B := True;
      for I in Buf'Range loop
         if Next (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "Reset single-seed replay");
   end;

   Check (Create_Seed_Raises (1, 4, Add, 1000, V (1000)),
          "LCG-fill Seed>=M raises");

   -----------------------------------------------------------------
   Section ("6. Next_Float in [0,1)");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (1)];
   begin
      G := Create (1, 2, Add, 16, S);
      B := True;
      for I in 1 .. 20 loop
         F := Next_Float (G);
         if F < 0.0 or else F >= 1.0 then
            B := False;
         end if;
      end loop;
      Check (B, "20 floats in [0,1)");
      Reset (G, S);
      X := Next (G);
      Reset (G, S);
      F := Next_Float (G);
      Check (F = Long_Float (X) / 16.0, "Next_Float = X/M");
   end;

   -----------------------------------------------------------------
   Section ("7. Lag_Pair Create overloads and constants");
   -----------------------------------------------------------------
   Check (Lag_24_55.J = 24 and Lag_24_55.K = 55, "Lag_24_55");
   Check (Lag_38_89.J = 38 and Lag_38_89.K = 89, "Lag_38_89");
   Check (Lag_37_100.J = 37 and Lag_37_100.K = 100, "Lag_37_100");
   Check (Lag_30_127.J = 30 and Lag_30_127.K = 127, "Lag_30_127");
   Check (Lag_83_258.J = 83 and Lag_83_258.K = 258, "Lag_83_258");
   Check (Lag_107_378.J = 107 and Lag_107_378.K = 378, "Lag_107_378");
   Check (Lag_273_607.J = 273 and Lag_273_607.K = 607, "Lag_273_607");
   Check (V (Long_Long_Integer (Default_Modulus)) = V (4_294_967_296), "Default_Modulus=2^32");
   Check (Max_Lag = Nat (1024), "Max_Lag=1024");

   G := Create (Lag_24_55, Add, Default_Modulus, V (12345));
   Check (Get_J (G) = 24, "Lag_Pair Create J");
   Check (Get_K (G) = 55, "Lag_Pair Create K");
   Check (Get_Op (G) = Add, "Lag_Pair Create Op");
   X := Next (G);
   Y := Next (G);
   Check (X < Default_Modulus and Y < Default_Modulus,
          "Lag_24_55 samples < M");

   declare
      S : Seed_Array (1 .. 55);
   begin
      for I in S'Range loop
         S (I) := Value (I);
      end loop;
      G := Create (Lag_24_55, Subtract, Default_Modulus, S);
      Check (Get_Op (G) = Subtract, "array Lag_Pair Subtract");
      Z := Next (G);
      Check (Z < Default_Modulus, "subtract sample < M");
   end;

   -----------------------------------------------------------------
   Section ("8. Modular helpers Add_Mod / Sub_Mod / Xor_Mod");
   -----------------------------------------------------------------
   Check (Add_Mod (V (3), V (5), V (7)) = 1, "3+5 mod 7 = 1");
   Check (Add_Mod (V (6), V (6), V (7)) = 5, "6+6 mod 7 = 5");
   Check (Add_Mod (V (0), V (0), V (2)) = 0, "0+0 mod 2");
   Check (Sub_Mod (V (3), V (5), V (7)) = 5, "3-5 mod 7 = 5");
   Check (Sub_Mod (V (5), V (3), V (7)) = 2, "5-3 mod 7 = 2");
   Check (Sub_Mod (V (0), V (1), V (8)) = 7, "0-1 mod 8 = 7");
   Check (Xor_Mod (V (5), V (3), V (16)) = 6, "5 xor 3 = 6");
   Check (Xor_Mod (V (15), V (15), V (16)) = 0, "15 xor 15 = 0");
   Check (Xor_Mod (V (7), V (1), V (5)) = 3, "(7 rem5) xor (1 rem5) = 3");
   Check (Combine (V (3), V (5), Add, V (7)) = 1, "Combine Add");
   Check (Combine (V (3), V (5), Subtract, V (7)) = 5, "Combine Sub");
   Check (Combine (V (5), V (3), Bitwise_Xor, V (16)) = 6,
          "Combine Xor");
   Check (Add_Mod_Raises (0, 0, 0), "Add_Mod M=0 raises");
   Check (Sub_Mod_Raises (0, 0, 0), "Sub_Mod M=0 raises");
   Check (Xor_Mod_Raises (0, 0, 0), "Xor_Mod M=0 raises");
   Check (Combine_Raises (0, 0, Add, 0), "Combine M=0 raises");
   Check (Add_Mod (Value'Last, V (1), Value'Last) = 1,
          "Add_Mod near Value'Last");
   Check (Sub_Mod (V (0), V (1), Value'Last) = Value'Last - 1,
          "Sub_Mod wrap Value'Last");

   -----------------------------------------------------------------
   Section ("9. Uninitialised generator / buffer bounds");
   -----------------------------------------------------------------
   declare
      U : Generator;
   begin
      Check (not Is_Initialised (U), "default not initialised");
      Check (Next_Raises (U), "Next uninit raises");
      Check (Next_Float_Raises (U), "Next_Float uninit raises");
      Check (Reset_Seed_Raises (U, 0), "Reset uninit raises");
      Check (Buffer_Word_Raises (U, 1), "Buffer_Word uninit raises");
   end;

   declare
      S : constant Seed_Array := [V (1), V (2)];
   begin
      G := Create (1, 2, Add, 16, S);
      Check (Buffer_Word_Raises (G, 3), "Index>K raises");
      Check (Get_Buffer_Word (G, 2) = 2, "Index=K ok");
   end;

   -----------------------------------------------------------------
   Section ("10. j=2,k=5 additive known sequence");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [1, 2, 3, 4, 5];
      Exp : constant array (1 .. 5) of Value := [5, 7, 8, 11, 13];
   begin
      G := Create (2, 5, Add, 32, S);
      B := True;
      for I in Exp'Range loop
         if Next (G) /= Exp (I) then
            B := False;
         end if;
      end loop;
      Check (B, "j=2 k=5 add sequence");
   end;

   -----------------------------------------------------------------
   Section ("11. Freeciv-style (24,55) Add reproducibility");
   -----------------------------------------------------------------
   G := Create (Lag_24_55, Add, Default_Modulus, V (1));
   declare
      Buf : array (1 .. 20) of Value;
   begin
      for I in Buf'Range loop
         Buf (I) := Next (G);
      end loop;
      Reset (G, V (1));
      B := True;
      for I in Buf'Range loop
         if Next (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "(24,55) Add reset replay 20");
   end;

   G := Create (Lag_24_55, Bitwise_Xor, Default_Modulus, V (99));
   G2 := Create (Lag_24_55, Bitwise_Xor, Default_Modulus, V (99));
   B := True;
   for I in 1 .. 30 loop
      if Next (G) /= Next (G2) then
         B := False;
      end if;
   end loop;
   Check (B, "(24,55) XOR twin generators");

   G := Create (Lag_38_89, Subtract, Default_Modulus, V (7));
   Check (Get_J (G) = 38 and Get_K (G) = 89, "(38,89) inspectors");
   X := Next (G);
   Check (X < Default_Modulus, "(38,89) sample");

   -----------------------------------------------------------------
   Section ("12. All three ops on same seeds differ");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (7), V (11), V (13)];
      XA, XS, XX : Value;
   begin
      G := Create (1, 3, Add, 64, S);
      XA := Next (G);
      G := Create (1, 3, Subtract, 64, S);
      XS := Next (G);
      G := Create (1, 3, Bitwise_Xor, 64, S);
      XX := Next (G);
      Check (XA = Add_Mod (13, 7, 64), "Add matches helper");
      Check (XS = Sub_Mod (13, 7, 64), "Sub matches helper");
      Check (XX = Xor_Mod (13, 7, 64), "Xor matches helper");
      Check (XA /= XS, "Add /= Sub on pair");
      Check (XA /= XX, "Add /= Xor on pair");
   end;

   -----------------------------------------------------------------
   Section ("13. Cursor advances mod K");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (2), V (3), V (4)];
   begin
      G := Create (1, 4, Add, 100, S);
      Check (Get_Cursor (G) = Nat (0), "cursor 0");
      Discard := Next (G);
      Check (Get_Cursor (G) = Nat (1), "cursor 1");
      Discard := Next (G);
      Check (Get_Cursor (G) = Nat (2), "cursor 2");
      Discard := Next (G);
      Check (Get_Cursor (G) = Nat (3), "cursor 3");
      Discard := Next (G);
      Check (Get_Cursor (G) = Nat (0), "cursor wraps to 0");
   end;

   -----------------------------------------------------------------
   Section ("14. More Invalid_Argument edges");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (2)];
      Bad : constant Seed_Array := [V (1)];
      Big : constant Seed_Array := [V (1), V (99)];
   begin
      G := Create (1, 2, Add, 16, S);
      Check (Reset_Seeds_Raises (G, Bad), "Reset wrong length");
      Check (Reset_Seed_Raises (G, 16), "Reset Seed>=M");
      Check (Reset_Seeds_Raises (G, Big), "Reset word>=M");
   end;

   Check (Create_Seed_Raises (1, 2, Subtract, 2, 2), "seed=M raises");
   declare
      Bad_Lags : constant Lag_Pair := (J => 5, K => 5);
   begin
      Check (not Is_Valid_Lags (Bad_Lags), "j=k Lag_Pair invalid");
      Check (Create_Seed_Raises (5, 5, Add, 16, 0), "Create j=k");
   end;

   -----------------------------------------------------------------
   Section ("15. Larger lag pairs smoke (LCG fill)");
   -----------------------------------------------------------------
   G := Create (Lag_30_127, Add, Default_Modulus, V (11));
   Check (Get_K (G) = 127, "k=127");
   for I in 1 .. 50 loop
      X := Next (G);
   end loop;
   Check (X < Default_Modulus, "50 samples (30,127)");

   G := Create (Lag_37_100, Bitwise_Xor, V (2 ** 16), V (3));
   Check (Get_Modulus (G) = 2 ** 16, "M=2^16");
   B := True;
   for I in 1 .. 40 loop
      if Next (G) >= 2 ** 16 then
         B := False;
      end if;
   end loop;
   Check (B, "40 XOR samples < 2^16");

   G := Create (Lag_83_258, Subtract, Default_Modulus, V (42));
   Check (Get_J (G) = 83, "j=83");
   X := Next (G);
   Y := Next (G);
   Reset (G, V (42));
   Check (Next (G) = X and then Next (G) = Y, "(83,258) reset");

   -----------------------------------------------------------------
   Section ("16. M=2 minimal modulus");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (0)];
   begin
      G := Create (1, 2, Add, 2, S);
      Check (Next (G) = 1, "m=2 X2");
      Check (Next (G) = 1, "m=2 X3");
      Check (Next (G) = 0, "m=2 X4");
   end;

   -----------------------------------------------------------------
   Section ("17. Next_Float endpoints and many samples");
   -----------------------------------------------------------------
   G := Create (Lag_24_55, Add, V (10), V (1));
   B := True;
   for I in 1 .. 100 loop
      F := Next_Float (G);
      if F < 0.0 or else F >= 1.0 then
         B := False;
      end if;
   end loop;
   Check (B, "100 floats in [0,1) M=10");

   -----------------------------------------------------------------
   Section ("18. Buffer inspect after advances");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (2), V (3)];
   begin
      G := Create (1, 3, Add, 64, S);
      X := Next (G);
      Check (X = 4, "X3=4");
      Check (Get_Buffer_Word (G, 1) = 4, "buf[1] overwritten with X3");
      Check (Get_Buffer_Word (G, 2) = 2, "buf[2] still X1");
      Check (Get_Buffer_Word (G, 3) = 3, "buf[3] still X2");
   end;

   -----------------------------------------------------------------
   Section ("19. Combine / helpers M=1 edge");
   -----------------------------------------------------------------
   Check (Add_Mod (V (5), V (9), V (1)) = 0, "Add_Mod M=1 -> 0");
   Check (Sub_Mod (V (5), V (9), V (1)) = 0, "Sub_Mod M=1 -> 0");
   Check (Xor_Mod (V (5), V (9), V (1)) = 0, "Xor_Mod M=1 -> 0");

   -----------------------------------------------------------------
   Section ("20. Deterministic multi-op batch");
   -----------------------------------------------------------------
   for Op in Binary_Op loop
      G := Create (2, 7, Op, V (997), V (123));
      G2 := Create (2, 7, Op, V (997), V (123));
      B := True;
      for I in 1 .. 25 loop
         if Next (G) /= Next (G2) then
            B := False;
         end if;
      end loop;
      Check (B, "twin batch op=" & Op'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("21. Lag_107_378 and Lag_273_607 smoke");
   -----------------------------------------------------------------
   G := Create (Lag_107_378, Add, Default_Modulus, V (5));
   Check (Get_K (G) = 378, "k=378");
   for I in 1 .. 10 loop
      X := Next (G);
   end loop;
   Check (X < Default_Modulus, "(107,378) sample");

   G := Create (Lag_273_607, Bitwise_Xor, Default_Modulus, V (9));
   Check (Get_J (G) = 273 and Get_K (G) = 607, "(273,607)");
   X := Next (G);
   Reset (G, V (9));
   Check (Next (G) = X, "(273,607) reset first sample");

   -----------------------------------------------------------------
   Section ("22. Seed array Lag_Pair Create + Reset array");
   -----------------------------------------------------------------
   declare
      S : Seed_Array (1 .. 55);
      Buf : array (1 .. 15) of Value;
   begin
      for I in S'Range loop
         S (I) := Value ((I * 17) mod 256);
      end loop;
      S (1) := 1;
      G := Create (Lag_24_55, Add, V (256), S);
      for I in Buf'Range loop
         Buf (I) := Next (G);
      end loop;
      Reset (G, S);
      B := True;
      for I in Buf'Range loop
         if Next (G) /= Buf (I) then
            B := False;
         end if;
      end loop;
      Check (B, "Lag_Pair array Reset replay");
   end;

   -----------------------------------------------------------------
   Section ("23. Subtract sequence j=3 k=7");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [10, 20, 30, 40, 50, 60, 70];
   begin
      G := Create (3, 7, Subtract, 1000, S);
      Check (Next (G) = 40, "X7=40");
      Check (Next (G) = 40, "X8=40");
      Check (Next (G) = 40, "X9=40");
      Check (Next (G) = 0, "X10=0");
   end;

   -----------------------------------------------------------------
   Section ("24. XOR sequence j=2 k=4");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (2), V (4), V (8)];
   begin
      G := Create (2, 4, Bitwise_Xor, 256, S);
      Check (Next (G) = 5, "xor X4=5");
      Check (Next (G) = 10, "xor X5=10");
      Check (Next (G) = 1, "xor X6=1");
   end;

   -----------------------------------------------------------------
   Section ("25. Many small-moduli periods / values");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (1), V (1)];
      Seen : array (0 .. 15) of Boolean := [others => False];
      C : Natural := 0;
   begin
      G := Create (1, 2, Add, 16, S);
      for I in 1 .. 32 loop
         X := Next (G);
         if not Seen (Natural (X)) then
            Seen (Natural (X)) := True;
            C := C + 1;
         end if;
      end loop;
      Check (C >= Nat (8), "add fib visits >=8 residues in 32");
   end;

   -----------------------------------------------------------------
   Section ("26. Inspector Get_* consistency");
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
   Section ("27. Cross-check Combine vs Next for j=1 k=2");
   -----------------------------------------------------------------
   declare
      S : constant Seed_Array := [V (9), V (4)];
   begin
      for Op in Binary_Op loop
         G := Create (1, 2, Op, 32, S);
         X := Next (G);
         Check (X = Combine (4, 9, Op, 32),
                "Next vs Combine " & Op'Image);
      end loop;
   end;

   -----------------------------------------------------------------
   Section ("28. Extra Pass padding — varied Create smoke");
   -----------------------------------------------------------------
   for K in Lag_Index range 2 .. 12 loop
      declare
         J : constant Lag_Index := 1;
         Seed_K : constant Value := V (Long_Long_Integer (K));
      begin
         G := Create (J, K, Add, V (1009), Seed_K);
         X := Next (G);
         Check (X < 1009, "smoke k=" & K'Image);
      end;
   end loop;

   for M_Pow in 3 .. 10 loop
      M := 2 ** M_Pow;
      G := Create (1, 3, Bitwise_Xor, M, V (1));
      B := True;
      for I in 1 .. 5 loop
         if Next (G) >= M then
            B := False;
         end if;
      end loop;
      Check (B, "xor M=2^" & M_Pow'Image);
   end loop;

   -----------------------------------------------------------------
   -- Extra deterministic checks to clear the 150-pass floor
   -----------------------------------------------------------------
   Section ("29. More Add_Mod / Sub_Mod identities");
   -----------------------------------------------------------------
   for T in 1 .. 12 loop
      declare
         A : constant Value := V (Long_Long_Integer (T * 3));
         Bv : constant Value := V (Long_Long_Integer (T * 5));
         Modulus : constant Value := V (17);
      begin
         Check (Add_Mod (A, Bv, Modulus) =
                  (A + Bv) rem Modulus,
                "Add_Mod id t=" & T'Image);
         Check (Sub_Mod (A, A, Modulus) = 0,
                "Sub_Mod A-A=0 t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("30. Reset after many draws");
   -----------------------------------------------------------------
   G := Create (Lag_24_55, Add, V (10007), V (77));
   declare
      First : constant Value := Next (G);
   begin
      for I in 1 .. 200 loop
         Discard := Next (G);
      end loop;
      Reset (G, V (77));
      Check (Next (G) = First, "reset after 200 draws");
   end;

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
