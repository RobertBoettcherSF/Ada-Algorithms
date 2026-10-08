pragma Ada_2022;
with Interfaces;
package body Bitwise_Or_Of_Numbers_Range with SPARK_Mode => On is
   use type Word;
   function Or_0_To (Value : Word) return Word is
   begin
      if Value < 2 then
         return Value;
      elsif Value < 4 then
         return 3;
      elsif Value < 8 then
         return 7;
      elsif Value < 16 then
         return 15;
      elsif Value < 32 then
         return 31;
      elsif Value < 64 then
         return 63;
      elsif Value < 128 then
         return 127;
      elsif Value < 256 then
         return 255;
      elsif Value < 512 then
         return 511;
      elsif Value < 1024 then
         return 1023;
      elsif Value < 2048 then
         return 2047;
      elsif Value < 4096 then
         return 4095;
      elsif Value < 8192 then
         return 8191;
      elsif Value < 16384 then
         return 16383;
      elsif Value < 32768 then
         return 32767;
      elsif Value < 65536 then
         return 65535;
      elsif Value < 131072 then
         return 131071;
      elsif Value < 262144 then
         return 262143;
      elsif Value < 524288 then
         return 524287;
      elsif Value < 1048576 then
         return 1048575;
      elsif Value < 2097152 then
         return 2097151;
      elsif Value < 4194304 then
         return 4194303;
      elsif Value < 8388608 then
         return 8388607;
      elsif Value < 16777216 then
         return 16777215;
      elsif Value < 33554432 then
         return 33554431;
      elsif Value < 67108864 then
         return 67108863;
      elsif Value < 134217728 then
         return 134217727;
      elsif Value < 268435456 then
         return 268435455;
      elsif Value < 536870912 then
         return 536870911;
      elsif Value < 1073741824 then
         return 1073741823;
      elsif Value < 2147483648 then
         return 2147483647;
      else
         return 16#FFFF_FFFF#;
      end if;
   end Or_0_To;
end Bitwise_Or_Of_Numbers_Range;
