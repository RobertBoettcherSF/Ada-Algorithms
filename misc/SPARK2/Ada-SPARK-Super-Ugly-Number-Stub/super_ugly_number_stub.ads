pragma Ada_2022;

package Super_Ugly_Number_Stub with SPARK_Mode => On is
   --  Original fixed exercise: factors (2, 7, 13, 19), N in 1 .. 12.
   subtype N_Index is Positive range 1 .. 12;
   subtype Small_Ugly is Positive range 1 .. 1_000_000;
   function Nth_Super_Ugly (N : N_Index) return Small_Ugly with Global => null;

   --  General version: the N-th smallest positive integer that is a product
   --  of the given factors (1 is the empty product); factors need not be
   --  prime or distinct. Up to 100 factors in 2 .. 1000 and N up to 10**5
   --  (the work table is 10**5 Integers, 400 KB). Values are reported up to
   --  Integer'Last: Fits is False exactly when the N-th value is larger (then
   --  Value is 1 and means nothing).
   Max_N       : constant := 100_000;
   Max_Factors : constant := 100;
   subtype N_Range is Positive range 1 .. Max_N;
   subtype Factor_Value is Positive range 2 .. 1_000;
   subtype Factor_Index is Positive range 1 .. Max_Factors;
   type Factor_List is array (Factor_Index range <>) of Factor_Value;
   subtype Ugly_Value is Positive;

   --  2 ** I for I in 0 .. 31 (proof only): with factor 2 the K-th value is
   --  at most 2 ** (K - 1).
   type Pow_Table is array (0 .. 31) of Long_Long_Integer;
   Pow2 : constant Pow_Table :=
     [1, 2, 4, 8, 16, 32, 64, 128,
      256, 512, 1024, 2048, 4096, 8192, 16384, 32768,
      65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608,
      16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648]
     with Ghost;

   function Has_Two (F : Factor_List) return Boolean is
     (for some J in F'Range => F (J) = 2);

   procedure Nth_Super_Ugly_General
     (Factors : Factor_List; N : N_Range; Value : out Ugly_Value; Fits : out Boolean)
     with Global => null,
          Pre    => Factors'Length >= 1,
          Post   => (if not Fits then Value = 1)
                    and then (if Has_Two (Factors) and then N <= 31
                              then Fits and then Long_Long_Integer (Value) <= Pow2 (N - 1));
end Super_Ugly_Number_Stub;
