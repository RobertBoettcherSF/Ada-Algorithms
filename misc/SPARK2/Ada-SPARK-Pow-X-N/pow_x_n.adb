pragma Ada_2022;
package body Pow_X_N with SPARK_Mode => On is

   function Big (V : Integer) return Big_Integer renames To_Big_Integer;

   --  A * P keeps the sign of A and does not shrink, for P >= 1.
   procedure Lemma_Mul_Ge (A, P : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => P >= 1,
     Post   => (if A >= 0 then A * P >= A) and then (if A <= 0 then A * P <= A);
   procedure Lemma_Mul_Ge (A, P : Big_Integer) is null;

   --  For A /= 0 and P >= 0, A * P is at least P away from 0.
   procedure Lemma_Unit_Mul (A, P : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => A /= 0 and then P >= 0,
     Post   => (if A > 0 then A * P >= P) and then (if A < 0 then A * P <= -P);
   procedure Lemma_Unit_Mul (A, P : Big_Integer) is null;

   procedure Lemma_Sq_Mono (A, K : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => K >= 0 and then (A >= K or else A <= -K),
     Post   => A * A >= K * K;
   procedure Lemma_Sq_Mono (A, K : Big_Integer) is
   begin
      if A >= K then
         pragma Assert (A * A >= K * A);
         pragma Assert (K * A >= K * K);
      else
         pragma Assert ((-A) * (-A) >= K * (-A));
         pragma Assert (K * (-A) >= K * K);
      end if;
   end Lemma_Sq_Mono;

   --  Powers of Y >= 1 are >= 1, and >= Y once N >= 1.
   procedure Lemma_Pos (Y : Big_Integer; N : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => Y >= 1,
     Post               => Pow (Y, N) >= 1 and then (if N >= 1 then Pow (Y, N) >= Y),
     Subprogram_Variant => (Decreases => N);
   procedure Lemma_Pos (Y : Big_Integer; N : Natural) is
   begin
      if N > 0 then
         Lemma_Pos (Y, N / 2);
         declare
            H : constant Big_Integer := Pow (Y, N / 2);
         begin
            Lemma_Mul_Ge (H, H);
            pragma Assert (H * H >= H);
            if N mod 2 = 1 then
               Lemma_Mul_Ge (Y, H * H);
               pragma Assert (Pow (Y, N) = Y * Sq (H));
               pragma Assert (Sq (H) = H * H);
               pragma Assert (Pow (Y, N) = Y * (H * H));
            else
               pragma Assert (N / 2 >= 1);
               pragma Assert (Pow (Y, N) = H * H);
            end if;
         end;
      end if;
   end Lemma_Pos;

   --  Squaring the base doubles the exponent: Pow (B, K) ** 2 = Pow (B * B, K).
   procedure Lemma_Square (B : Big_Integer; K : Natural)
   with
     Ghost,
     Global             => null,
     Post               => Pow (B, K) * Pow (B, K) = Pow (B * B, K),
     Subprogram_Variant => (Decreases => K);
   procedure Lemma_Square (B : Big_Integer; K : Natural) is
   begin
      if K > 0 then
         Lemma_Square (B, K / 2);
         declare
            H : constant Big_Integer := Pow (B, K / 2);
            G : constant Big_Integer := Pow (B * B, K / 2);
         begin
            pragma Assert (G = H * H);
            if K mod 2 = 0 then
               pragma Assert (Pow (B, K) = H * H);
               pragma Assert (Pow (B * B, K) = G * G);
            else
               pragma Assert (Pow (B, K) = B * Sq (H));
               pragma Assert (Pow (B, K) = B * (H * H));
               pragma Assert (Pow (B * B, K) = (B * B) * Sq (G));
               pragma Assert (Pow (B * B, K) = (B * B) * (G * G));
               pragma Assert ((B * (H * H)) * (B * (H * H)) = (B * B) * ((H * H) * (H * H)));
            end if;
         end;
      end if;
   end Lemma_Square;

   --  One more factor: Pow (Y, N + 1) = Y * Pow (Y, N).
   procedure Lemma_Succ (Y : Big_Integer; N : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => N < Natural'Last,
     Post               => Pow (Y, N + 1) = Y * Pow (Y, N),
     Subprogram_Variant => (Decreases => N);
   procedure Lemma_Succ (Y : Big_Integer; N : Natural) is
   begin
      if N mod 2 = 1 then
         Lemma_Succ (Y, N / 2);
         declare
            H : constant Big_Integer := Pow (Y, N / 2);
         begin
            pragma Assert ((N + 1) / 2 = N / 2 + 1);
            pragma Assert (Pow (Y, (N + 1) / 2) = Y * H);
            pragma Assert (Pow (Y, N + 1) = Sq (Pow (Y, (N + 1) / 2)));
            pragma Assert (Pow (Y, N + 1) = (Y * H) * (Y * H));
            pragma Assert (Pow (Y, N) = Y * Sq (H));
            pragma Assert (Pow (Y, N) = Y * (H * H));
         end;
      else
         pragma Assert ((N + 1) / 2 = N / 2);
         pragma Assert (Pow (Y, N + 1) = Y * Sq (Pow (Y, N / 2)));
         if N > 0 then
            pragma Assert (Pow (Y, N) = Sq (Pow (Y, N / 2)));
         else
            pragma Assert (Pow (Y, N) = 1);
         end if;
      end if;
   end Lemma_Succ;

   --  The bases -1, 0 and 1.
   procedure Lemma_Unit (X : Integer; N : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => X in -1 .. 1,
     Post               => Pow (Big (X), N)
                           = Big (if X = 0 then (if N = 0 then 1 else 0)
                                  elsif X = 1 or else N mod 2 = 0 then 1
                                  else -1),
     Subprogram_Variant => (Decreases => N);
   procedure Lemma_Unit (X : Integer; N : Natural) is
   begin
      if N > 0 then
         Lemma_Unit (X, N / 2);
      end if;
   end Lemma_Unit;

   --  abs X ** N >= 2 ** 32 for abs X >= 2 and N >= 32.
   procedure Lemma_Huge (X : Integer; N : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => X not in -1 .. 1 and then N >= 32,
     Post               => Pow (Big (X), N) >= 4_294_967_296
                           or else Pow (Big (X), N) <= -4_294_967_296,
     Subprogram_Variant => (Decreases => N);
   procedure Lemma_Huge (X : Integer; N : Natural) is
      Y : constant Big_Integer := Big (X);
   begin
      if N = 32 then
         pragma Assert (Pow (Y, 1) = Y);
         Lemma_Sq_Mono (Pow (Y, 1), 2);
         pragma Assert (Pow (Y, 2) >= 4);
         Lemma_Sq_Mono (Pow (Y, 2), 4);
         pragma Assert (Pow (Y, 4) >= 16);
         Lemma_Sq_Mono (Pow (Y, 4), 16);
         pragma Assert (Pow (Y, 8) >= 256);
         Lemma_Sq_Mono (Pow (Y, 8), 256);
         pragma Assert (Pow (Y, 16) >= 65_536);
         Lemma_Sq_Mono (Pow (Y, 16), 65_536);
         pragma Assert (Pow (Y, 32) >= 4_294_967_296);
      else
         Lemma_Huge (X, N - 1);
         Lemma_Succ (Y, N - 1);
         declare
            P : constant Big_Integer := Pow (Y, N - 1);
         begin
            pragma Assert (Pow (Y, N) = Y * P);
            if P >= 0 then
               Lemma_Unit_Mul (Y, P);
            else
               Lemma_Unit_Mul (Y, -P);
               pragma Assert (Y * P = -(Y * (-P)));
            end if;
         end;
      end if;
   end Lemma_Huge;

   procedure Lemma_Big (X : Integer; N : Natural) is
   begin
      Lemma_Huge (X, N);
   end Lemma_Big;

   procedure Power (X : Integer; N : Natural; Result : out Integer; Ok : out Boolean) is
      Lo  : constant Long_Long_Integer := Long_Long_Integer (Integer'First);
      Hi  : constant Long_Long_Integer := Long_Long_Integer (Integer'Last);
      Acc : Integer := 1;
      B   : Integer := X;
      E   : Natural := N;
      P   : Long_Long_Integer;
      --  X ** N, needed by the proof only; 0 where the loop does not run.
      Target : constant Big_Integer :=
        (if X in -1 .. 1 or else N >= 32 then To_Big_Integer (0) else Pow (Big (X), N))
      with Ghost;
   begin
      Result := 0;
      Ok := False;
      if X in -1 .. 1 then
         Lemma_Unit (X, N);
         Result := (if X = 0 then (if N = 0 then 1 else 0)
                    elsif X = 1 or else N mod 2 = 0 then 1
                    else -1);
         Ok := True;
         return;
      end if;
      if N >= 32 then
         --  abs X ** N >= 2 ** 32 (Lemma_Big).
         return;
      end if;

      while E > 0 loop
         pragma Loop_Invariant (E <= N);
         pragma Loop_Invariant (Acc /= 0 and then B not in -1 .. 1);
         pragma Loop_Invariant (Big (Acc) * Pow (Big (B), E) = Target);
         pragma Loop_Variant (Decreases => E);
         Lemma_Square (Big (B), E / 2);
         pragma Assert
           (Pow (Big (B), E)
            = (if E mod 2 = 1 then Big (B) else 1) * Pow (Big (B) * Big (B), E / 2));
         if E mod 2 = 1 then
            P := Long_Long_Integer (Acc) * Long_Long_Integer (B);
            if P not in Lo .. Hi then
               --  X ** N = (Acc * B) * (B * B) ** (E / 2), and the last
               --  factor is >= 1: X ** N is out of range on the same side.
               Lemma_Pos (Big (B) * Big (B), E / 2);
               Lemma_Mul_Ge (Big (Acc) * Big (B), Pow (Big (B) * Big (B), E / 2));
               pragma Assert (Target = (Big (Acc) * Big (B)) * Pow (Big (B) * Big (B), E / 2));
               pragma Assert (not Fits (Target));
               pragma Assert (not Fits_Power (X, N));
               return;
            end if;
            Acc := Integer (P);
         end if;
         E := E / 2;
         if E > 0 then
            if B not in -46_340 .. 46_340 then
               --  B * B >= 46_341 ** 2 > 2 ** 31, and X ** N =
               --  Acc * (B * B) ** E with Acc /= 0 and E >= 1.
               Lemma_Pos (Big (B) * Big (B), E);
               Lemma_Unit_Mul (Big (Acc), Pow (Big (B) * Big (B), E));
               Lemma_Sq_Mono (Big (B), 46_341);
               pragma Assert (Big (B) * Big (B) >= 2_147_488_281);
               pragma Assert (Target = Big (Acc) * Pow (Big (B) * Big (B), E));
               pragma Assert (not Fits (Target));
               pragma Assert (not Fits_Power (X, N));
               return;
            end if;
            B := B * B;
         end if;
      end loop;
      pragma Assert (Big (Acc) = Target);
      pragma Assert (Fits_Power (X, N));
      Result := Acc;
      Ok := True;
   end Power;
end Pow_X_N;
