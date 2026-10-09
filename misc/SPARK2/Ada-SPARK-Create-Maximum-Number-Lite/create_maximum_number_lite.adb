pragma Ada_2022;

package body Create_Maximum_Number_Lite with SPARK_Mode => On is
   function Maximum_Digit (A, B : Digit_Array; Length : Length_Type) return Digit is
      Best : Digit := 0;
   begin
      for I in 1 .. Length loop
         if A (I) > Best then
            Best := A (I);
         end if;
         if B (I) > Best then
            Best := B (I);
         end if;
      end loop;
      return Best;
   end Maximum_Digit;

   function Maximum_Prefix (A, B : Digit_Array; Length : Length_Type) return Digit_Array is
      Result : Digit_Array := [others => 0];
   begin
      for I in 1 .. Length loop
         if A (I) >= B (I) then
            Result (I) := A (I);
         else
            Result (I) := B (I);
         end if;
      end loop;
      return Result;
   end Maximum_Prefix;

   --  Largest L-digit subsequence of A (1 .. M) (monotonic stack).
   function Max_Sub (A : Digit_Array; M : Length_Type; L : Length_Type) return Digit_Array
     with Pre => L <= M
   is
      S   : Digit_Array := [others => 0];
      Top : Length_Type := 0;
   begin
      for I in 1 .. M loop
         pragma Loop_Invariant (Top <= L and then L - Top <= M - I + 1);
         while Top > 0 and then S (Top) < A (I) and then Top + (M - I + 1) > L loop
            pragma Loop_Invariant (Top <= L and then L - Top <= M - I + 1);
            pragma Loop_Variant (Decreases => Top);
            Top := Top - 1;
         end loop;
         if Top < L then
            Top := Top + 1;
            S (Top) := A (I);
         end if;
      end loop;
      return S;
   end Max_Sub;

   --  The rest X (I .. LX) is lexicographically larger than Y (J .. LY)
   --  (a longer sequence wins over its own prefix).
   function Greater (X : Digit_Array; I, LX : Natural; Y : Digit_Array; J, LY : Natural) return Boolean
     with Pre  => LX <= Index'Last and then LY <= Index'Last and then I in 1 .. LX + 1
                  and then J in 1 .. LY + 1 and then (I <= LX or else J <= LY),
          Post => (if Greater'Result then I <= LX else J <= LY)
   is
      P : Positive := I;
      Q : Positive := J;
   begin
      while P <= LX and then Q <= LY and then X (P) = Y (Q) loop
         pragma Loop_Invariant (P - I = Q - J and then P in I .. LX and then Q in J .. LY);
         pragma Loop_Variant (Increases => P);
         P := P + 1;
         Q := Q + 1;
      end loop;
      return Q > LY or else (P <= LX and then X (P) > Y (Q));
   end Greater;

   function Max_Number
     (A : Digit_Array; M : Length_Type; B : Digit_Array; N : Length_Type; K : Result_Length)
      return Result_Array
   is
      Best : Result_Array := [others => 0];
   begin
      for LA in Natural'Max (0, K - N) .. Natural'Min (K, M) loop
         declare
            LB  : constant Length_Type := K - LA;
            SA  : constant Digit_Array := Max_Sub (A, M, LA);
            SB  : constant Digit_Array := Max_Sub (B, N, LB);
            Cur : Result_Array := [others => 0];
            I   : Positive := 1;
            J   : Positive := 1;
            Better : Boolean := False;
         begin
            for P in 1 .. K loop
               pragma Loop_Invariant (I - 1 + (J - 1) = P - 1 and then I <= LA + 1 and then J <= LB + 1);
               if Greater (SA, I, LA, SB, J, LB) then
                  Cur (P) := SA (I);
                  I := I + 1;
               else
                  Cur (P) := SB (J);
                  J := J + 1;
               end if;
            end loop;
            for P in 1 .. K loop
               if Cur (P) /= Best (P) then
                  Better := Cur (P) > Best (P);
                  exit;
               end if;
            end loop;
            if Better then
               Best := Cur;
            end if;
         end;
      end loop;
      return Best;
   end Max_Number;
end Create_Maximum_Number_Lite;
