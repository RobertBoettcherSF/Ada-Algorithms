--  Bounded Ada/SPARK fixed-point Cooley-Tukey FFT (educational SAR building block).
pragma Ada_2022;
package Cooley_Tukey_FFT
  with SPARK_Mode => On
is
   N     : constant := 8;
   Scale : constant := 1024;

   subtype Sample is Integer range -2048 .. 2048;
   type Complex is record
      Re : Sample := 0;
      Im : Sample := 0;
   end record;

   subtype Index is Natural range 0 .. N - 1;
   type Complex_Array is array (Index) of Complex;

   --  Input components are limited so that no stage can leave Sample: per component the
   --  magnitude at most doubles in stages 1 and 2 (twiddles 1 and -i are exact), and stage 3
   --  adds at most 724 * 2 * M / 1024 for the 45-degree twiddles, so 212 -> 424 -> 848 ->
   --  848 + 1199 = 2047. Larger inputs are rejected by the type instead of being clamped.
   Input_Bound : constant := 212;
   subtype Input_Sample is Sample range -Input_Bound .. Input_Bound;
   type Input_Complex is record
      Re : Input_Sample := 0;
      Im : Input_Sample := 0;
   end record;
   type Input_Array is array (Index) of Input_Complex;

   function Within (X : Complex_Array; M : Natural) return Boolean is
     (for all K in Index => abs X (K).Re <= M and then abs X (K).Im <= M)
   with Ghost;

   --  Radix-2 DIT FFT, N=8. Twiddles are Q10 fixed-point (no IEEE floats). Output is
   --  unnormalized (no 1/N scale).
   procedure FFT (Input : Input_Array; Output : out Complex_Array)
     with Global => null,
          Post   => Within (Output, 2047);

end Cooley_Tukey_FFT;
