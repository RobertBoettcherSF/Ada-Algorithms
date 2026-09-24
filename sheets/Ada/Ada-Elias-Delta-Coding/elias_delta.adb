-- elias_delta.adb
package body Elias_Delta is

   function Integer_To_Binary (N : Positive) return String is
      Temp   : Natural := N; -- FIXED: Changed from Positive to Natural to allow 0 during division
      Result : String (1 .. 64);
      Index  : Integer := 64;
   begin
      if N = 1 then
         return "1";
      end if;
      while Temp > 0 loop
         if Temp mod 2 = 1 then
            Result(Index) := '1';
         else
            Result(Index) := '0';
         end if;
         Index := Index - 1;
         Temp := Temp / 2;
      end loop;
      return Result(Index + 1 .. 64);
   end Integer_To_Binary;

   function Binary_To_Integer (S : String) return Positive is
      Val : Natural := 0;
   begin
      if S = "" then
         raise Invalid_Code;
      end if;
      for I in S'Range loop
         Val := Val * 2;
         if S(I) = '1' then
            Val := Val + 1;
         elsif S(I) /= '0' then
            raise Invalid_Code;
         end if;
      end loop;
      if Val = 0 then
         raise Invalid_Code;
      end if;
      return Positive(Val);
   end Binary_To_Integer;

   function Gamma_Encode (N : Positive) return String is
      Bin    : constant String := Integer_To_Binary(N);
      Len    : constant Natural := Bin'Length;
      Prefix : String (1 .. Len - 1);
   begin
      for I in Prefix'Range loop
         Prefix(I) := '0';
      end loop;
      return Prefix & Bin;
   end Gamma_Encode;

   function Gamma_Decode (S : String; Last_Index : out Positive) return Positive is
      Zeros : Natural := 0;
      Idx   : Positive := S'First;
   begin
      while Idx <= S'Last and then S(Idx) = '0' loop
         Zeros := Zeros + 1;
         Idx := Idx + 1;
      end loop;

      if Idx > S'Last or else Idx + Zeros > S'Last then
         raise Invalid_Code;
      end if;

      declare
         Bin_Str : constant String := S(Idx .. Idx + Zeros);
      begin
         Last_Index := Idx + Zeros;
         return Binary_To_Integer(Bin_Str);
      end;
   end Gamma_Decode;

   function Encode (X : Positive) return String is
      Bin      : constant String := Integer_To_Binary(X);
      N        : constant Natural := Bin'Length - 1;
      N_Plus_1 : constant Positive := N + 1;
   begin
      declare
         Gamma_Part : constant String := Gamma_Encode(N_Plus_1);
         Rem_Part   : constant String := (if N > 0 then Bin(Bin'First + 1 .. Bin'Last) else "");
      begin
         return Gamma_Part & Rem_Part;
      end;
   end Encode;

   function Decode (S : String) return Positive is
      Last_Idx : Positive;
      N_Plus_1 : Positive;
      N        : Natural;
   begin
      N_Plus_1 := Gamma_Decode(S, Last_Idx);
      N := N_Plus_1 - 1;

      if Last_Idx + N > S'Last then
         raise Invalid_Code;
      end if;

      declare
         Rem_Str  : constant String := S(Last_Idx + 1 .. Last_Idx + N);
         Full_Bin : constant String := "1" & Rem_Str;
      begin
         return Binary_To_Integer(Full_Bin);
      end;
   end Decode;

   function Encode_Bits (X : Positive) return Bit_Vector is
      Enc_Str : constant String := Encode(X);
      Res     : Bit_Vector(1 .. Enc_Str'Length);
   begin
      for I in Enc_Str'Range loop
         Res(I - Enc_Str'First + 1) := (if Enc_Str(I) = '1' then One else Zero);
      end loop;
      return Res;
   end Encode_Bits;

   function Decode_Bits (Bits : Bit_Vector) return Positive is
      Enc_Str : String (1 .. Bits'Length);
   begin
      for I in Bits'Range loop
         Enc_Str(I - Bits'First + 1) := (if Bits(I) = One then '1' else '0');
      end loop;
      return Decode(Enc_Str);
   end Decode_Bits;

   function Encode_Non_Negative (X : Natural) return String is
   begin
      return Encode(X + 1);
   end Encode_Non_Negative;

   function Decode_Non_Negative (S : String) return Natural is
   begin
      return Decode(S) - 1;
   end Decode_Non_Negative;

   function ZigZag_Encode (X : Integer) return Positive is
   begin
      if X >= 0 then
         return Positive(X * 2 + 1);
      else
         return Positive((-X) * 2);
      end if;
   end ZigZag_Encode;

   function ZigZag_Decode (P : Positive) return Integer is
   begin
      if P mod 2 = 1 then
         return Integer(P - 1) / 2;
      else
         return -Integer(P / 2);
      end if;
   end ZigZag_Decode;

   function Encode_Integer (X : Integer) return String is
   begin
      return Encode(ZigZag_Encode(X));
   end Encode_Integer;

   function Decode_Integer (S : String) return Integer is
   begin
      return ZigZag_Decode(Decode(S));
   end Decode_Integer;

end Elias_Delta;
